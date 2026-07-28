import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

/// Icon key used for goals the user creates themselves via the "New Goal"
/// sheet.
const customGoalIconKey = 'custom';

const _seededPrefKey = 'goals_seeded';
const _streakCountKey = 'goals_streak_count';
const _streakLastActiveKey = 'goals_streak_last_active_date';

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
  GoalsRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Stream<List<GoalRow>> watchAll() => _db.select(_db.goals).watch();

  /// Inserts the four starter goals exactly once, ever (tracked via a
  /// [SharedPreferences] flag, so manually deleting them all later doesn't
  /// bring them back).
  ///
  /// [defaultCopy] must have an entry for each key in
  /// [DefaultGoalIconKeys].
  Future<void> ensureSeeded(Map<String, GoalCopy> defaultCopy) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededPrefKey) ?? false) return;

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
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.journal]!.title,
          iconKey: DefaultGoalIconKeys.journal,
          unit: GoalUnit.minutes,
          target: 30,
          frequency: GoalFrequency.daily,
          periodStart: _periodStartFor(GoalFrequency.daily, now),
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.meditation]!.title,
          iconKey: DefaultGoalIconKeys.meditation,
          unit: GoalUnit.minutes,
          target: 15,
          frequency: GoalFrequency.daily,
          periodStart: _periodStartFor(GoalFrequency.daily, now),
        ),
        GoalsCompanion.insert(
          title: defaultCopy[DefaultGoalIconKeys.reading]!.title,
          iconKey: DefaultGoalIconKeys.reading,
          unit: GoalUnit.books,
          target: 4,
          frequency: GoalFrequency.monthly,
          periodStart: _periodStartFor(GoalFrequency.monthly, now),
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
    final now = DateTime.now();
    await _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            title: title,
            iconKey: customGoalIconKey,
            unit: unit,
            customUnitLabel: Value(customUnitLabel),
            target: target,
            frequency: frequency,
            periodStart: _periodStartFor(frequency, now),
          ),
        );
  }

  /// Zeroes [GoalRow.progress] (and moves [GoalRow.periodStart] forward)
  /// for any goal whose tracked period no longer matches the period its
  /// [GoalRow.frequency] implies for "now" — e.g. a daily goal whose
  /// [GoalRow.periodStart] was yesterday. Meant to be called once per
  /// screen load, since there's no background scheduler to run it on a
  /// timer.
  Future<void> resetElapsedPeriods() async {
    final now = DateTime.now();
    final goals = await _db.select(_db.goals).get();
    for (final goal in goals) {
      final expected = _periodStartFor(goal.frequency, now);
      if (!_isSameDate(goal.periodStart, expected)) {
        await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id))).write(
          GoalsCompanion(progress: const Value(0), periodStart: Value(expected)),
        );
      }
    }
  }

  /// Adds [amount] to [goal]'s progress (clamped to its target), records
  /// today as a qualifying streak day, and reports whether this increment
  /// is the one that just completed the goal for its current period (so
  /// the UI can show a one-time celebration rather than one every tap).
  Future<bool> incrementProgress(GoalRow goal, int amount) async {
    final newProgress = (goal.progress + amount).clamp(0, goal.target);
    await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id)))
        .write(GoalsCompanion(progress: Value(newProgress)));
    await recordActivityToday();
    return goal.progress < goal.target && newProgress >= goal.target;
  }

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
