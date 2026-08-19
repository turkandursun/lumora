import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../domain/active_focus_session.dart';

const _pendingFocusSyncState = 'pending';
const _syncedFocusSyncState = 'synced';

class FocusMetrics {
  const FocusMetrics({
    this.completedSessionsToday = 0,
    this.actualFocusSecondsToday = 0,
    this.actualFocusSecondsThisWeek = 0,
    this.streak = 0,
  });

  final int completedSessionsToday;
  final int actualFocusSecondsToday;
  final int actualFocusSecondsThisWeek;
  final int streak;

  int get actualFocusMinutesToday => actualFocusSecondsToday ~/ 60;
  int get actualFocusMinutesThisWeek => actualFocusSecondsThisWeek ~/ 60;
}

class FocusStats extends FocusMetrics {
  const FocusStats({
    super.completedSessionsToday,
    super.actualFocusSecondsToday,
    super.actualFocusSecondsThisWeek,
    super.streak,
    this.goal = 5,
  });

  final int goal;

  FocusStats withMetrics(FocusMetrics metrics) => FocusStats(
        completedSessionsToday: metrics.completedSessionsToday,
        actualFocusSecondsToday: metrics.actualFocusSecondsToday,
        actualFocusSecondsThisWeek: metrics.actualFocusSecondsThisWeek,
        streak: metrics.streak,
        goal: goal,
      );

  FocusStats withGoal(int nextGoal) => FocusStats(
        completedSessionsToday: completedSessionsToday,
        actualFocusSecondsToday: actualFocusSecondsToday,
        actualFocusSecondsThisWeek: actualFocusSecondsThisWeek,
        streak: streak,
        goal: nextGoal,
      );

  static const empty = FocusStats();
}

abstract interface class FocusSessionGateway {
  String? get currentUserId;

  Future<bool> recordCompletedSession({
    required String sessionUuid,
    required int plannedDurationSeconds,
    required int actualDurationSeconds,
    required DateTime startedAt,
    required DateTime endedAt,
    String? taskLabel,
  });

  Future<void> syncForCurrentUser();
}

abstract interface class FocusRemoteDataSource {
  String? get currentUserId;
  Future<Map<String, dynamic>> upsertSession(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> fetchSessions(String userId);
}

class SupabaseFocusRemoteDataSource implements FocusRemoteDataSource {
  SupabaseFocusRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>> upsertSession(
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .from('focus_sessions')
        .upsert(payload, onConflict: 'id')
        .select('id, updated_at')
        .single();
    return Map<String, dynamic>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSessions(String userId) async {
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0;; offset += pageSize) {
      final response = await _client
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .order('started_at')
          .range(offset, offset + pageSize - 1);
      rows.addAll(response.map((row) => Map<String, dynamic>.from(row)));
      if (response.length < pageSize) break;
    }
    return rows;
  }
}

/// User-scoped local-first store for completed focus intervals.
class FocusRepository implements FocusSessionGateway {
  FocusRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting FocusRemoteDataSource? remoteDataSource,
    @visibleForTesting DateTime Function()? clock,
  })  : _db = database,
        _remote = remoteDataSource ??
            SupabaseFocusRemoteDataSource(
              supabaseClient ?? Supabase.instance.client,
            ),
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final FocusRemoteDataSource _remote;
  final DateTime Function() _clock;
  final Map<String, Future<void>> _syncsInFlight = {};
  final Set<String> _syncRequestedAgain = {};

  @override
  String? get currentUserId => _remote.currentUserId;

  void initialize() => unawaited(syncForCurrentUser());

  @override
  Future<bool> recordCompletedSession({
    required String sessionUuid,
    required int plannedDurationSeconds,
    required int actualDurationSeconds,
    required DateTime startedAt,
    required DateTime endedAt,
    String? taskLabel,
  }) async {
    final userId = currentUserId;
    if (userId == null ||
        sessionUuid.isEmpty ||
        plannedDurationSeconds <= 0 ||
        actualDurationSeconds < 0 ||
        endedAt.isBefore(startedAt)) {
      return false;
    }
    final label = normalizeFocusTaskLabel(taskLabel);
    var accepted = false;
    var inserted = false;
    try {
      await _db.transaction(() async {
        final existing = await (_db.select(_db.focusSessions)
              ..where(
                (table) =>
                    table.userId.equals(userId) &
                    table.sessionUuid.equals(sessionUuid),
              ))
            .getSingleOrNull();
        if (existing != null) {
          accepted = true;
          return;
        }
        if (currentUserId != userId) return;
        await _db.into(_db.focusSessions).insert(
              FocusSessionsCompanion.insert(
                sessionUuid: sessionUuid,
                userId: userId,
                taskLabel: Value(label),
                plannedDurationSeconds: plannedDurationSeconds,
                actualDurationSeconds: actualDurationSeconds,
                startedAt: startedAt.toUtc(),
                endedAt: endedAt.toUtc(),
                syncState: const Value(_pendingFocusSyncState),
                changedAt: Value(_clock().toUtc()),
              ),
            );
        accepted = true;
        inserted = true;
      });
    } catch (error) {
      debugPrint('[Focus] local insert deferred error=${error.runtimeType}');
      return false;
    }
    if (!accepted || currentUserId != userId) return false;
    if (inserted) {
      debugPrint('[Focus] local completed session id=$sessionUuid');
    }
    unawaited(syncForCurrentUser());
    return true;
  }

  Stream<FocusMetrics> watchMetricsForCurrentUser() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(const FocusMetrics());
    return (_db.select(_db.focusSessions)
          ..where((table) => table.userId.equals(userId)))
        .watch()
        .map((rows) => _calculateMetrics(rows, _clock()));
  }

  Future<FocusMetrics> loadMetricsForCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return const FocusMetrics();
    final rows = await (_db.select(_db.focusSessions)
          ..where((table) => table.userId.equals(userId)))
        .get();
    if (currentUserId != userId) return const FocusMetrics();
    return _calculateMetrics(rows, _clock());
  }

  @override
  Future<void> syncForCurrentUser() {
    final userId = currentUserId;
    if (userId == null) return Future.value();
    final existing = _syncsInFlight[userId];
    if (existing != null) {
      _syncRequestedAgain.add(userId);
      return existing;
    }
    late final Future<void> operation;
    operation = _runSyncLoop(userId).whenComplete(() {
      if (identical(_syncsInFlight[userId], operation)) {
        _syncsInFlight.remove(userId);
      }
    });
    _syncsInFlight[userId] = operation;
    return operation;
  }

  Future<void> _runSyncLoop(String userId) async {
    for (var pass = 0; pass < 2; pass++) {
      _syncRequestedAgain.remove(userId);
      await _performSync(userId);
      if (currentUserId != userId || !_syncRequestedAgain.remove(userId)) {
        break;
      }
    }
  }

  Future<void> _performSync(String userId) async {
    try {
      await _pushPending(userId);
      if (currentUserId != userId) return;
      await _pullCloud(userId);
    } catch (error) {
      debugPrint('[Focus] sync deferred error=${error.runtimeType}');
    }
  }

  Future<void> _pushPending(String userId) async {
    final rows = await (_db.select(_db.focusSessions)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.syncState.equals(_pendingFocusSyncState),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.changedAt)]))
        .get();
    for (final row in rows) {
      if (currentUserId != userId) return;
      final pushedChangedAt = row.changedAt;
      try {
        final response = await _remote.upsertSession(_payload(row, userId));
        if (currentUserId != userId) return;
        final updatedAt = _parseDateTime(response['updated_at']);
        await (_db.update(_db.focusSessions)
              ..where(
                (table) =>
                    table.id.equals(row.id) &
                    table.userId.equals(userId) &
                    table.sessionUuid.equals(row.sessionUuid) &
                    table.syncState.equals(_pendingFocusSyncState) &
                    table.changedAt.equals(pushedChangedAt),
              ))
            .write(
          FocusSessionsCompanion(
            syncState: const Value(_syncedFocusSyncState),
            cloudUpdatedAt: Value(updatedAt),
            lastSyncedAt: Value(_clock().toUtc()),
          ),
        );
      } catch (error) {
        debugPrint(
          '[Focus] push deferred id=${row.sessionUuid} '
          'error=${error.runtimeType}',
        );
      }
    }
  }

  Future<void> _pullCloud(String userId) async {
    final cloudRows = await _remote.fetchSessions(userId);
    if (currentUserId != userId) return;
    for (final raw in cloudRows) {
      if (currentUserId != userId) return;
      if (raw['user_id'] != userId) continue;
      final cloud = _CloudFocusSession.tryParse(raw);
      if (cloud == null) continue;
      final local = await (_db.select(_db.focusSessions)
            ..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.sessionUuid.equals(cloud.id),
            ))
          .getSingleOrNull();
      if (currentUserId != userId) return;
      if (local?.syncState == _pendingFocusSyncState) continue;
      if (local == null) {
        await _db.into(_db.focusSessions).insert(
              FocusSessionsCompanion.insert(
                sessionUuid: cloud.id,
                userId: userId,
                taskLabel: Value(cloud.taskLabel),
                plannedDurationSeconds: cloud.plannedDurationSeconds,
                actualDurationSeconds: cloud.actualDurationSeconds,
                startedAt: cloud.startedAt,
                endedAt: cloud.endedAt,
                syncState: const Value(_syncedFocusSyncState),
                changedAt: Value(cloud.updatedAt ?? cloud.endedAt),
                cloudUpdatedAt: Value(cloud.updatedAt),
                lastSyncedAt: Value(_clock().toUtc()),
              ),
            );
      } else {
        await (_db.update(_db.focusSessions)
              ..where(
                (table) =>
                    table.id.equals(local.id) & table.userId.equals(userId),
              ))
            .write(
          FocusSessionsCompanion(
            taskLabel: Value(cloud.taskLabel),
            plannedDurationSeconds: Value(cloud.plannedDurationSeconds),
            actualDurationSeconds: Value(cloud.actualDurationSeconds),
            startedAt: Value(cloud.startedAt),
            endedAt: Value(cloud.endedAt),
            syncState: const Value(_syncedFocusSyncState),
            changedAt: Value(cloud.updatedAt ?? cloud.endedAt),
            cloudUpdatedAt: Value(cloud.updatedAt),
            lastSyncedAt: Value(_clock().toUtc()),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _payload(FocusSessionRow row, String userId) => {
        'id': row.sessionUuid,
        'user_id': userId,
        'task_label': row.taskLabel,
        'planned_duration_seconds': row.plannedDurationSeconds,
        'actual_duration_seconds': row.actualDurationSeconds,
        'started_at': row.startedAt.toUtc().toIso8601String(),
        'ended_at': row.endedAt.toUtc().toIso8601String(),
      };
}

FocusMetrics _calculateMetrics(List<FocusSessionRow> rows, DateTime now) {
  final localNow = now.toLocal();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  var sessionsToday = 0;
  var secondsToday = 0;
  var secondsThisWeek = 0;
  final activeDates = <DateTime>{};
  for (final row in rows) {
    final localEnd = row.endedAt.toLocal();
    final day = DateTime(localEnd.year, localEnd.month, localEnd.day);
    activeDates.add(day);
    if (day == today) {
      sessionsToday++;
      secondsToday += row.actualDurationSeconds;
    }
    if (!day.isBefore(weekStart) && !day.isAfter(today)) {
      secondsThisWeek += row.actualDurationSeconds;
    }
  }
  var cursor = activeDates.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;
  while (activeDates.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return FocusMetrics(
    completedSessionsToday: sessionsToday,
    actualFocusSecondsToday: secondsToday,
    actualFocusSecondsThisWeek: secondsThisWeek,
    streak: streak,
  );
}

class _CloudFocusSession {
  const _CloudFocusSession({
    required this.id,
    required this.taskLabel,
    required this.plannedDurationSeconds,
    required this.actualDurationSeconds,
    required this.startedAt,
    required this.endedAt,
    required this.updatedAt,
  });

  final String id;
  final String? taskLabel;
  final int plannedDurationSeconds;
  final int actualDurationSeconds;
  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime? updatedAt;

  static _CloudFocusSession? tryParse(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final planned = (row['planned_duration_seconds'] as num?)?.toInt();
    final actual = (row['actual_duration_seconds'] as num?)?.toInt();
    final startedAt = _parseDateTime(row['started_at']);
    final endedAt = _parseDateTime(row['ended_at']);
    if (id == null ||
        id.isEmpty ||
        planned == null ||
        planned <= 0 ||
        actual == null ||
        actual < 0 ||
        startedAt == null ||
        endedAt == null ||
        endedAt.isBefore(startedAt)) {
      return null;
    }
    return _CloudFocusSession(
      id: id,
      taskLabel: normalizeFocusTaskLabel(row['task_label'] as String?),
      plannedDurationSeconds: planned,
      actualDurationSeconds: actual,
      startedAt: startedAt,
      endedAt: endedAt,
      updatedAt: _parseDateTime(row['updated_at']),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}
