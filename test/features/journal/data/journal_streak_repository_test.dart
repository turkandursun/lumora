import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/journal/data/journal_streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late JournalStreakRepository repository;

  setUp(() {
    repository = JournalStreakRepository();
  });

  DateTime daysAgo(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  }

  test('first ever save starts a streak of 1', () async {
    SharedPreferences.setMockInitialValues({});

    final (streak, increased) = await repository.recordEntrySaved();

    expect(streak.count, 1);
    expect(increased, isTrue);
  });

  test('saving again the same day leaves the streak untouched', () async {
    SharedPreferences.setMockInitialValues({
      'journal_streak_count': 5,
      'journal_streak_last_entry_date': daysAgo(0).toIso8601String(),
    });

    final (streak, increased) = await repository.recordEntrySaved();

    expect(streak.count, 5);
    expect(increased, isFalse);
  });

  test('saving the day after the last entry extends the streak', () async {
    SharedPreferences.setMockInitialValues({
      'journal_streak_count': 5,
      'journal_streak_last_entry_date': daysAgo(1).toIso8601String(),
    });

    final (streak, increased) = await repository.recordEntrySaved();

    expect(streak.count, 6);
    expect(increased, isTrue);
  });

  test('missing a day resets the streak to zero on load', () async {
    SharedPreferences.setMockInitialValues({
      'journal_streak_count': 5,
      'journal_streak_last_entry_date': daysAgo(3).toIso8601String(),
    });

    final streak = await repository.loadStreak();

    expect(streak.count, 0);
  });

  test('saving after a missed day starts a fresh streak of 1', () async {
    SharedPreferences.setMockInitialValues({
      'journal_streak_count': 5,
      'journal_streak_last_entry_date': daysAgo(3).toIso8601String(),
    });

    final (streak, increased) = await repository.recordEntrySaved();

    expect(streak.count, 1);
    expect(increased, isTrue);
  });
}
