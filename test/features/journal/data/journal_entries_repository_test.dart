import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/features/journal/data/journal_entries_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppDatabase database;
  late SupabaseClient client;
  late _FakeJournalRemoteDataSource remote;
  late JournalEntriesRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('http://localhost:54321', 'test-anon-key');
    remote = _FakeJournalRemoteDataSource()..currentUserId = 'user-a';
    repository = JournalEntriesRepository(
      database: database,
      supabaseClient: client,
      remoteDataSource: remote,
    );
  });

  tearDown(() async {
    await database.close();
    client.dispose();
  });

  test('new save creates one cloud row and one visible local row', () async {
    await repository.save('A journal entry with enough text.');

    expect(remote.insertCalls, 1);
    expect(remote.cloud, hasLength(1));
    expect(await database.select(database.journalEntries).get(), hasLength(1));
    expect(await repository.watchAll().first, hasLength(1));
  });

  test('save racing with cloud refresh still creates one local row', () async {
    remote.insertReturnGate = Completer<void>();

    final save = repository.save('A journal entry saved during refresh.');
    await remote.insertObserved.future;
    await repository.fetchAndSyncFromSupabase();
    remote.insertReturnGate!.complete();
    await save;

    expect(remote.cloud, hasLength(1));
    final rows = await database.select(database.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.supabaseId, remote.cloud.keys.single);
  });

  test('repeated fetch and repository restart remain idempotent', () async {
    remote.cloud['cloud-old'] = _cloudEntry('cloud-old');

    await repository.fetchAndSyncFromSupabase();
    await repository.fetchAndSyncFromSupabase();
    final afterRepeatedFetch =
        await database.select(database.journalEntries).get();
    expect(afterRepeatedFetch, hasLength(1));

    final restartedRepository = JournalEntriesRepository(
      database: database,
      supabaseClient: client,
      remoteDataSource: remote,
    );
    await restartedRepository.fetchAndSyncFromSupabase();

    expect(await database.select(database.journalEntries).get(), hasLength(1));
    expect(await restartedRepository.watchAll().first, hasLength(1));
  });

  test('concurrent fetch calls share one in-flight cloud request', () async {
    remote.cloud['cloud-one'] = _cloudEntry('cloud-one');
    remote.fetchReturnGate = Completer<void>();

    final first = repository.fetchAndSyncFromSupabase();
    await remote.fetchObserved.future;
    final second = repository.fetchAndSyncFromSupabase();
    expect(remote.fetchCalls, 1);

    remote.fetchReturnGate!.complete();
    await Future.wait([first, second]);

    expect(remote.fetchCalls, 1);
    expect(await database.select(database.journalEntries).get(), hasLength(1));
  });

  test('legacy duplicate for current user reconciles to one cache row',
      () async {
    await database.customStatement(
      'DROP INDEX journal_entries_user_cloud_unique',
    );
    await _insertLocal(database, userId: 'user-a', cloudId: 'cloud-dup');
    await _insertLocal(database, userId: 'user-a', cloudId: 'cloud-dup');

    final removed = await repository.reconcileLocalDuplicatesForCurrentUser();

    expect(removed, 1);
    final rows = await database.select(database.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.supabaseId, 'cloud-dup');
  });

  test('reconciliation never changes another users cache rows', () async {
    await database.customStatement(
      'DROP INDEX journal_entries_user_cloud_unique',
    );
    await _insertLocal(database, userId: 'user-a', cloudId: 'cloud-a');
    await _insertLocal(database, userId: 'user-b', cloudId: 'cloud-b');
    await _insertLocal(database, userId: 'user-b', cloudId: 'cloud-b');

    await repository.reconcileLocalDuplicatesForCurrentUser();

    final userA = await (database.select(database.journalEntries)
          ..where((table) => table.userId.equals('user-a')))
        .get();
    final userB = await (database.select(database.journalEntries)
          ..where((table) => table.userId.equals('user-b')))
        .get();
    expect(userA, hasLength(1));
    expect(userB, hasLength(2));
  });

  test('local rows without a Supabase ID are never content-deduplicated',
      () async {
    await _insertLocal(database, userId: 'user-a');
    await _insertLocal(database, userId: 'user-a');

    final removed = await repository.reconcileLocalDuplicatesForCurrentUser();

    expect(removed, 0);
    expect(await database.select(database.journalEntries).get(), hasLength(2));
  });

  test('database index rejects the same user and cloud identity twice',
      () async {
    await _insertLocal(database, userId: 'user-a', cloudId: 'cloud-unique');

    await expectLater(
      _insertLocal(database, userId: 'user-a', cloudId: 'cloud-unique'),
      throwsA(isA<Exception>()),
    );

    await _insertLocal(database, userId: 'user-b', cloudId: 'cloud-unique');
    await _insertLocal(database, userId: 'user-a');
    await _insertLocal(database, userId: 'user-a');
    expect(await database.select(database.journalEntries).get(), hasLength(4));
  });
}

Future<void> _insertLocal(
  AppDatabase database, {
  required String userId,
  String? cloudId,
}) async {
  await database.into(database.journalEntries).insert(
        JournalEntriesCompanion.insert(
          createdAt: DateTime.utc(2026, 8, 11, 12),
          content: 'Local journal cache row.',
          userId: Value(userId),
          supabaseId: Value(cloudId),
        ),
      );
}

Map<String, dynamic> _cloudEntry(String id) => {
      'id': id,
      'user_id': 'user-a',
      'content': 'Cloud journal entry.',
      'created_at': '2026-08-11T09:00:00.000Z',
      'updated_at': '2026-08-11T09:00:00.000Z',
    };

class _FakeJournalRemoteDataSource implements JournalEntriesRemoteDataSource {
  @override
  String? currentUserId;

  final Map<String, Map<String, dynamic>> cloud = {};
  int insertCalls = 0;
  int fetchCalls = 0;
  Completer<void>? insertReturnGate;
  Completer<void>? fetchReturnGate;
  Completer<void> insertObserved = Completer<void>();
  Completer<void> fetchObserved = Completer<void>();

  @override
  Future<Map<String, dynamic>> insertEntry(
    Map<String, dynamic> payload,
  ) async {
    insertCalls++;
    final id = 'cloud-$insertCalls';
    cloud[id] = {
      ...payload,
      'id': id,
    };
    if (!insertObserved.isCompleted) insertObserved.complete();
    await insertReturnGate?.future;
    return {'id': id};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEntries(String userId) async {
    fetchCalls++;
    if (!fetchObserved.isCompleted) fetchObserved.complete();
    final snapshot = cloud.values
        .where((row) => row['user_id'] == userId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
    await fetchReturnGate?.future;
    return snapshot;
  }
}
