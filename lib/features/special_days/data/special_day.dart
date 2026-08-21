import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/reminder_notification_ids.dart';

/// A user's "special day" — a birthday, anniversary, or any date they want to
/// be gently reminded of every year. Stored locally in [SharedPreferences]
/// (no server table needed) as a small JSON list, and surfaced on the calendar
/// with a distinct marker plus an annual local notification.
@immutable
class SpecialDay {
  const SpecialDay({
    required this.id,
    required this.title,
    required this.month,
    required this.day,
    this.year,
    this.kind = kindCustom,
  });

  static const kindBirthday = 'birthday';
  static const kindCustom = 'custom';

  final String id;
  final String title;
  final int month; // 1–12
  final int day; // 1–31
  final int? year; // optional original year (e.g. birth year)
  final String kind;

  bool get isBirthday => kind == kindBirthday;

  SpecialDay copyWith({
    String? title,
    int? month,
    int? day,
    int? year,
    String? kind,
  }) =>
      SpecialDay(
        id: id,
        title: title ?? this.title,
        month: month ?? this.month,
        day: day ?? this.day,
        year: year ?? this.year,
        kind: kind ?? this.kind,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'month': month,
        'day': day,
        if (year != null) 'year': year,
        'kind': kind,
      };

  factory SpecialDay.fromJson(Map<String, dynamic> json) => SpecialDay(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        month: (json['month'] as num?)?.toInt() ?? 1,
        day: (json['day'] as num?)?.toInt() ?? 1,
        year: (json['year'] as num?)?.toInt(),
        kind: json['kind']?.toString() ?? kindCustom,
      );

  /// A stable month+day key (1..1231) used for O(1) calendar membership tests
  /// (special days recur every year, so only month/day matter).
  int get monthDayKey => month * 100 + day;
}

/// Local persistence for [SpecialDay]s, backed by [SharedPreferences].
class SpecialDaysRepository {
  static const _key = 'special_days_v1';

  Future<List<SpecialDay>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key);
      if (raw == null) return const [];
      return raw
          .map((item) {
            try {
              return SpecialDay.fromJson(
                  Map<String, dynamic>.from(jsonDecode(item) as Map));
            } catch (_) {
              return null;
            }
          })
          .whereType<SpecialDay>()
          .toList(growable: false);
    } catch (error) {
      debugPrint('[SpecialDays] load failed: ${error.runtimeType}');
      return const [];
    }
  }

  Future<void> _saveAll(List<SpecialDay> days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        days.map((d) => jsonEncode(d.toJson())).toList(growable: false),
      );
    } catch (error) {
      debugPrint('[SpecialDays] save failed: ${error.runtimeType}');
    }
  }

  Future<List<SpecialDay>> addOrReplace(SpecialDay day) async {
    final days = List<SpecialDay>.of(await load());
    final index = days.indexWhere((d) => d.id == day.id);
    if (index >= 0) {
      days[index] = day;
    } else {
      days.add(day);
    }
    await _saveAll(days);
    return days;
  }

  Future<List<SpecialDay>> remove(String id) async {
    final days = List<SpecialDay>.of(await load())
      ..removeWhere((d) => d.id == id);
    await _saveAll(days);
    return days;
  }

  /// Adds or updates the single "birthday" entry (there is only ever one).
  Future<List<SpecialDay>> setBirthday({
    required int month,
    required int day,
    int? year,
    required String title,
  }) async {
    final days = List<SpecialDay>.of(await load())
      ..removeWhere((d) => d.isBirthday);
    days.add(SpecialDay(
      id: 'birthday',
      title: title,
      month: month,
      day: day,
      year: year,
      kind: SpecialDay.kindBirthday,
    ));
    await _saveAll(days);
    return days;
  }
}

/// Schedules / cancels the annual local notification for a [SpecialDay].
///
/// Special days recur yearly; [NotificationService.scheduleOnceAt] fires once,
/// so we schedule the NEXT occurrence and re-arm every time the list is loaded
/// (app open / screen open), which keeps the yearly reminder alive.
class SpecialDayNotifications {
  const SpecialDayNotifications._();

  static int notificationId(String specialDayId) =>
      reminderNotificationId('specialday_$specialDayId');

  static DateTime _nextOccurrence(SpecialDay day, DateTime now) {
    var candidate = DateTime(now.year, day.month, day.day, 9, 0);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year + 1, day.month, day.day, 9, 0);
    }
    return candidate;
  }

  static Future<void> schedule(SpecialDay day, {required bool isTr}) async {
    final at = _nextOccurrence(day, DateTime.now());
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

  static Future<void> rearmAll(List<SpecialDay> days,
      {required bool isTr}) async {
    for (final day in days) {
      await schedule(day, isTr: isTr);
    }
  }
}
