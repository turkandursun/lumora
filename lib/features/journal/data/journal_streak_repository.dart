import 'package:shared_preferences/shared_preferences.dart';

const _streakCountKey = 'journal_streak_count';
const _streakLastEntryDateKey = 'journal_streak_last_entry_date';

/// The user's current journaling streak: how many consecutive days they've
/// saved at least one journal entry. Kept as its own counter, separate from
/// [GoalStreak] in the goals feature — mirrors that streak's "missed a day
/// resets to zero" pattern, but the two are independent since journaling and
/// goal progress are different activities.
class JournalStreak {
  const JournalStreak({this.count = 0, this.lastEntryDate});

  final int count;
  final DateTime? lastEntryDate;
}

/// Owns the small journaling-streak record kept in [SharedPreferences].
/// This only tracks the streak of days on which an entry was saved — the
/// entries themselves live in [JournalEntries] via `JournalEntriesRepository`.
class JournalStreakRepository {
  /// The current streak, correcting it to zero first if more than a day has
  /// passed since [JournalStreak.lastEntryDate] (i.e. a day was missed).
  Future<JournalStreak> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return _correctedStreak(prefs);
  }

  /// Marks today as a day a journal entry was saved: extends the streak if
  /// yesterday was the last qualifying day, starts a new streak of 1
  /// otherwise, or leaves it untouched if today was already recorded.
  /// Returns the resulting streak alongside whether the count just
  /// increased, so the caller can decide whether a celebration is warranted.
  Future<(JournalStreak, bool)> recordEntrySaved() async {
    final prefs = await SharedPreferences.getInstance();
    final corrected = await _correctedStreak(prefs);
    final today = _dateOnly(DateTime.now());

    final lastEntry = corrected.lastEntryDate;
    if (lastEntry != null && _isSameDate(lastEntry, today)) {
      return (corrected, false);
    }

    final gapDays = lastEntry == null ? null : today.difference(lastEntry).inDays;
    final newCount = gapDays == 1 ? corrected.count + 1 : 1;
    await prefs.setInt(_streakCountKey, newCount);
    await prefs.setString(_streakLastEntryDateKey, today.toIso8601String());
    return (JournalStreak(count: newCount, lastEntryDate: today), true);
  }

  Future<JournalStreak> _correctedStreak(SharedPreferences prefs) async {
    final count = prefs.getInt(_streakCountKey) ?? 0;
    final lastEntryRaw = prefs.getString(_streakLastEntryDateKey);
    if (lastEntryRaw == null || count == 0) {
      return JournalStreak(
        count: 0,
        lastEntryDate: lastEntryRaw == null ? null : DateTime.parse(lastEntryRaw),
      );
    }

    final lastEntryDate = DateTime.parse(lastEntryRaw);
    final today = _dateOnly(DateTime.now());
    final gapDays = today.difference(lastEntryDate).inDays;
    if (gapDays <= 1) {
      return JournalStreak(count: count, lastEntryDate: lastEntryDate);
    }

    // More than a day has passed since the last saved entry — the streak is
    // broken; persist the correction so it stays accurate even if the user
    // doesn't write again today.
    await prefs.setInt(_streakCountKey, 0);
    return JournalStreak(count: 0, lastEntryDate: lastEntryDate);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
