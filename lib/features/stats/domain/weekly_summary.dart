import '../../../theme/mood_gradients.dart';

/// A personal "this week" snapshot computed from the last 7 days of mood logs
/// and journal entries. Pure data — no Flutter, no I/O — so it's easy to test.
class WeeklySummary {
  const WeeklySummary({
    required this.daysJournaled,
    required this.entriesThisWeek,
    required this.moodDays,
    required this.moodCounts,
    required this.topMood,
    required this.lowestDayWeekday,
    required this.streak,
  });

  /// Distinct days (0–7) in the window that have at least one journal entry.
  final int daysJournaled;

  /// Total journal entries written in the window.
  final int entriesThisWeek;

  /// Distinct days (0–7) that have a logged mood.
  final int moodDays;

  /// How many times each mood was logged in the window.
  final Map<AppMood, int> moodCounts;

  /// The most frequently logged mood this week (null if none logged).
  final AppMood? topMood;

  /// Weekday (1=Mon..7=Sun) of the lowest-wellbeing day, or null if no moods.
  final int? lowestDayWeekday;

  /// Current journal streak (consecutive days).
  final int streak;

  bool get isEmpty => daysJournaled == 0 && moodDays == 0;

  /// Higher = better wellbeing. Used only to find the "hardest" day.
  static const Map<AppMood, int> _wellbeing = {
    AppMood.happy: 5,
    AppMood.calm: 4,
    AppMood.tired: 3,
    AppMood.anxious: 2,
    AppMood.sad: 1,
  };

  /// Builds the summary for the 7-day window ending on [now] (inclusive).
  ///
  /// [moodLog] maps a date to an [AppMood] index. [entryDates] is every journal
  /// entry's timestamp. [streak] is the current journal streak.
  factory WeeklySummary.compute({
    required Map<DateTime, int> moodLog,
    required List<DateTime> entryDates,
    required int streak,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final start = today.subtract(const Duration(days: 6)); // 7-day window

    bool inWindow(DateTime d) {
      final day = _dateOnly(d);
      return !day.isBefore(start) && !day.isAfter(today);
    }

    // Journal days + count.
    final journalDays = <DateTime>{};
    var entries = 0;
    for (final d in entryDates) {
      if (inWindow(d)) {
        entries++;
        journalDays.add(_dateOnly(d));
      }
    }

    // Moods.
    final counts = <AppMood, int>{};
    final moodDaySet = <DateTime>{};
    int? lowestWeekday;
    var lowestScore = 1 << 20;
    moodLog.forEach((day, index) {
      if (!inWindow(day)) return;
      if (index < 0 || index >= AppMood.values.length) return;
      final mood = AppMood.values[index];
      counts[mood] = (counts[mood] ?? 0) + 1;
      moodDaySet.add(_dateOnly(day));
      final score = _wellbeing[mood] ?? 3;
      if (score < lowestScore) {
        lowestScore = score;
        lowestWeekday = _dateOnly(day).weekday;
      }
    });

    AppMood? top;
    var topCount = 0;
    counts.forEach((mood, c) {
      if (c > topCount) {
        topCount = c;
        top = mood;
      }
    });

    return WeeklySummary(
      daysJournaled: journalDays.length,
      entriesThisWeek: entries,
      moodDays: moodDaySet.length,
      moodCounts: counts,
      topMood: top,
      lowestDayWeekday: lowestWeekday,
      streak: streak,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
