import 'package:shared_preferences/shared_preferences.dart';

import '../database/tables/reminders_table.dart';
import 'notification_service.dart';

/// User-configurable smart daily nudges, separate from the manual reminders:
///  • a morning mood check-in ("how do you feel today?")
///  • an evening writing invite ("want to write a few lines?") — this also
///    quietly protects the journaling streak before the day ends.
///
/// Both are plain recurring daily local notifications with fixed ids, so they
/// never collide with the user's own reminders (which use small DB-row ids).
class SmartReminderSettings {
  const SmartReminderSettings({
    this.enabled = true,
    this.morningHour = 9,
    this.morningMinute = 0,
    this.eveningHour = 20,
    this.eveningMinute = 30,
  });

  final bool enabled;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;

  SmartReminderSettings copyWith({
    bool? enabled,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
  }) =>
      SmartReminderSettings(
        enabled: enabled ?? this.enabled,
        morningHour: morningHour ?? this.morningHour,
        morningMinute: morningMinute ?? this.morningMinute,
        eveningHour: eveningHour ?? this.eveningHour,
        eveningMinute: eveningMinute ?? this.eveningMinute,
      );
}

class SmartRemindersService {
  SmartRemindersService._();
  static final SmartRemindersService instance = SmartRemindersService._();

  static const _kEnabled = 'smart_reminders_enabled';
  static const _kMorningH = 'smart_morning_h';
  static const _kMorningM = 'smart_morning_m';
  static const _kEveningH = 'smart_evening_h';
  static const _kEveningM = 'smart_evening_m';

  // High, fixed ids that won't clash with per-reminder DB ids.
  static const int _morningId = 900001;
  static const int _eveningId = 900002;

  Future<SmartReminderSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return SmartReminderSettings(
        enabled: p.getBool(_kEnabled) ?? true,
        morningHour: p.getInt(_kMorningH) ?? 9,
        morningMinute: p.getInt(_kMorningM) ?? 0,
        eveningHour: p.getInt(_kEveningH) ?? 20,
        eveningMinute: p.getInt(_kEveningM) ?? 30,
      );
    } catch (_) {
      return const SmartReminderSettings();
    }
  }

  Future<void> save(SmartReminderSettings s, {required bool isTr}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kEnabled, s.enabled);
      await p.setInt(_kMorningH, s.morningHour);
      await p.setInt(_kMorningM, s.morningMinute);
      await p.setInt(_kEveningH, s.eveningHour);
      await p.setInt(_kEveningM, s.eveningMinute);
    } catch (_) {}
    await sync(isTr: isTr);
  }

  /// (Re)schedules the two daily nudges to match the saved settings. Safe to
  /// call on every app launch.
  Future<void> sync({required bool isTr}) async {
    final s = await load();
    final n = NotificationService.instance;
    await n.init();
    if (!s.enabled) {
      await n.cancel(_morningId);
      await n.cancel(_eveningId);
      return;
    }
    await n.requestPermission();
    await n.schedule(
      id: _morningId,
      title: isTr ? 'Günaydın 🌸' : 'Good morning 🌸',
      body: isTr
          ? 'Bugün nasıl hissediyorsun?'
          : 'How are you feeling today?',
      frequency: ReminderFrequency.daily,
      hour: s.morningHour,
      minute: s.morningMinute,
    );
    await n.schedule(
      id: _eveningId,
      title: isTr ? 'Günün nasıldı?' : 'How was your day?',
      body: isTr
          ? 'Birkaç satır yazmak ister misin? ✍️'
          : 'Want to write a few lines? ✍️',
      frequency: ReminderFrequency.daily,
      hour: s.eveningHour,
      minute: s.eveningMinute,
    );
  }
}
