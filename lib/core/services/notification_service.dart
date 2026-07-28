import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/tables/reminders_table.dart';
import 'reminder_notifier.dart';
import 'reminder_scheduling.dart';

/// Schedules and cancels local reminder notifications.
///
/// Real notifications are only ever attempted on platforms the underlying
/// plugin actually supports for scheduled notifications (Android, iOS,
/// Windows) — everywhere else (web, and any other desktop target) this
/// quietly no-ops so the rest of the app (storing/toggling reminders) keeps
/// working without a working notification backend.
///
/// [FlutterLocalNotificationsPlugin] itself is a singleton with no way to
/// substitute a fake, so the actual scheduling math lives in the plugin-free
/// [computeNextSchedule] instead, where it's directly unit-testable; callers
/// that just need *a* [ReminderNotifier] (like [RemindersRepository]) can
/// depend on that interface and use a trivial fake in tests instead.
class NotificationService implements ReminderNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'reminders';
  static const _channelName = 'Reminders';
  static const _channelDescription = 'Gentle nudges for journaling, breathing, and reflection';

  // Fixed, arbitrary identifiers for Windows toast registration — these
  // just need to be stable across runs, not globally unique.
  static const _windowsAppUserModelId = 'com.lumora.mindfuljournal';
  static const _windowsGuid = '6a548b0a-4b6d-4a1d-9e9e-9a6b1d8f9d21';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  /// Initializes the plugin and local timezone database. Safe to call
  /// repeatedly — only does real work once. Must complete before
  /// [schedule] is called.
  Future<void> init() async {
    if (_initialized || !_isSupportedPlatform) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Fall back to whatever the timezone package defaults to (UTC) if the
      // device's timezone can't be resolved — reminders will still fire,
      // just possibly at the wrong wall-clock time until this succeeds.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: 'Lumora',
          appUserModelId: _windowsAppUserModelId,
          guid: _windowsGuid,
        ),
      ),
    );
    _initialized = true;
  }

  /// Requests platform notification permission. No-ops on platforms that
  /// don't need an explicit runtime request (Windows toast notifications,
  /// Android below 13).
  @override
  Future<void> requestPermission() async {
    if (!_isSupportedPlatform) return;
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Schedules a repeating (or, for [ReminderFrequency.once], single-shot)
  /// notification. [id] should be stable per-reminder (the reminder's
  /// database row id works well) so a later [cancel] call can target it.
  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required ReminderFrequency frequency,
    int? weekday,
    required int hour,
    required int minute,
  }) async {
    if (!_isSupportedPlatform) return;
    await init();

    final schedule = computeNextSchedule(
      frequency: frequency,
      weekday: weekday,
      hour: hour,
      minute: minute,
      now: tz.TZDateTime.now(tz.local),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: schedule.dateTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: schedule.matchDateTimeComponents,
    );
  }

  /// Cancels a previously scheduled notification. Safe to call even if
  /// nothing was ever scheduled under [id].
  @override
  Future<void> cancel(int id) async {
    if (!_isSupportedPlatform) return;
    await _plugin.cancel(id: id);
  }
}
