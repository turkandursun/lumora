import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/goals_table.dart';
import '../domain/goal_template.dart';

const _activeGoalStatus = 'active';
const _archivedGoalStatus = 'archived';
const _pendingSyncState = 'pending';
const _syncedSyncState = 'synced';
const _activeTemplateIndexName = 'goals_user_active_template_unique';

class GoalsActiveTemplateConflict implements Exception {
  const GoalsActiveTemplateConflict(this.cause);

  final Object cause;

  @override
  String toString() => cause.toString();
}

/// Small boundary around Supabase so repository sync behavior can be tested
/// without weakening the production auth source. The production implementation
/// always reads the current user from [SupabaseClient.auth].
abstract interface class GoalsRemoteDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>> upsertGoal(Map<String, dynamic> payload);

  Future<List<Map<String, dynamic>>> fetchGoals(String userId);

  Future<Map<String, dynamic>?> findActiveGoalByTemplate({
    required String userId,
    required String templateKey,
  });
}

class SupabaseGoalsRemoteDataSource implements GoalsRemoteDataSource {
  SupabaseGoalsRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>> upsertGoal(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _client
          .from('goals')
          .upsert(payload, onConflict: 'id')
          .select('id, updated_at')
          .single();
      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (error) {
      if (error.code == '23505' &&
          (error.message.contains(_activeTemplateIndexName) ||
              error.details.toString().contains(_activeTemplateIndexName))) {
        throw GoalsActiveTemplateConflict(error);
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGoals(String userId) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .inFilter('status', const [_activeGoalStatus, _archivedGoalStatus]);
    return response
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> findActiveGoalByTemplate({
    required String userId,
    required String templateKey,
  }) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .eq('template_key', templateKey)
        .eq('status', _activeGoalStatus)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }
}

const customGoalIconKey = 'custom';

class GoalStreak {
  const GoalStreak({this.count = 0, this.lastActiveDate});

  final int count;
  final DateTime? lastActiveDate;
}

/// User-scoped, local-first persistence for goals.
///
/// Drift is always updated before cloud work. Supabase writes use the UUID
/// stored in [GoalRow.supabaseId], making retries idempotent.
class GoalsRepository {
  GoalsRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting GoalsRemoteDataSource? remoteDataSource,
    @visibleForTesting String Function()? uuidGenerator,
    @visibleForTesting DateTime Function()? clock,
  })  : _db = database,
        _remote = remoteDataSource ??
            SupabaseGoalsRemoteDataSource(
              supabaseClient ?? Supabase.instance.client,
            ),
        _uuidGenerator = uuidGenerator ?? _newUuidV4,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final GoalsRemoteDataSource _remote;
  final String Function() _uuidGenerator;
  final DateTime Function() _clock;
  final Map<String, Future<void>> _syncsInFlight = {};
  final Set<String> _syncRequestedAgain = {};

  String? get _currentUserId => _remote.currentUserId;

  String _streakCountKey(String userId) => 'goals_streak_count_$userId';
  String _streakLastActiveKey(String userId) =>
      'goals_streak_last_active_date_$userId';

  /// Starts background sync without delaying the first Drift stream frame.
  void initialize() {
    unawaited(syncForCurrentUser());
  }

  /// Only active goals belonging to the authenticated user are published.
  Stream<List<GoalRow>> watchAll() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.status.equals(_activeGoalStatus),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .watch();
  }

  Stream<List<GoalRow>> watchArchivedGoalsForCurrentUser() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.status.equals(_archivedGoalStatus),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.changedAt)]))
        .watch();
  }

  /// Inserts locally first and schedules an idempotent UUID upsert.
  Future<void> addCustomGoal({
    required String title,
    required GoalUnit unit,
    String? customUnitLabel,
    required int target,
    required GoalFrequency frequency,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = _clock();
    final changedAt = now.toUtc();
    final remoteId = _uuidGenerator();

    await _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            title: title,
            iconKey: customGoalIconKey,
            unit: unit,
            customUnitLabel: Value(customUnitLabel),
            target: target,
            frequency: frequency,
            periodStart: expectedPeriodStart(frequency, now),
            userId: Value(userId),
            supabaseId: Value(remoteId),
            status: const Value(_activeGoalStatus),
            syncState: const Value(_pendingSyncState),
            changedAt: Value(changedAt),
          ),
        );
    debugPrint('[Goals] local pending create id=$remoteId');
    unawaited(syncForCurrentUser());
  }

  /// Creates a real user goal only after a catalogue template is selected.
  /// Returns false when the same template is already active locally/cloud.
  Future<bool> addGoalFromTemplate({
    required GoalTemplate template,
    required String localizedTitle,
    String? localizedCustomUnitLabel,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final localExisting = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.templateKey.equals(template.key) &
                table.status.equals(_activeGoalStatus),
          ))
        .getSingleOrNull();
    if (localExisting != null || _currentUserId != userId) return false;

    try {
      final cloudExisting = await _remote.findActiveGoalByTemplate(
        userId: userId,
        templateKey: template.key,
      );
      if (_currentUserId != userId) return false;
      if (cloudExisting != null) {
        await syncForCurrentUser();
        return false;
      }
    } catch (error) {
      // Offline creation remains available. The local and cloud unique guards,
      // plus 23505 adoption, make the later retry idempotent.
      debugPrint('[Goals] template preflight offline: $error');
    }

    final now = _clock();
    final remoteId = _uuidGenerator();
    try {
      await _db.into(_db.goals).insert(
            GoalsCompanion.insert(
              title: localizedTitle,
              iconKey: template.iconKey,
              unit: template.unit,
              customUnitLabel: Value(
                template.unit == GoalUnit.custom
                    ? localizedCustomUnitLabel
                    : null,
              ),
              target: template.defaultTarget,
              frequency: template.frequency,
              periodStart: expectedPeriodStart(template.frequency, now),
              userId: Value(userId),
              supabaseId: Value(remoteId),
              templateKey: Value(template.key),
              status: const Value(_activeGoalStatus),
              syncState: const Value(_pendingSyncState),
              changedAt: Value(now.toUtc()),
            ),
          );
    } catch (error) {
      final nowExists = await (_db.select(_db.goals)
            ..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.templateKey.equals(template.key) &
                  table.status.equals(_activeGoalStatus),
            ))
          .getSingleOrNull();
      if (nowExists != null) return false;
      rethrow;
    }

    debugPrint('[Goals] template goal created template=${template.key}');
    unawaited(syncForCurrentUser());
    return true;
  }

  /// Updates editable fields locally first. Unit/frequency changes reset the
  /// current period; lowering target clamps progress to the new target.
  Future<bool> updateGoal({
    required int localId,
    required String title,
    required int target,
    required GoalUnit unit,
    String? customUnitLabel,
    required GoalFrequency frequency,
  }) async {
    final userId = _currentUserId;
    if (userId == null || title.trim().isEmpty || target <= 0) return false;
    if (unit == GoalUnit.custom &&
        (customUnitLabel == null || customUnitLabel.trim().isEmpty)) {
      return false;
    }

    final now = _clock();
    final changedAt = now.toUtc();
    var updated = false;
    String? remoteId;
    await _db.transaction(() async {
      final current = await (_db.select(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(localId) &
                  table.userId.equals(userId) &
                  table.status.equals(_activeGoalStatus),
            ))
          .getSingleOrNull();
      if (current == null || _currentUserId != userId) return;

      final resetsProgress =
          current.unit != unit || current.frequency != frequency;
      final nextProgress =
          resetsProgress ? 0 : current.progress.clamp(0, target).toInt();
      remoteId = current.supabaseId ?? _uuidGenerator();
      final affected = await (_db.update(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(localId) &
                  table.userId.equals(userId) &
                  table.status.equals(_activeGoalStatus),
            ))
          .write(
        GoalsCompanion(
          title: Value(title.trim()),
          target: Value(target),
          unit: Value(unit),
          customUnitLabel: Value(
            unit == GoalUnit.custom ? customUnitLabel!.trim() : null,
          ),
          frequency: Value(frequency),
          progress: Value(nextProgress),
          periodStart: Value(
            current.frequency == frequency
                ? current.periodStart
                : expectedPeriodStart(frequency, now),
          ),
          supabaseId: Value(remoteId),
          syncState: const Value(_pendingSyncState),
          changedAt: Value(changedAt),
        ),
      );
      updated = affected > 0;
    });
    if (!updated || _currentUserId != userId) return false;
    debugPrint('[Goals] local pending update id=$remoteId');
    unawaited(syncForCurrentUser());
    return true;
  }

  /// Progress writes are scoped by both local ID and authenticated user ID.
  Future<bool> incrementProgress(GoalRow goal, int amount) async {
    final result = await _incrementProgressRow(goal.id, amount);
    return result.justCompleted;
  }

  Future<_GoalIncrementResult> _incrementProgressRow(
    int localId,
    int amount,
  ) async {
    final userId = _currentUserId;
    if (userId == null || amount == 0) return const _GoalIncrementResult();

    var result = const _GoalIncrementResult();
    await _db.transaction(() async {
      final current = await (_db.select(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(localId) &
                  table.userId.equals(userId) &
                  table.status.equals(_activeGoalStatus),
            ))
          .getSingleOrNull();
      if (current == null || _currentUserId != userId) return;

      final now = _clock();
      final expected = expectedPeriodStart(current.frequency, now);
      final periodChanged = !_isSameDate(current.periodStart, expected);
      final baseProgress = periodChanged ? 0 : current.progress;
      if (periodChanged) {
        debugPrint(
          '[Goals] period reset template=${current.templateKey ?? 'custom'} '
          'old=${current.periodStart.toIso8601String()} '
          'new=${expected.toIso8601String()}',
        );
      }
      final newProgress =
          (baseProgress + amount).clamp(0, current.target).toInt();
      if (!periodChanged && newProgress == current.progress) return;

      final remoteId = current.supabaseId ?? _uuidGenerator();
      final affected = await (_db.update(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(current.id) &
                  table.userId.equals(userId) &
                  table.status.equals(_activeGoalStatus),
            ))
          .write(
        GoalsCompanion(
          progress: Value(newProgress),
          periodStart: Value(expected),
          supabaseId: Value(remoteId),
          syncState: const Value(_pendingSyncState),
          changedAt: Value(now.toUtc()),
        ),
      );
      if (affected == 0 || _currentUserId != userId) return;
      result = _GoalIncrementResult(
        didAdvance: newProgress > baseProgress,
        justCompleted:
            baseProgress < current.target && newProgress >= current.target,
        remoteId: remoteId,
        progress: newProgress,
        target: current.target,
      );
    });
    if (!result.didAdvance || _currentUserId != userId) return result;

    await _recordActivityTodayForUser(userId);
    debugPrint(
      '[Goals] local pending progress id=${result.remoteId} '
      'progress=${result.progress}/${result.target}',
    );
    unawaited(syncForCurrentUser());
    return result;
  }

  /// Auto-progress entry point. Template identity, not presentation icon,
  /// decides which current-user active goal may change.
  Future<bool> incrementByTemplateKey(String templateKey, int amount) async {
    final userId = _currentUserId;
    if (userId == null || amount <= 0) return false;

    final goal = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.status.equals(_activeGoalStatus) &
                table.templateKey.equals(templateKey),
          ))
        .getSingleOrNull();
    if (goal == null || _currentUserId != userId) return false;

    final result = await _incrementProgressRow(goal.id, amount);
    if (result.didAdvance) {
      debugPrint(
        '[Goals] auto progress template=$templateKey amount=$amount',
      );
    }
    return result.didAdvance;
  }

  /// Soft-delete endpoint prepared for the later archive UI.
  Future<void> archiveGoal(int localId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final goal = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.id.equals(localId) &
                table.userId.equals(userId) &
                table.status.equals(_activeGoalStatus),
          ))
        .getSingleOrNull();
    if (goal == null || _currentUserId != userId) return;

    final remoteId = goal.supabaseId ?? _uuidGenerator();
    final affected = await (_db.update(_db.goals)
          ..where(
            (table) =>
                table.id.equals(localId) &
                table.userId.equals(userId) &
                table.status.equals(_activeGoalStatus),
          ))
        .write(
      GoalsCompanion(
        supabaseId: Value(remoteId),
        status: const Value(_archivedGoalStatus),
        syncState: const Value(_pendingSyncState),
        changedAt: Value(_clock().toUtc()),
      ),
    );
    if (affected == 0 || _currentUserId != userId) return;

    debugPrint('[Goals] local pending archive id=$remoteId');
    unawaited(syncForCurrentUser());
  }

  /// Explicit cache cleanup, deliberately not used by normal logout so an
  /// offline pending change can resume when this user signs in again.
  Future<void> clearLocalCacheForCurrentUser() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await (_db.delete(_db.goals)..where((table) => table.userId.equals(userId)))
        .go();
  }

  @Deprecated('Use clearLocalCacheForCurrentUser; global deletion is unsafe.')
  Future<void> deleteAll() => clearLocalCacheForCurrentUser();

  /// User-scoped single-flight synchronization.
  Future<void> syncForCurrentUser() {
    final userId = _currentUserId;
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
    // One queued follow-up pass captures mutations that arrive while network
    // work is in flight. Bounding the loop prevents a malformed/persistent
    // cloud conflict from spinning forever; any remaining pending row is
    // safely retried by the next initialization or user mutation.
    for (var pass = 0; pass < 2; pass++) {
      _syncRequestedAgain.remove(userId);
      await _performSync(userId);
      if (!_isCurrentUser(userId) || !_syncRequestedAgain.remove(userId)) {
        break;
      }
    }
  }

  Future<void> _performSync(String userId) async {
    debugPrint('[Goals] sync started user=$userId');
    try {
      await _prepareLegacyLocalOnlyGoalIds(userId);
      if (!_isCurrentUser(userId)) return _logAuthChanged();

      await _reconcileLegacyGoalDuplicates(userId);
      if (!_isCurrentUser(userId)) return _logAuthChanged();

      final canContinue = await _pushPendingGoals(userId);
      if (!canContinue || !_isCurrentUser(userId)) {
        return _logAuthChanged();
      }

      await _pullCloudGoals(userId);
      if (!_isCurrentUser(userId)) return _logAuthChanged();

      await _ensureActiveTemplateUniqueIndex();
      final duplicateGroups = await _countActiveDuplicateGroups(userId);
      debugPrint(
        '[Goals] active duplicate groups after reconciliation='
        '$duplicateGroups',
      );

      final localRows = await (_db.select(_db.goals)
            ..where((table) => table.userId.equals(userId)))
          .get();
      if (!_isCurrentUser(userId)) return _logAuthChanged();

      final activeCount =
          localRows.where((row) => row.status == _activeGoalStatus).length;
      final archivedCount =
          localRows.where((row) => row.status == _archivedGoalStatus).length;
      debugPrint('[Goals] local active count=$activeCount');
      debugPrint('[Goals] local archived count=$archivedCount');
      debugPrint('[Goals] sync completed');
    } catch (error) {
      debugPrint('[Goals] sync error: $error');
    }
  }

  Future<void> _prepareLegacyLocalOnlyGoalIds(String userId) async {
    final legacyRows = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.supabaseId.isNull() &
                table.syncState.equals(_pendingSyncState),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .get();
    if (legacyRows.isEmpty || !_isCurrentUser(userId)) return;

    await _db.transaction(() async {
      for (final row in legacyRows) {
        await (_db.update(_db.goals)
              ..where(
                (table) =>
                    table.id.equals(row.id) &
                    table.userId.equals(userId) &
                    table.supabaseId.isNull() &
                    table.syncState.equals(_pendingSyncState),
              ))
            .write(
          GoalsCompanion(
            supabaseId: Value(_uuidGenerator()),
            changedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }
    });
  }

  Future<void> reconcileLegacyGoalDuplicatesForCurrentUser() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _reconcileLegacyGoalDuplicates(userId);
  }

  Future<void> _reconcileLegacyGoalDuplicates(String userId) async {
    debugPrint('[Goals] legacy reconciliation started');

    List<Map<String, dynamic>> cloudRows = const [];
    try {
      cloudRows = await _remote.fetchGoals(userId);
    } catch (error) {
      // Local duplicate cleanup is still safe offline. If a matching cloud
      // row exists, the 23505 recovery below adopts it during pending push.
      debugPrint('[Goals] legacy cloud lookup error: $error');
    }
    if (!_isCurrentUser(userId)) return _logAuthChanged();

    final cloudByTemplate = <String, _CloudGoal>{};
    for (final raw in cloudRows) {
      if (raw['user_id'] != userId) continue;
      final cloud = _CloudGoal.tryParse(raw);
      if (cloud == null ||
          cloud.status != _activeGoalStatus ||
          cloud.templateKey == null) {
        continue;
      }
      cloudByTemplate[cloud.templateKey!] = cloud;
    }

    final localRows = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.status.equals(_activeGoalStatus) &
                table.templateKey.isNotNull(),
          ))
        .get();
    if (!_isCurrentUser(userId)) return _logAuthChanged();

    final groups = <String, List<GoalRow>>{};
    for (final row in localRows) {
      final templateKey = row.templateKey;
      if (templateKey == null) continue;
      groups.putIfAbsent(templateKey, () => []).add(row);
    }

    for (final entry in groups.entries) {
      if (!_isCurrentUser(userId)) return _logAuthChanged();
      final rows = entry.value;
      final cloud = cloudByTemplate[entry.key];
      final needsIdentityAdoption =
          cloud != null && rows.every((row) => row.supabaseId != cloud.id);
      if (rows.length == 1 && !needsIdentityAdoption) continue;

      if (rows.length > 1) {
        debugPrint(
          '[Goals] duplicate template=${entry.key} '
          'localCount=${rows.length}',
        );
      }
      await _reconcileTemplateRows(
        userId: userId,
        templateKey: entry.key,
        rows: rows,
        cloud: cloud,
      );
    }

    await _ensureActiveTemplateUniqueIndex();
    final duplicateGroups = await _countActiveDuplicateGroups(userId);
    debugPrint(
      '[Goals] active duplicate groups after reconciliation=$duplicateGroups',
    );
    debugPrint('[Goals] legacy reconciliation completed');
  }

  Future<GoalRow?> _reconcileTemplateRows({
    required String userId,
    required String templateKey,
    required List<GoalRow> rows,
    required _CloudGoal? cloud,
  }) async {
    if (rows.isEmpty) return null;

    final cloudIdentityKeeper = cloud == null
        ? null
        : rows.where((row) => row.supabaseId == cloud.id).firstOrNull;
    final keeper = cloudIdentityKeeper ??
        rows.reduce(
          (best, candidate) =>
              _isBetterKeeper(candidate, best, templateKey) ? candidate : best,
        );

    final pendingRows =
        rows.where((row) => row.syncState == _pendingSyncState).toList();
    final customizedRows =
        rows.where((row) => _customizationScore(row, templateKey) > 0).toList();
    final fieldCandidates = customizedRows.isNotEmpty
        ? customizedRows
        : pendingRows.isNotEmpty
            ? pendingRows
            : <GoalRow>[];
    final fieldDonor = fieldCandidates.isEmpty
        ? keeper
        : fieldCandidates.reduce(
            (best, candidate) => _isBetterKeeper(candidate, best, templateKey)
                ? candidate
                : best,
          );
    final preserveLocalFields = pendingRows.isNotEmpty ||
        _customizationScore(fieldDonor, templateKey) > 0 ||
        cloud == null;

    final desiredTitle = preserveLocalFields ? fieldDonor.title : cloud.title;
    final desiredIconKey =
        preserveLocalFields ? fieldDonor.iconKey : cloud.iconKey;
    final desiredUnit = preserveLocalFields ? fieldDonor.unit : cloud.unit;
    final desiredCustomUnit = preserveLocalFields
        ? fieldDonor.customUnitLabel
        : cloud.customUnitLabel;
    final desiredTarget =
        preserveLocalFields ? fieldDonor.target : cloud.target;
    final desiredFrequency =
        preserveLocalFields ? fieldDonor.frequency : cloud.frequency;

    var winningPeriod = rows.first.periodStart;
    var winningProgress = rows.first.progress;
    for (final row in rows.skip(1)) {
      final comparison = _comparePeriod(row.periodStart, winningPeriod);
      if (comparison > 0) {
        winningPeriod = row.periodStart;
        winningProgress = row.progress;
      } else if (comparison == 0) {
        winningProgress = math.max(winningProgress, row.progress);
      }
    }
    if (cloud != null) {
      final comparison = _comparePeriod(cloud.periodStart, winningPeriod);
      if (comparison > 0) {
        winningPeriod = cloud.periodStart;
        winningProgress = cloud.progress;
      } else if (comparison == 0) {
        winningProgress = math.max(winningProgress, cloud.progress);
      }
    }
    winningProgress = winningProgress.clamp(0, desiredTarget).toInt();

    final desiredRemoteId = cloud?.id ?? keeper.supabaseId;
    final matchesCloud = cloud != null &&
        _valuesMatchCloud(
          cloud: cloud,
          title: desiredTitle,
          iconKey: desiredIconKey,
          unit: desiredUnit,
          customUnitLabel: desiredCustomUnit,
          target: desiredTarget,
          progress: winningProgress,
          frequency: desiredFrequency,
          periodStart: winningPeriod,
        );
    final needsPush = cloud == null || !matchesCloud;
    final now = DateTime.now().toUtc();

    if (cloud != null && keeper.supabaseId != cloud.id) {
      debugPrint(
        '[Goals] adopting cloud id template=$templateKey cloudId=${cloud.id}',
      );
    }

    await _db.transaction(() async {
      await (_db.update(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(keeper.id) & table.userId.equals(userId),
            ))
          .write(
        GoalsCompanion(
          title: Value(desiredTitle),
          iconKey: Value(desiredIconKey),
          templateKey: Value(templateKey),
          unit: Value(desiredUnit),
          customUnitLabel: Value(desiredCustomUnit),
          target: Value(desiredTarget),
          progress: Value(winningProgress),
          frequency: Value(desiredFrequency),
          periodStart: Value(winningPeriod),
          supabaseId: Value(desiredRemoteId),
          status: const Value(_activeGoalStatus),
          syncState: Value(needsPush ? _pendingSyncState : _syncedSyncState),
          changedAt: Value(needsPush ? now : cloud.updatedAt ?? now),
          cloudUpdatedAt: Value(cloud?.updatedAt),
          lastSyncedAt:
              needsPush ? const Value.absent() : Value(DateTime.now().toUtc()),
        ),
      );

      for (final duplicate in rows) {
        if (duplicate.id == keeper.id) continue;
        await (_db.delete(_db.goals)
              ..where(
                (table) =>
                    table.id.equals(duplicate.id) & table.userId.equals(userId),
              ))
            .go();
        debugPrint('[Goals] removed local duplicate id=${duplicate.id}');
      }
    });

    debugPrint(
      '[Goals] merged duplicate template=$templateKey '
      'progress=$winningProgress/$desiredTarget',
    );
    return (_db.select(_db.goals)
          ..where(
            (table) => table.id.equals(keeper.id) & table.userId.equals(userId),
          ))
        .getSingleOrNull();
  }

  bool _isBetterKeeper(
    GoalRow candidate,
    GoalRow current,
    String templateKey,
  ) {
    final periodComparison =
        _comparePeriod(candidate.periodStart, current.periodStart);
    if (periodComparison != 0) return periodComparison > 0;
    if (candidate.progress != current.progress) {
      return candidate.progress > current.progress;
    }

    final candidateCustomization = _customizationScore(candidate, templateKey);
    final currentCustomization = _customizationScore(current, templateKey);
    if (candidateCustomization != currentCustomization) {
      return candidateCustomization > currentCustomization;
    }

    final candidateCloudScore = _cloudLinkScore(candidate);
    final currentCloudScore = _cloudLinkScore(current);
    if (candidateCloudScore != currentCloudScore) {
      return candidateCloudScore > currentCloudScore;
    }
    return candidate.id < current.id;
  }

  int _customizationScore(GoalRow row, String templateKey) {
    final template = goalTemplateByKey(templateKey);
    if (template == null) return 0;

    // The former starter journal was 30 minutes/day. Treat that exact shape
    // as a known legacy default, not as a user customization, while the new
    // catalogue correctly tracks one entry/day.
    if (templateKey == GoalTemplateKeys.journal &&
        row.target == 30 &&
        row.unit == GoalUnit.minutes &&
        row.frequency == GoalFrequency.daily) {
      return 0;
    }
    var score = 0;
    if (row.target != template.defaultTarget) score++;
    if (row.unit != template.unit) score++;
    if (row.frequency != template.frequency) score++;
    return score;
  }

  int _cloudLinkScore(GoalRow row) {
    var score = 0;
    if (row.supabaseId != null) score++;
    if (row.syncState == _syncedSyncState) score++;
    if (row.cloudUpdatedAt != null) score++;
    if (row.lastSyncedAt != null) score++;
    return score;
  }

  int _comparePeriod(DateTime first, DateTime second) {
    final firstDate = DateTime.utc(first.year, first.month, first.day);
    final secondDate = DateTime.utc(second.year, second.month, second.day);
    return firstDate.compareTo(secondDate);
  }

  bool _valuesMatchCloud({
    required _CloudGoal cloud,
    required String title,
    required String iconKey,
    required GoalUnit unit,
    required String? customUnitLabel,
    required int target,
    required int progress,
    required GoalFrequency frequency,
    required DateTime periodStart,
  }) {
    return cloud.title == title &&
        cloud.iconKey == iconKey &&
        cloud.unit == unit &&
        cloud.customUnitLabel == customUnitLabel &&
        cloud.target == target &&
        cloud.progress == progress &&
        cloud.frequency == frequency &&
        _comparePeriod(cloud.periodStart, periodStart) == 0 &&
        cloud.status == _activeGoalStatus;
  }

  Future<int> _countActiveDuplicateGroups(String userId) async {
    final rows = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.status.equals(_activeGoalStatus) &
                table.templateKey.isNotNull(),
          ))
        .get();
    final counts = <String, int>{};
    for (final row in rows) {
      final key = row.templateKey;
      if (key == null) continue;
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts.values.where((count) => count > 1).length;
  }

  Future<void> _ensureActiveTemplateUniqueIndex() async {
    await _db.customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS $_activeTemplateIndexName
      ON goals (user_id, template_key)
      WHERE template_key IS NOT NULL AND status = 'active'
    ''');
  }

  Future<bool> _pushPendingGoals(String userId) async {
    final pendingRows = await (_db.select(_db.goals)
          ..where(
            (table) =>
                table.userId.equals(userId) &
                table.syncState.equals(_pendingSyncState),
          )
          ..orderBy([
            (table) => OrderingTerm.asc(table.changedAt),
            (table) => OrderingTerm.asc(table.id),
          ]))
        .get();
    debugPrint('[Goals] pending count=${pendingRows.length}');

    for (final goal in pendingRows) {
      if (!_isCurrentUser(userId)) return false;
      final remoteId = goal.supabaseId;
      if (remoteId == null) continue;
      final pushedChangedAt = goal.changedAt;

      try {
        final response = await _remote.upsertGoal(_goalPayload(goal, userId));
        if (!_isCurrentUser(userId)) return false;
        await _markPushSucceeded(
          goal: goal,
          userId: userId,
          remoteId: remoteId,
          pushedChangedAt: pushedChangedAt,
          response: response,
        );
        debugPrint('[Goals] push success id=$remoteId');
      } on GoalsActiveTemplateConflict catch (error) {
        final templateKey = goal.templateKey;
        if (templateKey != null && goal.status == _activeGoalStatus) {
          debugPrint(
            '[Goals] template conflict detected template=$templateKey',
          );
          final resolved = await _recoverActiveTemplateConflict(
            userId: userId,
            templateKey: templateKey,
          );
          if (!_isCurrentUser(userId)) return false;
          if (resolved) continue;
        }
        debugPrint('[Goals] push error id=$remoteId error=$error');
      } catch (error) {
        debugPrint('[Goals] push error id=$remoteId error=$error');
      }
    }
    return true;
  }

  Future<void> _markPushSucceeded({
    required GoalRow goal,
    required String userId,
    required String remoteId,
    required DateTime pushedChangedAt,
    required Map<String, dynamic> response,
  }) async {
    final cloudUpdatedAt = _parseDateTime(response['updated_at']);
    await (_db.update(_db.goals)
          ..where(
            (table) =>
                table.id.equals(goal.id) &
                table.userId.equals(userId) &
                table.supabaseId.equals(remoteId) &
                table.syncState.equals(_pendingSyncState) &
                table.changedAt.equals(pushedChangedAt),
          ))
        .write(
      GoalsCompanion(
        syncState: const Value(_syncedSyncState),
        cloudUpdatedAt: Value(cloudUpdatedAt),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<bool> _recoverActiveTemplateConflict({
    required String userId,
    required String templateKey,
  }) async {
    try {
      final raw = await _remote.findActiveGoalByTemplate(
        userId: userId,
        templateKey: templateKey,
      );
      if (!_isCurrentUser(userId) || raw == null) return false;
      if (raw['user_id'] != userId) return false;

      final cloud = _CloudGoal.tryParse(raw);
      if (cloud == null ||
          cloud.templateKey != templateKey ||
          cloud.status != _activeGoalStatus) {
        return false;
      }

      final rows = await (_db.select(_db.goals)
            ..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.status.equals(_activeGoalStatus) &
                  table.templateKey.equals(templateKey),
            ))
          .get();
      if (rows.isEmpty || !_isCurrentUser(userId)) return false;

      final reconciled = await _reconcileTemplateRows(
        userId: userId,
        templateKey: templateKey,
        rows: rows,
        cloud: cloud,
      );
      if (reconciled == null || !_isCurrentUser(userId)) return false;

      if (reconciled.syncState == _pendingSyncState) {
        final changedAt = reconciled.changedAt;
        final response = await _remote.upsertGoal(
          _goalPayload(reconciled, userId),
        );
        if (!_isCurrentUser(userId)) return false;
        await _markPushSucceeded(
          goal: reconciled,
          userId: userId,
          remoteId: cloud.id,
          pushedChangedAt: changedAt,
          response: response,
        );
      }

      debugPrint('[Goals] conflict resolved with cloud id=${cloud.id}');
      return true;
    } catch (error) {
      debugPrint(
        '[Goals] template conflict recovery error '
        'template=$templateKey error=$error',
      );
      return false;
    }
  }

  Future<void> _pullCloudGoals(String userId) async {
    final cloudRows = await _remote.fetchGoals(userId);
    if (!_isCurrentUser(userId)) return;
    debugPrint('[Goals] cloud fetched count=${cloudRows.length}');

    final localRows = await (_db.select(_db.goals)
          ..where((table) => table.userId.equals(userId)))
        .get();
    if (!_isCurrentUser(userId)) return;

    final localByRemoteId = <String, GoalRow>{
      for (final row in localRows)
        if (row.supabaseId != null) row.supabaseId!: row,
    };
    final localActiveByTemplate = <String, GoalRow>{
      for (final row in localRows)
        if (row.status == _activeGoalStatus && row.templateKey != null)
          row.templateKey!: row,
    };
    final cloudIds = <String>{};
    final adoptedLocalIds = <int>{};
    final syncNow = DateTime.now().toUtc();

    for (final raw in cloudRows) {
      final rawId = raw['id'] as String?;
      if (rawId != null && rawId.isNotEmpty) cloudIds.add(rawId);
      if (raw['user_id'] != userId) continue;

      final cloud = _CloudGoal.tryParse(raw);
      if (cloud == null) continue;

      final local = localByRemoteId[cloud.id];
      if (local == null) {
        final templateCandidate =
            cloud.status == _activeGoalStatus && cloud.templateKey != null
                ? localActiveByTemplate[cloud.templateKey!]
                : null;
        if (templateCandidate != null) {
          adoptedLocalIds.add(templateCandidate.id);
          final reconciled = await _reconcileTemplateRows(
            userId: userId,
            templateKey: cloud.templateKey!,
            rows: [templateCandidate],
            cloud: cloud,
          );
          if (reconciled != null && reconciled.syncState == _pendingSyncState) {
            _syncRequestedAgain.add(userId);
          }
          continue;
        }

        await _db.into(_db.goals).insert(
              GoalsCompanion.insert(
                title: cloud.title,
                iconKey: cloud.iconKey,
                unit: cloud.unit,
                customUnitLabel: Value(cloud.customUnitLabel),
                target: cloud.target,
                progress: Value(cloud.progress),
                frequency: cloud.frequency,
                periodStart: cloud.periodStart,
                userId: Value(userId),
                supabaseId: Value(cloud.id),
                templateKey: Value(cloud.templateKey),
                status: Value(cloud.status),
                syncState: const Value(_syncedSyncState),
                changedAt: Value(cloud.updatedAt ?? syncNow),
                cloudUpdatedAt: Value(cloud.updatedAt),
                lastSyncedAt: Value(syncNow),
              ),
            );
        continue;
      }

      if (local.syncState == _pendingSyncState) continue;

      final merge = _mergeProgress(local, cloud);
      if (merge.needsPush) _syncRequestedAgain.add(userId);
      await (_db.update(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(local.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(_syncedSyncState),
            ))
          .write(
        GoalsCompanion(
          title: Value(cloud.title),
          iconKey: Value(cloud.iconKey),
          templateKey: Value(cloud.templateKey),
          unit: Value(cloud.unit),
          customUnitLabel: Value(cloud.customUnitLabel),
          target: Value(cloud.target),
          progress: Value(merge.progress),
          frequency: Value(cloud.frequency),
          periodStart: Value(merge.periodStart),
          status: Value(cloud.status),
          syncState: Value(
            merge.needsPush ? _pendingSyncState : _syncedSyncState,
          ),
          changedAt: Value(
            merge.needsPush ? syncNow : cloud.updatedAt ?? syncNow,
          ),
          cloudUpdatedAt: Value(cloud.updatedAt),
          lastSyncedAt: merge.needsPush ? const Value.absent() : Value(syncNow),
        ),
      );
    }

    for (final local in localRows) {
      final remoteId = local.supabaseId;
      if (remoteId == null || cloudIds.contains(remoteId)) continue;
      if (local.syncState == _pendingSyncState ||
          adoptedLocalIds.contains(local.id)) {
        continue;
      }

      await (_db.delete(_db.goals)
            ..where(
              (table) =>
                  table.id.equals(local.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(_syncedSyncState),
            ))
          .go();
    }
  }

  Map<String, dynamic> _goalPayload(GoalRow goal, String userId) {
    return {
      'id': goal.supabaseId,
      'user_id': userId,
      'title': goal.title,
      'icon_key': goal.iconKey,
      'template_key': goal.templateKey,
      'unit': goal.unit.name,
      'custom_unit_label': goal.customUnitLabel,
      'target': goal.target,
      'progress': goal.progress,
      'frequency': goal.frequency.name,
      'period_start': DateTime.utc(
        goal.periodStart.year,
        goal.periodStart.month,
        goal.periodStart.day,
      ).toIso8601String(),
      'status': goal.status,
    };
  }

  _ProgressMerge _mergeProgress(GoalRow local, _CloudGoal cloud) {
    final localPeriod = DateTime.utc(
      local.periodStart.year,
      local.periodStart.month,
      local.periodStart.day,
    );
    final cloudPeriod = DateTime.utc(
      cloud.periodStart.year,
      cloud.periodStart.month,
      cloud.periodStart.day,
    );
    final safeLocalProgress = math.min(local.progress, cloud.target);

    if (cloudPeriod.isAfter(localPeriod)) {
      return _ProgressMerge(cloud.progress, cloud.periodStart, false);
    }
    if (localPeriod.isAfter(cloudPeriod)) {
      debugPrint(
        '[Goals] progress conflict local period is newer '
        'local=${local.periodStart.toIso8601String()} '
        'cloud=${cloud.periodStart.toIso8601String()}',
      );
      return _ProgressMerge(safeLocalProgress, local.periodStart, true);
    }

    final merged = math.max(safeLocalProgress, cloud.progress);
    if (merged != cloud.progress) {
      debugPrint(
        '[Goals] progress conflict using max '
        'local=$safeLocalProgress cloud=${cloud.progress}',
      );
    }
    return _ProgressMerge(
      merged,
      cloud.periodStart,
      merged != cloud.progress,
    );
  }

  bool _isCurrentUser(String userId) => _currentUserId == userId;

  void _logAuthChanged() {
    debugPrint('[Goals] auth changed, sync aborted');
  }

  /// Compatibility aliases for existing call sites.
  Future<void> syncGoalsWithSupabase() => syncForCurrentUser();
  Future<void> fetchAndSyncFromSupabase() => syncForCurrentUser();

  Future<GoalStreak> loadStreak() async {
    final userId = _currentUserId;
    if (userId == null) return const GoalStreak();
    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId != userId) return const GoalStreak();
    return _correctedStreak(prefs, userId);
  }

  Future<GoalStreak> recordActivityToday() async {
    final userId = _currentUserId;
    if (userId == null) return const GoalStreak();
    return _recordActivityTodayForUser(userId);
  }

  Future<GoalStreak> _recordActivityTodayForUser(String userId) async {
    if (!_isCurrentUser(userId)) return const GoalStreak();
    final prefs = await SharedPreferences.getInstance();
    if (!_isCurrentUser(userId)) return const GoalStreak();

    final corrected = await _correctedStreak(prefs, userId);
    final today = _dateOnly(_clock());
    final lastActive = corrected.lastActiveDate;
    if (lastActive != null && _isSameDate(lastActive, today)) {
      return corrected;
    }

    final gapDays =
        lastActive == null ? null : today.difference(lastActive).inDays;
    final newCount = gapDays == 1 ? corrected.count + 1 : 1;
    if (!_isCurrentUser(userId)) return const GoalStreak();
    await prefs.setInt(_streakCountKey(userId), newCount);
    await prefs.setString(
      _streakLastActiveKey(userId),
      today.toIso8601String(),
    );
    return GoalStreak(count: newCount, lastActiveDate: today);
  }

  Future<GoalStreak> _correctedStreak(
    SharedPreferences prefs,
    String userId,
  ) async {
    final count = prefs.getInt(_streakCountKey(userId)) ?? 0;
    final lastActiveRaw = prefs.getString(_streakLastActiveKey(userId));
    if (lastActiveRaw == null || count == 0) {
      return GoalStreak(
        count: 0,
        lastActiveDate:
            lastActiveRaw == null ? null : DateTime.parse(lastActiveRaw),
      );
    }

    final lastActiveDate = DateTime.parse(lastActiveRaw);
    final today = _dateOnly(_clock());
    final gapDays = today.difference(lastActiveDate).inDays;
    if (gapDays <= 1) {
      return GoalStreak(count: count, lastActiveDate: lastActiveDate);
    }

    if (_isCurrentUser(userId)) {
      await prefs.setInt(_streakCountKey(userId), 0);
    }
    return GoalStreak(count: 0, lastActiveDate: lastActiveDate);
  }

  /// Calendar period anchor in the device's local timezone. Supabase payload
  /// normalization preserves this calendar date when serializing to UTC.
  static DateTime expectedPeriodStart(
    GoalFrequency frequency,
    DateTime now,
  ) {
    final today = _dateOnly(now);
    switch (frequency) {
      case GoalFrequency.daily:
        return today;
      case GoalFrequency.weekly:
        return today.subtract(Duration(days: today.weekday - 1));
      case GoalFrequency.monthly:
        return DateTime(today.year, today.month);
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _GoalIncrementResult {
  const _GoalIncrementResult({
    this.didAdvance = false,
    this.justCompleted = false,
    this.remoteId,
    this.progress = 0,
    this.target = 0,
  });

  final bool didAdvance;
  final bool justCompleted;
  final String? remoteId;
  final int progress;
  final int target;
}

class _CloudGoal {
  const _CloudGoal({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.templateKey,
    required this.unit,
    required this.customUnitLabel,
    required this.target,
    required this.progress,
    required this.frequency,
    required this.periodStart,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String iconKey;
  final String? templateKey;
  final GoalUnit unit;
  final String? customUnitLabel;
  final int target;
  final int progress;
  final GoalFrequency frequency;
  final DateTime periodStart;
  final String status;
  final DateTime? updatedAt;

  static _CloudGoal? tryParse(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final title = row['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.trim().isEmpty) {
      return null;
    }

    final unitName = row['unit'] as String?;
    final frequencyName = row['frequency'] as String?;
    final target = (row['target'] as num?)?.toInt() ?? 1;
    final rawProgress = (row['progress'] as num?)?.toInt() ?? 0;
    final safeTarget = math.max(1, target);
    final status = row['status'] == _archivedGoalStatus
        ? _archivedGoalStatus
        : _activeGoalStatus;

    return _CloudGoal(
      id: id,
      title: title,
      iconKey: row['icon_key'] as String? ?? customGoalIconKey,
      templateKey: row['template_key'] as String?,
      unit: GoalUnit.values.firstWhere(
        (value) => value.name == unitName,
        orElse: () => GoalUnit.custom,
      ),
      customUnitLabel: row['custom_unit_label'] as String?,
      target: safeTarget,
      progress: rawProgress.clamp(0, safeTarget).toInt(),
      frequency: GoalFrequency.values.firstWhere(
        (value) => value.name == frequencyName,
        orElse: () => GoalFrequency.daily,
      ),
      periodStart: _parseDateTime(row['period_start']) ?? DateTime.now(),
      status: status,
      updatedAt: _parseDateTime(row['updated_at']),
    );
  }
}

class _ProgressMerge {
  const _ProgressMerge(this.progress, this.periodStart, this.needsPush);

  final int progress;
  final DateTime periodStart;
  final bool needsPush;
}

DateTime? _parseDateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}

String _newUuidV4() {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
