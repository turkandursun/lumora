import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/tables/reminders_table.dart';
import 'package:mindful_journal/core/services/reminder_scheduling.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  // A fixed reference "now": Wednesday, 2024-01-10, 10:00.
  final now = tz.TZDateTime(tz.UTC, 2024, 1, 10, 10, 0);

  test('daily reminder later today fires today, and repeats daily', () {
    final schedule = computeNextSchedule(
      frequency: ReminderFrequency.daily,
      hour: 18,
      minute: 0,
      now: now,
    );

    expect(schedule.dateTime, tz.TZDateTime(tz.UTC, 2024, 1, 10, 18, 0));
    expect(schedule.matchDateTimeComponents, DateTimeComponents.time);
  });

  test('daily reminder earlier today rolls over to tomorrow', () {
    final schedule = computeNextSchedule(
      frequency: ReminderFrequency.daily,
      hour: 8,
      minute: 0,
      now: now,
    );

    expect(schedule.dateTime, tz.TZDateTime(tz.UTC, 2024, 1, 11, 8, 0));
  });

  test('weekly reminder resolves to the next occurrence of that weekday', () {
    // now is Wednesday; Sunday is 4 days later.
    final schedule = computeNextSchedule(
      frequency: ReminderFrequency.weekly,
      weekday: DateTime.sunday,
      hour: 18,
      minute: 0,
      now: now,
    );

    expect(schedule.dateTime, tz.TZDateTime(tz.UTC, 2024, 1, 14, 18, 0));
    expect(schedule.dateTime.weekday, DateTime.sunday);
    expect(schedule.matchDateTimeComponents, DateTimeComponents.dayOfWeekAndTime);
  });

  test('weekly reminder on today\'s weekday, still ahead, fires today', () {
    // now is Wednesday 10:00; a Wednesday-18:00 reminder should fire today.
    final schedule = computeNextSchedule(
      frequency: ReminderFrequency.weekly,
      weekday: DateTime.wednesday,
      hour: 18,
      minute: 0,
      now: now,
    );

    expect(schedule.dateTime, tz.TZDateTime(tz.UTC, 2024, 1, 10, 18, 0));
  });

  test('weekly reminder on today\'s weekday, already passed, rolls a full week', () {
    // now is Wednesday 10:00; a Wednesday-08:00 reminder has already passed
    // today, so the next one is next Wednesday, not tomorrow.
    final schedule = computeNextSchedule(
      frequency: ReminderFrequency.weekly,
      weekday: DateTime.wednesday,
      hour: 8,
      minute: 0,
      now: now,
    );

    expect(schedule.dateTime, tz.TZDateTime(tz.UTC, 2024, 1, 17, 8, 0));
  });

  test('one-time reminder has no repeat components', () {
    final schedule = computeNextSchedule(
      frequency: ReminderFrequency.once,
      hour: 20,
      minute: 0,
      now: now,
    );

    expect(schedule.dateTime, tz.TZDateTime(tz.UTC, 2024, 1, 10, 20, 0));
    expect(schedule.matchDateTimeComponents, isNull);
  });
}
