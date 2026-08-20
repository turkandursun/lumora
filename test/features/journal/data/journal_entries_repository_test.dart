import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/sync/user_content_sync.dart';
import 'package:mindful_journal/features/journal/data/journal_entries_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/fake_user_content_remote_data_source.dart';

void main() {
  late AppDatabase database;
  late SupabaseClient client;
  late FakeUserContentRemoteDataSource remote;
  late JournalEntriesRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('http://localhost:54321', 'test-anon-key');
    remote = FakeUserContentRemoteDataSource()..online = false;
    repository = JournalEntriesRepository(
      database: database,
      supabaseClient: client,
      remoteDataSource: remote,
      uuidGenerator: () => '00000000-0000-4000-8000-000000000001',
    );
  });

  tearDown(() async {
    await database.close();
    client.dispose();
  });

  test('offline create stays visible and pending, then retries idempotently',
      () async {
    await repository.save('Offline journal');
    await _settle();

    var rows = await database.select(database.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.syncState, contentSyncPendingUpsert);
    expect(await repository.watchAll().first, hasLength(1));

    remote.online = true;
    await repository.syncForCurrentUser();
    await repository.syncForCurrentUser();

    rows = await database.select(database.journalEntries).get();
    expect(rows.single.syncState, contentSyncSynced);
    expect(remote.table('journal_entries'), hasLength(1));
  });

  test('offline update remains pending and the retry sends latest content',
      () async {
    await _insertSynced(database);
    await repository.update(1, content: 'Latest local content');
    await _settle();

    expect(
      (await database.select(database.journalEntries).getSingle()).syncState,
      contentSyncPendingUpsert,
    );
    remote.online = true;
    await repository.syncForCurrentUser();
    expect(
      remote.table('journal_entries')['cloud-journal']?['content'],
      'Latest local content',
    );
  });

  test('offline delete is a hidden tombstone and pull cannot resurrect it',
      () async {
    await _insertSynced(database);
    remote.table('journal_entries')['cloud-journal'] = _cloudJournal();
    await repository.delete(1, supabaseId: 'cloud-journal');
    await _settle();

    final tombstone =
        await database.select(database.journalEntries).getSingle();
    expect(tombstone.syncState, contentSyncPendingDelete);
    expect(await repository.watchAll().first, isEmpty);

    remote.online = true;
    await repository.syncForCurrentUser();
    expect(await database.select(database.journalEntries).get(), isEmpty);
    expect(remote.table('journal_entries'), isEmpty);
  });

  test('late account A push never acknowledges A row after B signs in',
      () async {
    await repository.save('Account A pending');
    await _settle();
    remote.online = true;
    remote.upsertObserved = Completer<void>();
    remote.upsertGate = Completer<void>();

    final sync = repository.syncForCurrentUser();
    await remote.upsertObserved.future;
    remote.currentUserId = 'user-b';
    remote.upsertGate!.complete();
    await sync;

    final row = await database.select(database.journalEntries).getSingle();
    expect(row.userId, 'user-a');
    expect(row.syncState, contentSyncPendingUpsert);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('a newer local mutation is drained after an older response', () async {
    remote.online = true;
    remote.upsertGate = Completer<void>();
    remote.upsertObserved = Completer<void>();
    await repository.save('First');
    await remote.upsertObserved.future;
    final row = await database.select(database.journalEntries).getSingle();
    await repository.update(row.id, content: 'Second');
    remote.upsertGate!.complete();
    remote.upsertGate = null;
    await repository.syncForCurrentUser();
    expect(
      (await database.select(database.journalEntries).getSingle()).syncState,
      contentSyncSynced,
    );
    expect(
      remote.table('journal_entries').values.single['content'],
      'Second',
    );
  });

  test('duplicate cloud identity reconciliation remains user-scoped', () async {
    await database.customStatement(
      'DROP INDEX journal_entries_user_cloud_unique',
    );
    await _insertSynced(database);
    await database.into(database.journalEntries).insert(
          JournalEntriesCompanion.insert(
            createdAt: DateTime.utc(2026, 8, 20, 11),
            content: 'Duplicate cache',
            userId: const Value('user-a'),
            supabaseId: const Value('cloud-journal'),
          ),
        );
    await database.into(database.journalEntries).insert(
          JournalEntriesCompanion.insert(
            createdAt: DateTime.utc(2026, 8, 20, 12),
            content: 'Other account',
            userId: const Value('user-b'),
            supabaseId: const Value('cloud-journal'),
          ),
        );

    expect(await repository.reconcileLocalDuplicatesForCurrentUser(), 1);
    expect(
      await (database.select(database.journalEntries)
            ..where((table) => table.userId.equals('user-a')))
          .get(),
      hasLength(1),
    );
    expect(
      await (database.select(database.journalEntries)
            ..where((table) => table.userId.equals('user-b')))
          .get(),
      hasLength(1),
    );
  });
}

Future<void> _insertSynced(AppDatabase database) async {
  await database.into(database.journalEntries).insert(
        JournalEntriesCompanion.insert(
          createdAt: DateTime.utc(2026, 8, 20, 10),
          content: 'Cloud-backed',
          userId: const Value('user-a'),
          supabaseId: const Value('cloud-journal'),
          syncState: const Value(contentSyncSynced),
          changedAt: Value(DateTime.utc(2026, 8, 20, 10)),
        ),
      );
}

Map<String, dynamic> _cloudJournal() => {
      'id': 'cloud-journal',
      'user_id': 'user-a',
      'content': 'Cloud-backed',
      'created_at': '2026-08-20T10:00:00.000Z',
      'updated_at': '2026-08-20T10:00:00.000Z',
    };

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
