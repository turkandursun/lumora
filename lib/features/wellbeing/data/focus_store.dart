import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent focus stats: how many sessions were completed today, the user's
/// daily goal, and a "don't break the chain" streak (consecutive days with at
/// least one completed session). This is the stickiness engine behind
/// Forest / Focus To-Do.
class FocusStats {
  const FocusStats({
    required this.completedToday,
    required this.goal,
    required this.streak,
  });

  final int completedToday;
  final int goal;
  final int streak;

  FocusStats copyWith({int? completedToday, int? goal, int? streak}) =>
      FocusStats(
        completedToday: completedToday ?? this.completedToday,
        goal: goal ?? this.goal,
        streak: streak ?? this.streak,
      );

  static const empty = FocusStats(completedToday: 0, goal: 5, streak: 0);
}

class FocusStore {
  static const _kDate = 'focus_last_date';
  static const _kCount = 'focus_count_today';
  static const _kGoal = 'focus_goal';
  static const _kStreak = 'focus_streak';
  static const _kStreakDate = 'focus_streak_date';

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<FocusStats> load() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));

    var count = p.getInt(_kCount) ?? 0;
    if (p.getString(_kDate) != today) count = 0; // a fresh day resets the count

    var streak = p.getInt(_kStreak) ?? 0;
    final streakDate = p.getString(_kStreakDate);
    // The chain is intact only if it was last advanced today or yesterday.
    if (streakDate != today && streakDate != yesterday) streak = 0;

    return FocusStats(
      completedToday: count,
      goal: p.getInt(_kGoal) ?? 5,
      streak: streak,
    );
  }

  Future<FocusStats> recordSession() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));

    var count = p.getInt(_kCount) ?? 0;
    if (p.getString(_kDate) != today) count = 0;
    count++;
    await p.setInt(_kCount, count);
    await p.setString(_kDate, today);

    // Advance the streak once per day, on the day's first session.
    var streak = p.getInt(_kStreak) ?? 0;
    final streakDate = p.getString(_kStreakDate);
    if (streakDate != today) {
      streak = (streakDate == yesterday) ? streak + 1 : 1;
      await p.setInt(_kStreak, streak);
      await p.setString(_kStreakDate, today);
    }

    return FocusStats(
      completedToday: count,
      goal: p.getInt(_kGoal) ?? 5,
      streak: streak,
    );
  }

  Future<FocusStats> setGoal(int goal) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGoal, goal.clamp(1, 12));
    return load();
  }
}

class FocusStatsNotifier extends StateNotifier<FocusStats> {
  FocusStatsNotifier(this._store) : super(FocusStats.empty) {
    _load();
  }

  final FocusStore _store;

  Future<void> _load() async => state = await _store.load();
  Future<void> recordSession() async => state = await _store.recordSession();
  Future<void> setGoal(int goal) async => state = await _store.setGoal(goal);
}

final focusStoreProvider = Provider((ref) => FocusStore());

final focusStatsProvider =
    StateNotifierProvider<FocusStatsNotifier, FocusStats>(
        (ref) => FocusStatsNotifier(ref.watch(focusStoreProvider)));
