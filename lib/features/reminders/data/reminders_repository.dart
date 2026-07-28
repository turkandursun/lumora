import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/reminders_table.dart';
import '../../../core/services/reminder_notifier.dart';

/// Localized title + notification body for one reminder, resolved by the
/// presentation layer (which has an [AppLocalizations] instance) and handed
/// down here — this repository never touches localization directly, so it
/// stays correct even if the app's language changes between calls.
class ReminderCopy {
  const ReminderCopy({required this.title, required this.body});

  final String title;
  final String body;
}

/// Icon keys for the four seeded starter reminders — also used to look up
/// each one's [ReminderCopy] in the presentation layer.
class DefaultReminderIconKeys {
  DefaultReminderIconKeys._();

  static const morningJournal = 'sun';
  static const breathingBreak = 'breathing';
  static const gratitudeMoment = 'heart';
  static const weeklyReflection = 'reflection';
}

/// Icon key used for reminders the user creates themselves via the "New
/// Reminder" sheet.
const customReminderIconKey = 'custom';

const _seededPrefKey = 'reminders_seeded';

/// Owns reminder persistence (via [AppDatabase]) and keeps
/// [NotificationService] in sync with it: enabling a reminder schedules its
/// notification, disabling or deleting one cancels it.
class RemindersRepository {
  RemindersRepository({
    required AppDatabase database,
    required ReminderNotifier notifications,
  })  : _db = database,
        _notifications = notifications;

  final AppDatabase _db;
  final ReminderNotifier _notifications;

  Stream<List<ReminderRow>> watchAll() => _db.select(_db.reminders).watch();

  /// Inserts the four starter reminders exactly once, ever (tracked via a
  /// [SharedPreferences] flag, so manually deleting them all later doesn't
  /// bring them back). Schedules notifications for whichever of them come
  /// in enabled (all of them, by default).
  ///
  /// [defaultCopy] must have an entry for each key in
  /// [DefaultReminderIconKeys].
  Future<void> ensureSeeded(Map<String, ReminderCopy> defaultCopy) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededPrefKey) ?? false) return;

    await _db.batch((batch) {
      batch.insertAll(_db.reminders, [
        RemindersCompanion.insert(
          title: defaultCopy[DefaultReminderIconKeys.morningJournal]!.title,
          iconKey: DefaultReminderIconKeys.morningJournal,
          frequency: ReminderFrequency.daily,
          hour: 8,
          minute: 0,
        ),
        RemindersCompanion.insert(
          title: defaultCopy[DefaultReminderIconKeys.breathingBreak]!.title,
          iconKey: DefaultReminderIconKeys.breathingBreak,
          frequency: ReminderFrequency.daily,
          hour: 12,
          minute: 0,
        ),
        RemindersCompanion.insert(
          title: defaultCopy[DefaultReminderIconKeys.gratitudeMoment]!.title,
          iconKey: DefaultReminderIconKeys.gratitudeMoment,
          frequency: ReminderFrequency.daily,
          hour: 21,
          minute: 0,
        ),
        RemindersCompanion.insert(
          title: defaultCopy[DefaultReminderIconKeys.weeklyReflection]!.title,
          iconKey: DefaultReminderIconKeys.weeklyReflection,
          frequency: ReminderFrequency.weekly,
          weekday: const Value(DateTime.sunday),
          hour: 18,
          minute: 0,
        ),
      ]);
    });
    await prefs.setBool(_seededPrefKey, true);

    for (final row in await _db.select(_db.reminders).get()) {
      if (!row.enabled) continue;
      final copy = defaultCopy[row.iconKey];
      if (copy != null) await _schedule(row, copy);
    }
  }

  Future<void> addCustomReminder({
    required String title,
    required ReminderFrequency frequency,
    int? weekday,
    required int hour,
    required int minute,
    required String notificationBody,
  }) async {
    final id = await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(
            title: title,
            iconKey: customReminderIconKey,
            frequency: frequency,
            weekday: Value(weekday),
            hour: hour,
            minute: minute,
          ),
        );
    await _notifications.schedule(
      id: id,
      title: title,
      body: notificationBody,
      frequency: frequency,
      weekday: weekday,
      hour: hour,
      minute: minute,
    );
  }

  /// Toggles [reminder]'s enabled state, scheduling or cancelling its
  /// notification to match. [copy] is only needed when enabling (nothing
  /// needs to be (re)scheduled when disabling).
  Future<void> setEnabled(ReminderRow reminder, bool enabled, {ReminderCopy? copy}) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(reminder.id)))
        .write(RemindersCompanion(enabled: Value(enabled)));

    if (enabled) {
      if (copy != null) await _schedule(reminder, copy);
    } else {
      await _notifications.cancel(reminder.id);
    }
  }

  Future<void> delete(ReminderRow reminder) async {
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(reminder.id))).go();
    await _notifications.cancel(reminder.id);
  }

  Future<void> _schedule(ReminderRow row, ReminderCopy copy) {
    return _notifications.schedule(
      id: row.id,
      title: copy.title,
      body: copy.body,
      frequency: row.frequency,
      weekday: row.weekday,
      hour: row.hour,
      minute: row.minute,
    );
  }
}
