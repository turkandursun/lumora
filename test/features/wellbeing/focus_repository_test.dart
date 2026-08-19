import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/features/wellbeing/data/focus_repository.dart';

void main() {
  late AppDatabase database;
  late _FakeFocusRemote remote;
  late DateTime now;
  late FocusRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = _FakeFocusRemote()..currentUserId = 'user-a';
    now = DateTime(2026, 8, 19, 12);
    repository = FocusRepository(
      database: database,
      remoteDataSource: remote,
      clock: () => now,
    );
  });

  tearDown(() => database.close());

  test('completed session is local-first and duplicate UUID is idempotent',
      () async {
    remote.failWrites = true;
    final first = await _record(repository, 'stable-id', now);
    final duplicate = await _record(repository, 'stable-id', now);
    await repository.syncForCurrentUser();

    final rows = await database.select(database.focusSessions).get();
    expect(first, isTrue);
    expect(duplicate, isTrue);
    expect(rows, hasLength(1));
    expect(rows.single.syncState, 'pending');
  });

  test('offline pending session becomes synced on retry', () async {
    remote.failWrites = true;
    await _record(repository, 'offline-id', now);
    await repository.syncForCurrentUser();
    expect(
      (await database.select(database.focusSessions).get()).single.syncState,
      'pending',
    );

    remote.failWrites = false;
    await repository.syncForCurrentUser();

    expect(remote.rows['offline-id']?['user_id'], 'user-a');
    expect(
      (await database.select(database.focusSessions).get()).single.syncState,
      'synced',
    );
  });

  test('completed count, daily/week minutes and streak derive from history',
      () async {
    remote.failWrites = true;
    await _record(repository, 'today-1', now, actualSeconds: 1500);
    await _record(
      repository,
      'today-2',
      now.subtract(const Duration(hours: 1)),
      actualSeconds: 900,
    );
    await _record(
      repository,
      'yesterday',
      now.subtract(const Duration(days: 1)),
      actualSeconds: 600,
    );
    await _record(
      repository,
      'two-days',
      now.subtract(const Duration(days: 2)),
      actualSeconds: 300,
    );

    final metrics = await repository.loadMetricsForCurrentUser();
    expect(metrics.completedSessionsToday, 2);
    expect(metrics.actualFocusMinutesToday, 40);
    expect(metrics.actualFocusMinutesThisWeek, 55);
    expect(metrics.streak, 3);
  });

  test('user A history is not visible after switching to user B', () async {
    remote.failWrites = true;
    await _record(repository, 'a-id', now);

    remote.currentUserId = 'user-b';
    await _record(repository, 'b-id', now);
    final metricsB = await repository.loadMetricsForCurrentUser();
    final rowsB = await (database.select(database.focusSessions)
          ..where((table) => table.userId.equals('user-b')))
        .get();

    expect(metricsB.completedSessionsToday, 1);
    expect(rowsB.map((row) => row.sessionUuid), ['b-id']);
  });

  test('late cloud response for user A is ignored after account switch',
      () async {
    final fetch = Completer<List<Map<String, dynamic>>>();
    remote.nextFetch = fetch;
    final syncA = repository.syncForCurrentUser();
    await remote.fetchStarted.future;

    remote.currentUserId = 'user-b';
    fetch.complete([
      _cloudRow('cloud-a', 'user-a', now),
    ]);
    await syncA;

    expect(await database.select(database.focusSessions).get(), isEmpty);
  });

  test('cloud pull is idempotent for the same stable UUID', () async {
    remote.rows['cloud-id'] = _cloudRow('cloud-id', 'user-a', now);

    await repository.syncForCurrentUser();
    await repository.syncForCurrentUser();

    final rows = await database.select(database.focusSessions).get();
    expect(rows, hasLength(1));
    expect(rows.single.sessionUuid, 'cloud-id');
  });
}

Future<bool> _record(
  FocusRepository repository,
  String id,
  DateTime endedAt, {
  int actualSeconds = 60,
}) {
  return repository.recordCompletedSession(
    sessionUuid: id,
    plannedDurationSeconds: actualSeconds,
    actualDurationSeconds: actualSeconds,
    startedAt: endedAt.subtract(Duration(seconds: actualSeconds)),
    endedAt: endedAt,
    taskLabel: 'task',
  );
}

Map<String, dynamic> _cloudRow(
  String id,
  String userId,
  DateTime endedAt,
) =>
    {
      'id': id,
      'user_id': userId,
      'task_label': null,
      'planned_duration_seconds': 60,
      'actual_duration_seconds': 60,
      'started_at': endedAt
          .subtract(const Duration(seconds: 60))
          .toUtc()
          .toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'updated_at': endedAt.toUtc().toIso8601String(),
    };

class _FakeFocusRemote implements FocusRemoteDataSource {
  @override
  String? currentUserId;

  bool failWrites = false;
  final rows = <String, Map<String, dynamic>>{};
  Completer<List<Map<String, dynamic>>>? nextFetch;
  Completer<void> fetchStarted = Completer<void>();

  @override
  Future<List<Map<String, dynamic>>> fetchSessions(String userId) async {
    if (!fetchStarted.isCompleted) fetchStarted.complete();
    final pending = nextFetch;
    nextFetch = null;
    if (pending != null) return pending.future;
    return rows.values
        .where((row) => row['user_id'] == userId)
        .map(Map<String, dynamic>.from)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> upsertSession(
    Map<String, dynamic> payload,
  ) async {
    if (failWrites) throw StateError('offline');
    rows[payload['id'] as String] = Map<String, dynamic>.from(payload)
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return {
      'id': payload['id'],
      'updated_at': rows[payload['id']]!['updated_at'],
    };
  }
}
