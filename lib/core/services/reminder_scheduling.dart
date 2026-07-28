import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/tables/reminders_table.dart';

/// When a reminder should next fire, and how flutter_local_notifications
/// should repeat it (`null` for a one-time reminder).
class ReminderSchedule {
  const ReminderSchedule({required this.dateTime, required this.matchDateTimeComponents});

  final tz.TZDateTime dateTime;
  final DateTimeComponents? matchDateTimeComponents;
}

/// Pure scheduling math for [NotificationService] — kept separate (and free
/// of the plugin singleton) so it's directly unit-testable against a fixed
/// [now] rather than the real clock.
ReminderSchedule computeNextSchedule({
  required ReminderFrequency frequency,
  int? weekday,
  required int hour,
  required int minute,
  required tz.TZDateTime now,
}) {
  tz.TZDateTime nextDailyOccurrence() {
    var scheduled = tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  final scheduledDate = frequency == ReminderFrequency.weekly
      ? _nextInstanceOfWeekday(nextDailyOccurrence(), weekday!)
      : nextDailyOccurrence();

  final matchDateTimeComponents = switch (frequency) {
    ReminderFrequency.daily => DateTimeComponents.time,
    ReminderFrequency.weekly => DateTimeComponents.dayOfWeekAndTime,
    ReminderFrequency.once => null,
  };

  return ReminderSchedule(dateTime: scheduledDate, matchDateTimeComponents: matchDateTimeComponents);
}

tz.TZDateTime _nextInstanceOfWeekday(tz.TZDateTime from, int weekday) {
  var scheduled = from;
  while (scheduled.weekday != weekday) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}
