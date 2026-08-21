import 'package:flutter/foundation.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/reminder_notification_ids.dart';

/// An account-owned calendar date shown in Profile and Calendar.
@immutable
class SpecialDay {
  const SpecialDay({
    required this.id,
    required this.title,
    required this.month,
    required this.day,
    this.year,
    this.kind = kindCustom,
    this.repeatsAnnually = true,
  });

  static const kindBirthday = 'birthday';
  static const kindWedding = 'wedding';
  static const kindAnniversary = 'anniversary';
  static const kindCustom = 'custom';
  static const supportedKinds = <String>{
    kindBirthday,
    kindWedding,
    kindAnniversary,
    kindCustom,
  };

  final String id;
  final String title;
  final int month;
  final int day;
  final int? year;
  final String kind;
  final bool repeatsAnnually;

  bool get isBirthday => kind == kindBirthday;

  DateTime get eventDate => DateTime(year ?? 2000, month, day);

  bool occursOn(DateTime date) {
    if (repeatsAnnually) return date.month == month && date.day == day;
    return date.year == year && date.month == month && date.day == day;
  }

  SpecialDay copyWith({
    String? title,
    int? month,
    int? day,
    int? year,
    String? kind,
    bool? repeatsAnnually,
  }) =>
      SpecialDay(
        id: id,
        title: title ?? this.title,
        month: month ?? this.month,
        day: day ?? this.day,
        year: year ?? this.year,
        kind: kind ?? this.kind,
        repeatsAnnually: repeatsAnnually ?? this.repeatsAnnually,
      );

  int get monthDayKey => month * 100 + day;
}

/// Schedules / cancels the local notification for a [SpecialDay].
class SpecialDayNotifications {
  const SpecialDayNotifications._();

  static int notificationId(String specialDayId) =>
      reminderNotificationId('specialday_$specialDayId');

  static DateTime? _nextOccurrence(SpecialDay day, DateTime now) {
    if (!day.repeatsAnnually) {
      final year = day.year;
      if (year == null || !_isValidDate(year, day.month, day.day)) return null;
      final candidate = DateTime(year, day.month, day.day, 9);
      return candidate.isAfter(now) ? candidate : null;
    }

    // Search rather than relying on DateTime's overflow normalization. A
    // 29-February event therefore remains 29 February in the next leap year.
    for (var year = now.year; year <= now.year + 8; year++) {
      if (!_isValidDate(year, day.month, day.day)) continue;
      final candidate = DateTime(year, day.month, day.day, 9);
      if (candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  static bool _isValidDate(int year, int month, int day) {
    final value = DateTime(year, month, day);
    return value.year == year && value.month == month && value.day == day;
  }

  @visibleForTesting
  static DateTime? nextOccurrenceForTesting(SpecialDay day, DateTime now) =>
      _nextOccurrence(day, now);

  static Future<void> schedule(SpecialDay day, {required bool isTr}) async {
    final at = _nextOccurrence(day, DateTime.now());
    if (at == null) {
      await cancel(day.id);
      return;
    }
    final title = day.isBirthday
        ? (isTr ? '🎂 Doğum günü' : '🎂 Birthday')
        : (isTr ? '✨ Özel gün' : '✨ Special day');
    final body = day.isBirthday
        ? (isTr
            ? '${day.title} bugün — kendine bir an ayır 💫'
            : "${day.title} is today — take a moment for yourself 💫")
        : (isTr ? '${day.title} bugün 💛' : '${day.title} is today 💛');
    try {
      await NotificationService.instance.scheduleOnceAt(
        id: notificationId(day.id),
        title: title,
        body: body,
        at: at,
      );
    } catch (error) {
      debugPrint('[SpecialDays] schedule failed: ${error.runtimeType}');
    }
  }

  static Future<void> cancel(String specialDayId) async {
    try {
      await NotificationService.instance.cancel(notificationId(specialDayId));
    } catch (error) {
      debugPrint('[SpecialDays] cancel failed: ${error.runtimeType}');
    }
  }

  static Future<void> rearmAll(
    List<SpecialDay> days, {
    required bool isTr,
  }) async {
    for (final day in days) {
      await schedule(day, isTr: isTr);
    }
  }
}
