import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
const _defaultDisabledFixPrefKey = 'reminders_default_disabled_fix_v1';

/// Owns reminder persistence (via [AppDatabase]) and keeps
/// [NotificationService] in sync with it: enabling a reminder schedules its
/// notification, disabling or deleting one cancels it.
class RemindersRepository {
  RemindersRepository({
    required AppDatabase database,
    required ReminderNotifier notifications,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _notifications = notifications,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final ReminderNotifier _notifications;
  final SupabaseClient _client;

  Stream<List<ReminderRow>> watchAll() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return (_db.select(_db.reminders)..where((t) => t.userId.isNull())).watch();
    }
    return (_db.select(_db.reminders)..where((t) => t.userId.equals(user.id))).watch();
  }

  /// Inserts the four starter reminders exactly once, ever (tracked via a
  /// [SharedPreferences] flag, so manually deleting them all later doesn't
  /// bring them back). Toggled OFF (enabled = false) by default.
  Future<void> ensureSeeded(Map<String, ReminderCopy> defaultCopy) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededPrefKey) ?? false) return;

    final user = _client.auth.currentUser;
    final defaultReminders = [
      (
        title: defaultCopy[DefaultReminderIconKeys.morningJournal]!.title,
        iconKey: DefaultReminderIconKeys.morningJournal,
        frequency: ReminderFrequency.daily,
        weekday: null,
        hour: 8,
        minute: 0,
      ),
      (
        title: defaultCopy[DefaultReminderIconKeys.breathingBreak]!.title,
        iconKey: DefaultReminderIconKeys.breathingBreak,
        frequency: ReminderFrequency.daily,
        weekday: null,
        hour: 12,
        minute: 0,
      ),
      (
        title: defaultCopy[DefaultReminderIconKeys.gratitudeMoment]!.title,
        iconKey: DefaultReminderIconKeys.gratitudeMoment,
        frequency: ReminderFrequency.daily,
        weekday: null,
        hour: 21,
        minute: 0,
      ),
      (
        title: defaultCopy[DefaultReminderIconKeys.weeklyReflection]!.title,
        iconKey: DefaultReminderIconKeys.weeklyReflection,
        frequency: ReminderFrequency.weekly,
        weekday: DateTime.sunday,
        hour: 18,
        minute: 0,
      ),
    ];

    for (final item in defaultReminders) {
      String? cloudId;
      if (user != null) {
        try {
          final insertData = <String, dynamic>{
            'user_id': user.id,
            'title': item.title,
            'icon_key': item.iconKey,
            'frequency': item.frequency.name,
            'weekday': item.weekday,
            'hour': item.hour,
            'minute': item.minute,
            'enabled': false,
          };

          final response = await _client
              .from('reminders')
              .insert(insertData)
              .select('id')
              .single();

          cloudId = response['id']?.toString();
          debugPrint('[RemindersSync] Seeded default reminder into Supabase, iconKey=${item.iconKey}, cloudId=$cloudId');
        } catch (e) {
          debugPrint('[RemindersSync] Error seeding default reminder into Supabase: $e');
        }
      }

      await _db.into(_db.reminders).insert(
            RemindersCompanion.insert(
              title: item.title,
              iconKey: item.iconKey,
              frequency: item.frequency,
              weekday: Value(item.weekday),
              hour: item.hour,
              minute: item.minute,
              enabled: const Value(false),
              userId: Value(user?.id),
              supabaseId: Value(cloudId),
            ),
          );
    }

    await prefs.setBool(_seededPrefKey, true);
  }

  /// Uploads any local reminders that do not have a [supabaseId] to Supabase (e.g. seeded while logged out, or legacy rows).
  Future<void> syncUnsyncedRemindersToCloud() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final unsyncedRows = await (_db.select(_db.reminders)
            ..where((t) => t.supabaseId.isNull() | t.userId.isNull()))
          .get();

      for (final row in unsyncedRows) {
        try {
          final insertData = <String, dynamic>{
            'user_id': user.id,
            'title': row.title,
            'icon_key': row.iconKey,
            'frequency': row.frequency.name,
            'weekday': row.weekday,
            'hour': row.hour,
            'minute': row.minute,
            'enabled': row.enabled,
          };

          final response = await _client
              .from('reminders')
              .insert(insertData)
              .select('id')
              .single();

          final cloudId = response['id']?.toString();
          if (cloudId != null) {
            await (_db.update(_db.reminders)..where((t) => t.id.equals(row.id)))
                .write(RemindersCompanion(
              userId: Value(user.id),
              supabaseId: Value(cloudId),
            ));
            debugPrint('[RemindersSync] Backfilled local reminder (id=${row.id}) to Supabase, cloudId=$cloudId');
          }
        } catch (e) {
          debugPrint('[RemindersSync] Error backfilling local reminder (id=${row.id}) to Supabase: $e');
        }
      }
    } catch (e) {
      debugPrint('[RemindersSync] Error running syncUnsyncedRemindersToCloud: $e');
    }
  }

  /// One-time migration for existing devices: defaults legacy starter reminders to OFF
  /// and cancels any active notifications for them.
  Future<void> fixLegacyDefaultRemindersDisabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_defaultDisabledFixPrefKey) ?? false) return;

      const defaultKeys = [
        DefaultReminderIconKeys.morningJournal,
        DefaultReminderIconKeys.breathingBreak,
        DefaultReminderIconKeys.gratitudeMoment,
        DefaultReminderIconKeys.weeklyReflection,
      ];

      final rows = await (_db.select(_db.reminders)
            ..where((t) => t.iconKey.isIn(defaultKeys)))
          .get();

      for (final row in rows) {
        if (row.enabled) {
          await _notifications.cancel(row.id);
          await (_db.update(_db.reminders)..where((t) => t.id.equals(row.id)))
              .write(const RemindersCompanion(enabled: Value(false)));
        }
      }

      await prefs.setBool(_defaultDisabledFixPrefKey, true);
      debugPrint('[RemindersSync] One-time migration: defaulted legacy starter reminders to OFF.');
    } catch (e) {
      debugPrint('[RemindersSync] Error running legacy default reminders fix: $e');
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
    final user = _client.auth.currentUser;
    String? cloudId;

    if (user != null) {
      try {
        final insertData = <String, dynamic>{
          'user_id': user.id,
          'title': title,
          'icon_key': customReminderIconKey,
          'frequency': frequency.name,
          'weekday': weekday,
          'hour': hour,
          'minute': minute,
          'enabled': true,
        };

        final response = await _client
            .from('reminders')
            .insert(insertData)
            .select('id')
            .single();

        cloudId = response['id']?.toString();
        debugPrint('[RemindersSync] Inserted custom reminder into Supabase, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[RemindersSync] Error inserting into Supabase: $e');
      }
    }

    final id = await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(
            title: title,
            iconKey: customReminderIconKey,
            frequency: frequency,
            weekday: Value(weekday),
            hour: hour,
            minute: minute,
            enabled: const Value(true),
            userId: Value(user?.id),
            supabaseId: Value(cloudId),
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
  /// notification to match.
  Future<void> setEnabled(ReminderRow reminder, bool enabled, {ReminderCopy? copy}) async {
    final user = _client.auth.currentUser;

    await (_db.update(_db.reminders)..where((t) => t.id.equals(reminder.id)))
        .write(RemindersCompanion(enabled: Value(enabled)));

    if (enabled) {
      if (copy != null) await _schedule(reminder, copy);
    } else {
      await _notifications.cancel(reminder.id);
    }

    if (user != null && reminder.supabaseId != null) {
      try {
        await _client.from('reminders').update({'enabled': enabled}).eq('id', reminder.supabaseId!);
        debugPrint('[RemindersSync] Updated enabled=$enabled in Supabase for cloudId=${reminder.supabaseId}');
      } catch (e) {
        debugPrint('[RemindersSync] Error updating enabled in Supabase: $e');
      }
    }
  }

  Future<void> delete(ReminderRow reminder) async {
    final user = _client.auth.currentUser;

    await (_db.delete(_db.reminders)..where((t) => t.id.equals(reminder.id))).go();
    await _notifications.cancel(reminder.id);

    if (user != null && reminder.supabaseId != null) {
      try {
        await _client.from('reminders').delete().eq('id', reminder.supabaseId!);
        debugPrint('[RemindersSync] Deleted reminder from Supabase, cloudId=${reminder.supabaseId}');
      } catch (e) {
        debugPrint('[RemindersSync] Error deleting reminder from Supabase: $e');
      }
    }
  }

  /// Deletes all local reminders and cancels their notifications (e.g. upon user logout).
  Future<void> deleteAll() async {
    final rows = await _db.select(_db.reminders).get();
    for (final row in rows) {
      try {
        await _notifications.cancel(row.id);
      } catch (_) {}
    }
    await _db.delete(_db.reminders).go();
  }

  /// Fetches user's reminders from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> fetchAndSyncFromSupabase(Map<String, ReminderCopy> defaultCopy) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('reminders')
          .select()
          .eq('user_id', user.id);

      final cloudRows = response as List;
      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id']?.toString();
        if (id != null) {
          cloudMap[id] = row as Map<String, dynamic>;
        }
      }

      final localEntries = await (_db.select(_db.reminders)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, ReminderRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          final localRow = localSupabaseIdMap[localSupabaseId]!;
          await _notifications.cancel(localRow.id);
          await (_db.delete(_db.reminders)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[RemindersSync] Deleted local reminder with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally, or update enabled state
      for (final cloudId in cloudMap.keys) {
        final row = cloudMap[cloudId]!;
        final title = row['title'] as String? ?? '';
        final iconKey = row['icon_key'] as String? ?? customReminderIconKey;
        final freqStr = row['frequency'] as String? ?? 'daily';
        final frequency = ReminderFrequency.values.firstWhere(
          (e) => e.name == freqStr,
          orElse: () => ReminderFrequency.daily,
        );
        final weekday = row['weekday'] as int?;
        final hour = row['hour'] as int? ?? 9;
        final minute = row['minute'] as int? ?? 0;
        final enabled = row['enabled'] as bool? ?? false;

        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final newId = await _db.into(_db.reminders).insert(
                RemindersCompanion.insert(
                  title: title,
                  iconKey: iconKey,
                  frequency: frequency,
                  weekday: Value(weekday),
                  hour: hour,
                  minute: minute,
                  enabled: Value(enabled),
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );

          if (enabled) {
            final copy = defaultCopy[iconKey] ??
                ReminderCopy(title: title, body: title);
            await _notifications.schedule(
              id: newId,
              title: copy.title,
              body: copy.body,
              frequency: frequency,
              weekday: weekday,
              hour: hour,
              minute: minute,
            );
          }
          debugPrint('[RemindersSync] Inserted cloud reminder locally, cloudId=$cloudId');
        } else {
          final localRow = localSupabaseIdMap[cloudId]!;
          if (localRow.enabled != enabled) {
            await (_db.update(_db.reminders)..where((t) => t.id.equals(localRow.id)))
                .write(RemindersCompanion(enabled: Value(enabled)));

            if (enabled) {
              final copy = defaultCopy[iconKey] ??
                  ReminderCopy(title: title, body: title);
              await _schedule(localRow, copy);
            } else {
              await _notifications.cancel(localRow.id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[RemindersSync] Error fetching from Supabase: $e');
    }
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
