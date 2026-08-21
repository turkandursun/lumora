import 'package:shared_preferences/shared_preferences.dart';

import 'notification_messages.dart';
import 'notification_service.dart';

/// ASTRA's five daily nudge slots, each drawing from its own 30-message pool
/// with a rotating (sequential-then-shuffled) schedule — see
/// [notification_messages.dart].
///
///  • 09:00 — Güne Başlarken (sabah motivasyonu)
///  • 13:00 — Gün İçi Molaları (nefes ve odaklanma)
///  • 18:00 — Öz Değer Hatırlatıcıları
///  • 22:00 — Gün Sonu (gevşeme ve meditasyon)
///  • 15:00 — Yoklama, yalnızca uygulamanın hiç açılmadığı günlerde
///
/// The four fixed-time slots are scheduled as individual dated notifications
/// over a short rolling window and re-armed on every app launch/resume — this
/// is what lets each day carry a *different* message (a single repeating
/// notification could only ever show one fixed body). The absence "yoklama"
/// nudge is armed only for days *after* today, so opening the app slides it
/// forward and it fires solely after a full day away.
///
/// Times are fixed by product spec; the only user-facing control is the
/// master on/off toggle (see [SmartRemindersCard]).
class SmartReminderSettings {
  const SmartReminderSettings({this.enabled = true});

  final bool enabled;

  SmartReminderSettings copyWith({bool? enabled}) =>
      SmartReminderSettings(enabled: enabled ?? this.enabled);
}

class SmartRemindersService {
  SmartRemindersService._();
  static final SmartRemindersService instance = SmartRemindersService._();

  static const _kEnabled = 'smart_reminders_enabled';
  static const _kAnchor = 'smart_rotation_anchor_epoch_day';

  // How many days ahead each slot is pre-scheduled. Kept small so the total
  // pending count (≈ 4 × horizon + horizon absence) stays well under iOS's
  // 64-pending-notification cap, leaving room for the user's own reminders.
  static const int _horizonDays = 7;

  // Distinct id blocks per slot; base + dayOffset (0.._horizonDays). All are
  // far below the reminder namespace (0x40000000) so they never collide with
  // user reminders or focus-completion notifications.
  static const int _morningBase = 910000;
  static const int _middayBase = 920000;
  static const int _selfWorthBase = 930000;
  static const int _nightBase = 940000;
  static const int _absenceBase = 950000;

  // Slot wall-clock times (fixed by spec).
  static const int _morningHour = 9, _morningMinute = 0;
  static const int _middayHour = 13, _middayMinute = 0;
  static const int _selfWorthHour = 18, _selfWorthMinute = 0;
  static const int _nightHour = 22, _nightMinute = 0;
  static const int _absenceHour = 15, _absenceMinute = 0;

  // Per-slot shuffle seeds — must differ so the five pools rotate independently.
  static const int _morningSeed = 11;
  static const int _middaySeed = 23;
  static const int _selfWorthSeed = 37;
  static const int _nightSeed = 53;
  static const int _absenceSeed = 71;

  static const String _title = 'ASTRA';

  Future<SmartReminderSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return SmartReminderSettings(enabled: p.getBool(_kEnabled) ?? true);
    } catch (_) {
      return const SmartReminderSettings();
    }
  }

  Future<void> save(SmartReminderSettings s, {required bool isTr}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kEnabled, s.enabled);
    } catch (_) {}
    await sync(isTr: isTr);
  }

  /// (Re)schedules every slot to match the saved settings. Safe to call on
  /// every app launch. [isTr] is currently unused (content is Turkish-only)
  /// but kept so translations can be wired in later without touching callers.
  Future<void> sync({required bool isTr}) async {
    final s = await load();
    final n = NotificationService.instance;
    await n.init();
    await _cancelAll(n);
    if (!s.enabled) return;
    await n.requestPermission();
    await _armAll(n, isTr: isTr);
  }

  /// Called whenever the app is opened/resumed: re-arms all slots, which in
  /// particular slides the absence "yoklama" nudge forward so an active user
  /// is never poked.
  Future<void> markAppOpened({required bool isTr}) async {
    final s = await load();
    final n = NotificationService.instance;
    await n.init();
    if (!s.enabled) {
      await _cancelAll(n);
      return;
    }
    await _armAll(n, isTr: isTr);
  }

  Future<void> _armAll(NotificationService n, {required bool isTr}) async {
    final anchor = await _anchorEpochDay();
    final today = _epochDay(DateTime.now());

    await _armSlot(n,
        base: _morningBase,
        hour: _morningHour,
        minute: _morningMinute,
        messages: morningMessages(isTr),
        slotSeed: _morningSeed,
        anchor: anchor,
        today: today,
        includeToday: true);
    await _armSlot(n,
        base: _middayBase,
        hour: _middayHour,
        minute: _middayMinute,
        messages: middayMessages(isTr),
        slotSeed: _middaySeed,
        anchor: anchor,
        today: today,
        includeToday: true);
    await _armSlot(n,
        base: _selfWorthBase,
        hour: _selfWorthHour,
        minute: _selfWorthMinute,
        messages: selfWorthMessages(isTr),
        slotSeed: _selfWorthSeed,
        anchor: anchor,
        today: today,
        includeToday: true);
    await _armSlot(n,
        base: _nightBase,
        hour: _nightHour,
        minute: _nightMinute,
        messages: nightMessages(isTr),
        slotSeed: _nightSeed,
        anchor: anchor,
        today: today,
        includeToday: true);
    // Absence: skip today — the app is open right now, so a "where are you?"
    // poke only makes sense starting tomorrow.
    await _armSlot(n,
        base: _absenceBase,
        hour: _absenceHour,
        minute: _absenceMinute,
        messages: absenceMessages(isTr),
        slotSeed: _absenceSeed,
        anchor: anchor,
        today: today,
        includeToday: false);
  }

  Future<void> _armSlot(
    NotificationService n, {
    required int base,
    required int hour,
    required int minute,
    required List<String> messages,
    required int slotSeed,
    required int anchor,
    required int today,
    required bool includeToday,
  }) async {
    // Clear the whole window first so no stale day lingers after a re-arm.
    for (var i = 0; i <= _horizonDays; i++) {
      await n.cancel(base + i);
    }
    final start = includeToday ? 0 : 1;
    for (var i = start; i < _horizonDays; i++) {
      final dayEpoch = today + i;
      final dayNumber = dayEpoch - anchor;
      final index = rotatedIndex(
        slotSeed: slotSeed,
        dayNumber: dayNumber,
        listLength: messages.length,
      );
      final at = _dateFromEpochDay(dayEpoch, hour, minute);
      // scheduleOnceAt no-ops for times already in the past, so today's slot
      // is silently skipped if its hour has already passed.
      await n.scheduleOnceAt(
        id: base + i,
        title: _title,
        body: messages[index],
        at: at,
      );
    }
  }

  Future<void> _cancelAll(NotificationService n) async {
    for (final base in const [
      _morningBase,
      _middayBase,
      _selfWorthBase,
      _nightBase,
      _absenceBase,
    ]) {
      for (var i = 0; i <= _horizonDays; i++) {
        await n.cancel(base + i);
      }
    }
  }

  /// Whole-day count since the Unix epoch, in local time.
  int _epochDay(DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(DateTime(1970)).inDays;

  DateTime _dateFromEpochDay(int epochDay, int hour, int minute) {
    final date = DateTime(1970).add(Duration(days: epochDay));
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// The day rotation counting starts from — persisted on first run so that
  /// day 0 always shows message #1 of each list, regardless of install date.
  Future<int> _anchorEpochDay() async {
    try {
      final p = await SharedPreferences.getInstance();
      final existing = p.getInt(_kAnchor);
      if (existing != null) return existing;
      final anchor = _epochDay(DateTime.now());
      await p.setInt(_kAnchor, anchor);
      return anchor;
    } catch (_) {
      return _epochDay(DateTime.now());
    }
  }
}
