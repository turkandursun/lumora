import 'package:shared_preferences/shared_preferences.dart';

import '../database/tables/reminders_table.dart';
import 'notification_service.dart';

/// Three warm, user-configurable daily nudges from Luma, separate from the
/// user's own manual reminders:
///
///  • a warm **good-morning** message every morning,
///  • a friendly **"pişt, neredesin?"** poke in the evening — but only on days
///    the app wasn't opened at all (it's re-armed for the next day every time
///    the app is opened, so an active user never gets nagged), and
///  • a cozy **good-night** message every night.
///
/// Morning and night are plain repeating daily notifications. The evening poke
/// is a one-off that's re-armed on each app open, which is what gives it the
/// "only if you didn't come by today" behaviour. All three use high, fixed ids
/// so they never collide with the user's own reminders (small DB-row ids).
class SmartReminderSettings {
  const SmartReminderSettings({
    this.enabled = true,
    this.morningHour = 9,
    this.morningMinute = 0,
    this.eveningHour = 19,
    this.eveningMinute = 0,
    this.nightHour = 22,
    this.nightMinute = 30,
  });

  final bool enabled;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;
  final int nightHour;
  final int nightMinute;

  SmartReminderSettings copyWith({
    bool? enabled,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
    int? nightHour,
    int? nightMinute,
  }) =>
      SmartReminderSettings(
        enabled: enabled ?? this.enabled,
        morningHour: morningHour ?? this.morningHour,
        morningMinute: morningMinute ?? this.morningMinute,
        eveningHour: eveningHour ?? this.eveningHour,
        eveningMinute: eveningMinute ?? this.eveningMinute,
        nightHour: nightHour ?? this.nightHour,
        nightMinute: nightMinute ?? this.nightMinute,
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
  static const _kNightH = 'smart_night_h';
  static const _kNightM = 'smart_night_m';

  // High, fixed ids that won't clash with per-reminder DB ids.
  static const int _morningId = 900001;
  static const int _eveningId = 900002;
  static const int _nightId = 900003;

  Future<SmartReminderSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return SmartReminderSettings(
        enabled: p.getBool(_kEnabled) ?? true,
        morningHour: p.getInt(_kMorningH) ?? 9,
        morningMinute: p.getInt(_kMorningM) ?? 0,
        eveningHour: p.getInt(_kEveningH) ?? 19,
        eveningMinute: p.getInt(_kEveningM) ?? 0,
        nightHour: p.getInt(_kNightH) ?? 22,
        nightMinute: p.getInt(_kNightM) ?? 30,
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
      await p.setInt(_kNightH, s.nightHour);
      await p.setInt(_kNightM, s.nightMinute);
    } catch (_) {}
    await sync(isTr: isTr);
  }

  /// (Re)schedules all three nudges to match the saved settings. Safe to call
  /// on every app launch.
  Future<void> sync({required bool isTr}) async {
    final s = await load();
    final n = NotificationService.instance;
    await n.init();
    if (!s.enabled) {
      await n.cancel(_morningId);
      await n.cancel(_eveningId);
      await n.cancel(_nightId);
      return;
    }
    await n.requestPermission();

    // Warm good-morning — every morning.
    await n.schedule(
      id: _morningId,
      title: isTr ? 'Günaydın ☀️' : 'Good morning ☀️',
      body: isTr
          ? 'Yeni bir gün, yeni bir başlangıç. Bugün kendine nazik ol 💛'
          : 'A brand new day. Be gentle with yourself today 💛',
      frequency: ReminderFrequency.daily,
      hour: s.morningHour,
      minute: s.morningMinute,
    );

    // Cozy good-night — every night.
    await n.schedule(
      id: _nightId,
      title: isTr ? 'İyi geceler 🌙' : 'Good night 🌙',
      body: isTr
          ? 'Bugün için teşekkürler. Tatlı rüyalar, yarın görüşürüz 💛'
          : 'Thank you for today. Sweet dreams — see you tomorrow 💛',
      frequency: ReminderFrequency.daily,
      hour: s.nightHour,
      minute: s.nightMinute,
    );

    // Evening "pişt, neredesin?" — armed for the next day; opening the app
    // re-arms it further out, so it only ever fires after a full day away.
    await _armEveningPoke(s, isTr: isTr);
  }

  /// Called whenever the app is opened/resumed: slides the evening poke to the
  /// next day so an active user is never nudged, while a full day of absence
  /// still triggers the previously-armed poke.
  Future<void> markAppOpened({required bool isTr}) async {
    final s = await load();
    if (!s.enabled) return;
    await NotificationService.instance.init();
    await _armEveningPoke(s, isTr: isTr);
  }

  Future<void> _armEveningPoke(
    SmartReminderSettings s, {
    required bool isTr,
  }) async {
    final n = NotificationService.instance;
    await n.cancel(_eveningId);
    // Tomorrow at the evening time — because the app is being opened now,
    // today's poke is skipped and only a full day of silence brings it back.
    final now = DateTime.now();
    final target = DateTime(
      now.year,
      now.month,
      now.day + 1,
      s.eveningHour,
      s.eveningMinute,
    );
    await n.scheduleOnceAt(
      id: _eveningId,
      title: isTr ? 'Pişt, neredesin? 👀' : 'Psst, where are you? 👀',
      body: isTr
          ? 'Bugün seni özledim. Bir uğrayıp iki satır yazmaya ne dersin? 💛'
          : 'Missed you today. Fancy dropping by for a couple of lines? 💛',
      at: target,
    );
  }
}
