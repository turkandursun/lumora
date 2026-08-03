import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/goals_table.dart';

/// Localized title for one of the four seeded starter goals, resolved by
/// the presentation layer (which has an `AppLocalizations` instance) and
/// handed down here — this repository never touches localization directly.
class GoalCopy {
  const GoalCopy({required this.title});

  final String title;
}

/// Icon keys for the four seeded starter goals.
class DefaultGoalIconKeys {
  DefaultGoalIconKeys._();

  static const water = 'water';
  static const journal = 'journal';
  static const meditation = 'meditation';
  static const reading = 'reading';
  static const breathing = 'breathing';
}

/// Icon key used for goals the user creates themselves via the "New Goal"
/// sheet.
const customGoalIconKey = 'custom';

/// The user's current goal-tracking streak: how many consecutive days they
/// made progress on at least one goal (the simpler of the two streak
/// definitions the design allowed for — "made progress" rather than
/// "completed every daily goal" — since it needs no cross-goal
/// bookkeeping and stays correct even as goals are added or removed).
class GoalStreak {
  const GoalStreak({this.count = 0, this.lastActiveDate});

  final int count;
  final DateTime? lastActiveDate;
}

/// Owns goal persistence (via [AppDatabase]) and the small streak record
/// that lives alongside it in [SharedPreferences].
class GoalsRepository {
  GoalsRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  String get _currentUserId => _client.auth.currentUser?.id ?? 'guest';

  String get _seededPrefKey => 'goals_seeded_$_currentUserId';
  String get _streakCountKey => 'goals_streak_count_$_currentUserId';
  String get _streakLastActiveKey => 'goals_streak_last_active_date_$_currentUserId';

  /// Only returns goals belonging to the currently logged in user.
  Stream<List<GoalRow>> watchAll() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(const []);
    return (_db.select(_db.goals)..where((t) => t.userId.equals(user.id))).watch();
  }

  /// Inserts the four starter goals exactly once per user (tracked via a
  /// [SharedPreferences] flag).
  Future<void> ensureSeeded(Map<String, GoalCopy> defaultCopy) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededPrefKey) ?? false) return;

    final userId = _client.auth.currentUser?.id;
    final now = DateTime.now();
    await _db.batch((batch) {
      batch.insertAll(_db.goals, [
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.water]!.title,
          iconKey: DefaultGoalIconKeys.water,
          unit: GoalUnit.glasses,
          target: 8,
          frequency: GoalFrequency.daily,
          periodStart: _periodStartFor(GoalFrequency.daily, now),
          userId: Value(userId),
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.journal]!.title,
          iconKey: DefaultGoalIconKeys.journal,
          unit: GoalUnit.minutes,
          target: 30,
          frequency: GoalFrequency.daily,
          periodStart: _periodStartFor(GoalFrequency.daily, now),
          userId: Value(userId),
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.meditation]!.title,
          iconKey: DefaultGoalIconKeys.meditation,
          unit: GoalUnit.minutes,
          target: 15,
          frequency: GoalFrequency.daily,
          periodStart: _periodStartFor(GoalFrequency.daily, now),
          userId: Value(userId),
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.breathing]!.title,
          iconKey: DefaultGoalIconKeys.breathing,
          unit: GoalUnit.minutes,
          target: 10,
          frequency: GoalFrequency.daily,
          periodStart: _periodStartFor(GoalFrequency.daily, now),
          userId: Value(userId),
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.reading]!.title,
          iconKey: DefaultGoalIconKeys.reading,
          unit: GoalUnit.books,
          target: 4,
          frequency: GoalFrequency.monthly,
          periodStart: _periodStartFor(GoalFrequency.monthly, now),
          userId: Value(userId),
        ),
      ]);
    });
    await prefs.setBool(_seededPrefKey, true);
  }

  Future<void> addCustomGoal({
    required String title,
    required GoalUnit unit,
    String? customUnitLabel,
    required int target,
    required GoalFrequency frequency,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    String? cloudId;
    if (user != null) {
      try {
        final insertedRow = await _client.from('goals').insert({
          'user_id': user.id,
          'title': title,
          'icon_key': customGoalIconKey,
          'unit': unit.name,
          'custom_unit_label': customUnitLabel,
          'target': target,
          'progress': 0,
          'frequency': frequency.name,
          'period_start': _periodStartFor(frequency, now).toIso8601String(),
        }).select('id').single();
        cloudId = insertedRow['id'] as String?;
        debugPrint('[GoalsSync] Successfully inserted goal to Supabase, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[GoalsSync] Error inserting goal into Supabase: $e');
      }
    }

    await _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            title: title,
            iconKey: customGoalIconKey,
            unit: unit,
            customUnitLabel: Value(customUnitLabel),
            target: target,
            frequency: frequency,
            periodStart: _periodStartFor(frequency, now),
            userId: Value(user?.id),
            supabaseId: Value(cloudId),
          ),
        );
  }

  /// Zeroes [GoalRow.progress] (and moves [GoalRow.periodStart] forward)
  /// for any goal whose tracked period no longer matches the period its
  /// [GoalRow.frequency] implies for "now".
  Future<void> resetElapsedPeriods() async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();
    final goals = await (_db.select(_db.goals)
          ..where((t) => user != null ? t.userId.equals(user.id) : t.userId.isNull()))
        .get();
    for (final goal in goals) {
      final expected = _periodStartFor(goal.frequency, now);
      if (!_isSameDate(goal.periodStart, expected)) {
        await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id))).write(
          GoalsCompanion(progress: const Value(0), periodStart: Value(expected)),
        );
        if (user != null && goal.supabaseId != null) {
          try {
            await _client.from('goals').update({
              'progress': 0,
              'period_start': expected.toIso8601String(),
            }).eq('id', goal.supabaseId!).eq('user_id', user.id);
          } catch (e) {
            debugPrint('[GoalsSync] Error updating period reset in Supabase: $e');
          }
        }
      }
    }
  }

  /// Adds [amount] to [goal]'s progress (clamped to its target), records
  /// today as a qualifying streak day, and reports whether this increment
  /// completed the goal.
  Future<bool> incrementProgress(GoalRow goal, int amount) async {
    final newProgress = (goal.progress + amount).clamp(0, goal.target);
    await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id)))
        .write(GoalsCompanion(progress: Value(newProgress)));
    await recordActivityToday();

    final user = _client.auth.currentUser;
    if (user != null && goal.supabaseId != null) {
      try {
        await _client.from('goals').update({
          'progress': newProgress,
        }).eq('id', goal.supabaseId!).eq('user_id', user.id);
      } catch (e) {
        debugPrint('[GoalsSync] Error updating progress in Supabase: $e');
      }
    }
    return goal.progress < goal.target && newProgress >= goal.target;
  }

  /// Auto-advances any goal whose [iconKey] matches a completed activity
  /// (journal / meditation / breathing) by [amount], so tracked goals fill
  /// in on their own as the user actually does the activity.
  Future<void> incrementByIconKey(String iconKey, int amount) async {
    if (amount <= 0) return;
    final uid = _client.auth.currentUser?.id;
    final rows = await (_db.select(_db.goals)
          ..where((t) => t.iconKey.equals(iconKey)))
        .get();
    for (final goal in rows) {
      if (uid != null && goal.userId != uid) continue;
      if (goal.progress >= goal.target) continue;
      await incrementProgress(goal, amount);
    }
  }

  /// Deletes all local goals from Drift SQLite (e.g. upon user logout).
  Future<void> deleteAll() async {
    await _db.delete(_db.goals).go();
  }

  /// Fetches the user's goals from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> syncGoalsWithSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('goals')
          .select()
          .eq('user_id', user.id);

      final cloudRows = response as List;
      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id'] as String?;
        if (id != null) {
          cloudMap[id] = row as Map<String, dynamic>;
        }
      }

      final localEntries = await (_db.select(_db.goals)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, GoalRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.goals)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[GoalsSync] Deleted local goal with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally
      for (final cloudId in cloudMap.keys) {
        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final row = cloudMap[cloudId]!;
          final title = row['title'] as String?;
          final iconKey = row['icon_key'] as String? ?? 'custom';
          final unitStr = row['unit'] as String?;
          final customUnitLabel = row['custom_unit_label'] as String?;
          final target = (row['target'] as num?)?.toInt() ?? 1;
          final progress = (row['progress'] as num?)?.toInt() ?? 0;
          final freqStr = row['frequency'] as String?;
          final periodStartStr = row['period_start'] as String?;

          if (title == null || title.isEmpty) continue;

          final unit = GoalUnit.values.firstWhere(
            (e) => e.name == unitStr,
            orElse: () => GoalUnit.custom,
          );
          final frequency = GoalFrequency.values.firstWhere(
            (e) => e.name == freqStr,
            orElse: () => GoalFrequency.daily,
          );
          final periodStart = periodStartStr != null
              ? DateTime.tryParse(periodStartStr) ?? DateTime.now()
              : DateTime.now();

          await _db.into(_db.goals).insert(
                GoalsCompanion.insert(
                  title: title,
                  iconKey: iconKey,
                  unit: unit,
                  customUnitLabel: Value(customUnitLabel),
                  target: target,
                  progress: Value(progress),
                  frequency: frequency,
                  periodStart: periodStart,
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );
          debugPrint('[GoalsSync] Inserted cloud goal locally, cloudId=$cloudId');
        }
      }
    } catch (e) {
      debugPrint('[GoalsSync] Error fetching from Supabase: $e');
    }
  }

  /// Alias for [syncGoalsWithSupabase] to match the journal repository naming.
  Future<void> fetchAndSyncFromSupabase() => syncGoalsWithSupabase();

  /// The current streak, correcting it to zero first if more than a day
  /// has passed since [GoalStreak.lastActiveDate] (i.e. a day was missed).
  Future<GoalStreak> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return _correctedStreak(prefs);
  }

  /// Marks today as a qualifying streak day: extends the streak if
  /// yesterday was the last qualifying day, starts a new streak of 1
  /// otherwise, or leaves it untouched if today was already recorded.
  Future<GoalStreak> recordActivityToday() async {
    final prefs = await SharedPreferences.getInstance();
    final corrected = await _correctedStreak(prefs);
    final today = _dateOnly(DateTime.now());

    final lastActive = corrected.lastActiveDate;
    if (lastActive != null && _isSameDate(lastActive, today)) {
      return corrected;
    }

    final gapDays = lastActive == null ? null : today.difference(lastActive).inDays;
    final newCount = gapDays == 1 ? corrected.count + 1 : 1;
    await prefs.setInt(_streakCountKey, newCount);
    await prefs.setString(_streakLastActiveKey, today.toIso8601String());
    return GoalStreak(count: newCount, lastActiveDate: today);
  }

  Future<GoalStreak> _correctedStreak(SharedPreferences prefs) async {
    final count = prefs.getInt(_streakCountKey) ?? 0;
    final lastActiveRaw = prefs.getString(_streakLastActiveKey);
    if (lastActiveRaw == null || count == 0) {
      return GoalStreak(count: 0, lastActiveDate: lastActiveRaw == null ? null : DateTime.parse(lastActiveRaw));
    }

    final lastActiveDate = DateTime.parse(lastActiveRaw);
    final today = _dateOnly(DateTime.now());
    final gapDays = today.difference(lastActiveDate).inDays;
    if (gapDays <= 1) {
      return GoalStreak(count: count, lastActiveDate: lastActiveDate);
    }

    // More than a day has passed since the last qualifying day — the
    // streak is broken; persist the correction so it stays accurate even
    // if the user doesn't act again today.
    await prefs.setInt(_streakCountKey, 0);
    return GoalStreak(count: 0, lastActiveDate: lastActiveDate);
  }

  DateTime _periodStartFor(GoalFrequency frequency, DateTime now) {
    final today = _dateOnly(now);
    switch (frequency) {
      case GoalFrequency.daily:
        return today;
      case GoalFrequency.weekly:
        return today.subtract(Duration(days: today.weekday - 1));
      case GoalFrequency.monthly:
        return DateTime(today.year, today.month, 1);
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
