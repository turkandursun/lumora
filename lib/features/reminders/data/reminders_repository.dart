import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/reminders_table.dart';
import '../../../core/services/reminder_notification_ids.dart';
import '../../../core/services/reminder_notifier.dart';

class ReminderCopy {
  const ReminderCopy({required this.title, required this.body});

  final String title;
  final String body;
}

class DefaultReminderIconKeys {
  DefaultReminderIconKeys._();

  static const morningJournal = 'sun';
  static const breathingBreak = 'breathing';
  static const weeklyReflection = 'reflection';
}

class DefaultReminderKeys {
  DefaultReminderKeys._();

  static const morningJournal = 'morning_journal';
  static const breathingBreak = 'breathing_break';
  static const weeklyReflection = 'weekly_reflection';
}

class DefaultReminderDefinition {
  const DefaultReminderDefinition({
    required this.defaultKey,
    required this.iconKey,
    required this.frequency,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  final String defaultKey;
  final String iconKey;
  final ReminderFrequency frequency;
  final int? weekday;
  final int hour;
  final int minute;
}

const defaultReminderDefinitions = <DefaultReminderDefinition>[
  DefaultReminderDefinition(
    defaultKey: DefaultReminderKeys.morningJournal,
    iconKey: DefaultReminderIconKeys.morningJournal,
    frequency: ReminderFrequency.daily,
    weekday: null,
    hour: 8,
    minute: 0,
  ),
  DefaultReminderDefinition(
    defaultKey: DefaultReminderKeys.breathingBreak,
    iconKey: DefaultReminderIconKeys.breathingBreak,
    frequency: ReminderFrequency.daily,
    weekday: null,
    hour: 12,
    minute: 0,
  ),
  DefaultReminderDefinition(
    defaultKey: DefaultReminderKeys.weeklyReflection,
    iconKey: DefaultReminderIconKeys.weeklyReflection,
    frequency: ReminderFrequency.weekly,
    weekday: DateTime.sunday,
    hour: 18,
    minute: 0,
  ),
];

const customReminderIconKey = 'custom';
const _defaultDisabledFixPrefKey = 'reminders_default_disabled_fix_v1';
const _gratitudeCleanupPrefKey = 'reminders_gratitude_cleanup_v1';

/// Supabase is the source of truth; Drift is the user-scoped offline cache.
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
  Future<void>? _initialization;
  String? _initializingUserId;

  Stream<List<ReminderRow>> watchAll() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return (_db.select(_db.reminders)
            ..where((table) => table.userId.isNull()))
          .watch();
    }
    return (_db.select(_db.reminders)
          ..where((table) => table.userId.equals(userId)))
        .watch();
  }

  /// Serializes initialization across multiple screen instances in the same
  /// process. Database uniqueness remains the cross-device/race safeguard.
  Future<void> initializeForCurrentUser(
    Map<String, ReminderCopy> defaultCopy,
  ) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Future<void>.value();

    final active = _initialization;
    if (active != null && _initializingUserId == userId) return active;

    late final Future<void> operation;
    operation = _runInitialization(defaultCopy).whenComplete(() {
      if (identical(_initialization, operation)) {
        _initialization = null;
        _initializingUserId = null;
      }
    });
    _initializingUserId = userId;
    _initialization = operation;
    return operation;
  }

  Future<void> _runInitialization(
    Map<String, ReminderCopy> defaultCopy,
  ) async {
    debugPrint('[Reminders] initialization started');
    try {
      await _notifications.requestPermission();
      await ensureDefaultRemindersForCurrentUser(defaultCopy);
      await fixLegacyDefaultRemindersDisabled();
      await cleanupGratitudeReminders();
      await syncUnsyncedRemindersToCloud();
      await fetchAndSyncFromSupabase(defaultCopy);
      await reconcileNotifications(defaultCopy);
      debugPrint('[Reminders] initialization completed');
    } catch (error) {
      debugPrint('[Reminders] error: $error');
    }
  }

  /// Creates only cloud defaults that do not already exist for the current
  /// user. Existing rows are never updated, so user settings stay untouched.
  Future<void> ensureDefaultRemindersForCurrentUser(
    Map<String, ReminderCopy> defaultCopy,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _client
          .from('reminders')
          .select('default_key')
          .eq('user_id', userId);
      if (_client.auth.currentUser?.id != userId) return;

      final existingKeys = response
          .map((row) => row['default_key'] as String?)
          .whereType<String>()
          .toSet();
      final missing = defaultReminderDefinitions
          .where((definition) => !existingKeys.contains(definition.defaultKey))
          .toList(growable: false);

      debugPrint(
          '[Reminders] existing defaults: ${existingKeys.toList()..sort()}');
      debugPrint(
        '[Reminders] missing defaults: '
        '${missing.map((definition) => definition.defaultKey).toList()}',
      );

      for (final definition in missing) {
        final copy = defaultCopy[definition.iconKey]!;
        try {
          await _client.from('reminders').insert({
            'user_id': userId,
            'default_key': definition.defaultKey,
            'title': copy.title,
            'icon_key': definition.iconKey,
            'frequency': definition.frequency.name,
            'weekday': definition.weekday,
            'hour': definition.hour,
            'minute': definition.minute,
            'enabled': false,
          });
          debugPrint('[Reminders] inserted default: ${definition.defaultKey}');
        } on PostgrestException catch (error) {
          if (error.code != '23505') rethrow;
          // Another initializer/device won the race. The partial UNIQUE
          // index is the final authority, so this is a successful outcome.
        }
      }
      debugPrint('[Reminders] defaults ensured');
    } catch (error) {
      debugPrint('[Reminders] error: $error');
    }
  }

  Future<void> cleanupGratitudeReminders() async {
    final userId = _client.auth.currentUser?.id;
    final markerSuffix = userId ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();
      final marker = '${_gratitudeCleanupPrefKey}_$markerSuffix';
      if (prefs.getBool(marker) ?? false) return;

      final query = _db.select(_db.reminders)
        ..where((table) {
          final owner = userId == null
              ? table.userId.isNull()
              : table.userId.equals(userId);
          return owner & table.iconKey.equals('heart');
        });
      final rows = await query.get();

      for (final row in rows) {
        await _cancelRowNotifications(row);
        if (row.supabaseId != null && userId != null) {
          try {
            await _client
                .from('reminders')
                .delete()
                .eq('id', row.supabaseId!)
                .eq('user_id', userId);
          } catch (error) {
            debugPrint('[Reminders] error: $error');
          }
        }
        await (_db.delete(_db.reminders)
              ..where((table) => table.id.equals(row.id)))
            .go();
      }

      await prefs.setBool(marker, true);
    } catch (error) {
      debugPrint('[Reminders] error: $error');
    }
  }

  /// Uploads only the current user's pending local rows. Defaults resolve by
  /// `(user_id, default_key)` first; custom reminders retain normal inserts.
  Future<void> syncUnsyncedRemindersToCloud() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final unsyncedRows = await (_db.select(_db.reminders)
            ..where(
              (table) =>
                  table.userId.equals(userId) & table.supabaseId.isNull(),
            ))
          .get();

      for (final row in unsyncedRows) {
        if (_client.auth.currentUser?.id != userId) return;
        String? cloudId;

        if (row.defaultKey != null) {
          cloudId = await _cloudIdForDefault(userId, row.defaultKey!);
          if (cloudId == null) {
            try {
              final inserted = await _client
                  .from('reminders')
                  .insert(_cloudPayload(row, userId: userId))
                  .select('id')
                  .single();
              cloudId = inserted['id']?.toString();
            } on PostgrestException catch (error) {
              if (error.code != '23505') rethrow;
              cloudId = await _cloudIdForDefault(userId, row.defaultKey!);
            }
          }
        } else {
          final inserted = await _client
              .from('reminders')
              .insert(_cloudPayload(row, userId: userId))
              .select('id')
              .single();
          cloudId = inserted['id']?.toString();
        }

        if (cloudId == null || _client.auth.currentUser?.id != userId) {
          continue;
        }
        await (_db.update(_db.reminders)
              ..where(
                (table) =>
                    table.id.equals(row.id) & table.userId.equals(userId),
              ))
            .write(RemindersCompanion(supabaseId: Value(cloudId)));
      }
    } catch (error) {
      debugPrint('[Reminders] error: $error');
    }
  }

  /// One-time safeguard for pre-cloud default rows only. Rows that already
  /// have a stable defaultKey are user data and are never overwritten here.
  Future<void> fixLegacyDefaultRemindersDisabled() async {
    final userId = _client.auth.currentUser?.id;
    final markerSuffix = userId ?? 'guest';
    try {
      final prefs = await SharedPreferences.getInstance();
      final marker = '${_defaultDisabledFixPrefKey}_$markerSuffix';
      if (prefs.getBool(marker) ?? false) return;

      const iconKeys = [
        DefaultReminderIconKeys.morningJournal,
        DefaultReminderIconKeys.breathingBreak,
        DefaultReminderIconKeys.weeklyReflection,
      ];
      final rows = await (_db.select(_db.reminders)
            ..where((table) {
              final owner = userId == null
                  ? table.userId.isNull()
                  : table.userId.equals(userId);
              return owner &
                  table.defaultKey.isNull() &
                  table.iconKey.isIn(iconKeys);
            }))
          .get();

      for (final row in rows.where((item) => item.enabled)) {
        await _cancelRowNotifications(row);
        await (_db.update(_db.reminders)
              ..where((table) => table.id.equals(row.id)))
            .write(const RemindersCompanion(enabled: Value(false)));
      }
      await prefs.setBool(marker, true);
    } catch (error) {
      debugPrint('[Reminders] error: $error');
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
    final userId = _client.auth.currentUser?.id;
    String? cloudId;

    if (userId != null) {
      try {
        final inserted = await _client
            .from('reminders')
            .insert({
              'user_id': userId,
              'default_key': null,
              'title': title,
              'icon_key': customReminderIconKey,
              'frequency': frequency.name,
              'weekday': weekday,
              'hour': hour,
              'minute': minute,
              'enabled': true,
            })
            .select('id')
            .single();
        cloudId = inserted['id']?.toString();
      } catch (error) {
        debugPrint('[Reminders] error: $error');
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
            userId: Value(userId),
            supabaseId: Value(cloudId),
            defaultKey: const Value(null),
          ),
        );
    final row = await (_db.select(_db.reminders)
          ..where((table) => table.id.equals(id)))
        .getSingle();
    await _schedule(
      row,
      ReminderCopy(title: title, body: notificationBody),
    );
  }

  Future<void> setEnabled(
    ReminderRow reminder,
    bool enabled, {
    ReminderCopy? copy,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await (_db.update(_db.reminders)
          ..where((table) => table.id.equals(reminder.id)))
        .write(RemindersCompanion(enabled: Value(enabled)));

    final updated = reminder.copyWith(enabled: enabled);
    if (enabled) {
      if (copy != null) await _schedule(updated, copy);
    } else {
      await _cancelRowNotifications(updated);
    }

    if (userId != null && reminder.supabaseId != null) {
      try {
        await _client
            .from('reminders')
            .update({'enabled': enabled})
            .eq('id', reminder.supabaseId!)
            .eq('user_id', userId);
      } catch (error) {
        debugPrint('[Reminders] error: $error');
      }
    }
  }

  Future<void> delete(ReminderRow reminder) async {
    if (reminder.defaultKey != null) {
      debugPrint(
        '[Reminders] error: system default cannot be deleted: '
        '${reminder.defaultKey}',
      );
      return;
    }

    final userId = _client.auth.currentUser?.id;
    await (_db.delete(_db.reminders)
          ..where((table) => table.id.equals(reminder.id)))
        .go();
    await _cancelRowNotifications(reminder);

    if (userId != null && reminder.supabaseId != null) {
      try {
        await _client
            .from('reminders')
            .delete()
            .eq('id', reminder.supabaseId!)
            .eq('user_id', userId);
      } catch (error) {
        debugPrint('[Reminders] error: $error');
      }
    }
  }

  Future<void> deleteAll() async {
    final rows = await _db.select(_db.reminders).get();
    for (final row in rows) {
      await _cancelRowNotifications(row);
    }
    await _db.delete(_db.reminders).go();
  }

  /// Mirrors the current user's cloud rows into Drift and removes stale or
  /// duplicate local cache rows. Notification state is reconciled afterwards.
  Future<void> fetchAndSyncFromSupabase(
    Map<String, ReminderCopy> defaultCopy,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response =
          await _client.from('reminders').select().eq('user_id', userId);
      debugPrint('[Reminders] cloud fetch count: ${response.length}');
      if (_client.auth.currentUser?.id != userId) return;

      final cloudRows = <String, Map<String, dynamic>>{};
      for (final row in response) {
        final cloudId = row['id']?.toString();
        if (cloudId != null) cloudRows[cloudId] = row;
      }

      var localRows = await (_db.select(_db.reminders)
            ..where((table) => table.userId.equals(userId)))
          .get();
      final cloudIds = cloudRows.keys.toSet();

      for (final local in localRows) {
        final cloudId = local.supabaseId;
        if (cloudId != null && !cloudIds.contains(cloudId)) {
          await _cancelRowNotifications(local);
          await (_db.delete(_db.reminders)
                ..where((table) => table.id.equals(local.id)))
              .go();
        }
      }

      localRows = await (_db.select(_db.reminders)
            ..where((table) => table.userId.equals(userId)))
          .get();
      final consumedLocalIds = <int>{};

      for (final entry in cloudRows.entries) {
        final cloudId = entry.key;
        final row = entry.value;
        final defaultKey = row['default_key'] as String?;
        final candidates = localRows.where((local) {
          if (consumedLocalIds.contains(local.id)) return false;
          if (local.supabaseId == cloudId) return true;
          return defaultKey != null &&
              local.defaultKey == defaultKey &&
              local.supabaseId == null;
        }).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

        final title = row['title'] as String? ?? '';
        final iconKey = row['icon_key'] as String? ?? customReminderIconKey;
        final frequency = ReminderFrequency.values.firstWhere(
          (value) => value.name == (row['frequency'] as String? ?? 'daily'),
          orElse: () => ReminderFrequency.daily,
        );
        final weekday = row['weekday'] as int?;
        final hour = row['hour'] as int? ?? 9;
        final minute = row['minute'] as int? ?? 0;
        final enabled = row['enabled'] as bool? ?? false;

        if (candidates.isEmpty) {
          await _db.into(_db.reminders).insert(
                RemindersCompanion.insert(
                  title: title,
                  iconKey: iconKey,
                  frequency: frequency,
                  weekday: Value(weekday),
                  hour: hour,
                  minute: minute,
                  enabled: Value(enabled),
                  userId: Value(userId),
                  supabaseId: Value(cloudId),
                  defaultKey: Value(defaultKey),
                ),
              );
        } else {
          final keeper = candidates.first;
          consumedLocalIds.add(keeper.id);
          await (_db.update(_db.reminders)
                ..where((table) => table.id.equals(keeper.id)))
              .write(
            RemindersCompanion(
              title: Value(title),
              iconKey: Value(iconKey),
              frequency: Value(frequency),
              weekday: Value(weekday),
              hour: Value(hour),
              minute: Value(minute),
              enabled: Value(enabled),
              userId: Value(userId),
              supabaseId: Value(cloudId),
              defaultKey: Value(defaultKey),
            ),
          );

          for (final duplicate in candidates.skip(1)) {
            consumedLocalIds.add(duplicate.id);
            await _cancelRowNotifications(duplicate);
            await (_db.delete(_db.reminders)
                  ..where((table) => table.id.equals(duplicate.id)))
                .go();
          }
        }
      }

      final localCount = await (_db.select(_db.reminders)
            ..where((table) => table.userId.equals(userId)))
          .get()
          .then((rows) => rows.length);
      debugPrint('[Reminders] local reminder count: $localCount');
    } catch (error) {
      debugPrint('[Reminders] error: $error');
    }
  }

  /// Makes the plugin's pending reminder namespace exactly match the current
  /// user's enabled Drift rows after cloud/local synchronization.
  Future<void> reconcileNotifications(
    Map<String, ReminderCopy> defaultCopy,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rows = await (_db.select(_db.reminders)
            ..where((table) => table.userId.equals(userId)))
          .get();
      final pending = await _notifications.pendingNotificationIds();
      final knownIds = <int>{};
      final ownerByNotificationId = <int, String>{};

      for (final row in rows) {
        final stableIdentity = _notificationIdentity(row);
        final notificationId = reminderNotificationId(stableIdentity);
        final existingOwner = ownerByNotificationId[notificationId];
        if (existingOwner != null && existingOwner != stableIdentity) {
          debugPrint(
            '[Reminders] error: notification id collision '
            '$notificationId ($existingOwner, $stableIdentity)',
          );
          continue;
        }
        ownerByNotificationId[notificationId] = stableIdentity;
        knownIds.add(notificationId);

        // Cancel the pre-v20 raw Drift id when it is still pending. This is
        // limited to ids that are known to belong to current reminder rows.
        if (row.id != notificationId && pending.contains(row.id)) {
          await _cancelNotification(row.id);
        }

        if (row.enabled) {
          final copy = defaultCopy[row.iconKey] ??
              ReminderCopy(title: row.title, body: row.title);
          await _schedule(row, copy);
        } else if (pending.contains(notificationId)) {
          await _cancelNotification(notificationId);
        }
      }

      final orphanIds = pending.where(
        (id) => isReminderNotificationId(id) && !knownIds.contains(id),
      );
      for (final id in orphanIds) {
        await _cancelNotification(id);
      }
    } catch (error) {
      debugPrint('[Reminders] error: $error');
    }
  }

  Future<String?> _cloudIdForDefault(String userId, String defaultKey) async {
    final row = await _client
        .from('reminders')
        .select('id')
        .eq('user_id', userId)
        .eq('default_key', defaultKey)
        .maybeSingle();
    return row?['id']?.toString();
  }

  Map<String, dynamic> _cloudPayload(
    ReminderRow row, {
    required String userId,
  }) {
    return {
      'user_id': userId,
      'default_key': row.defaultKey,
      'title': row.title,
      'icon_key': row.iconKey,
      'frequency': row.frequency.name,
      'weekday': row.weekday,
      'hour': row.hour,
      'minute': row.minute,
      'enabled': row.enabled,
    };
  }

  String _notificationIdentity(ReminderRow row) {
    return row.supabaseId ?? 'local:${row.userId ?? 'guest'}:${row.id}';
  }

  int _notificationId(ReminderRow row) =>
      reminderNotificationId(_notificationIdentity(row));

  Future<void> _schedule(ReminderRow row, ReminderCopy copy) async {
    final id = _notificationId(row);
    await _notifications.schedule(
      id: id,
      title: copy.title,
      body: copy.body,
      frequency: row.frequency,
      weekday: row.weekday,
      hour: row.hour,
      minute: row.minute,
    );
    debugPrint('[Reminders] notification scheduled: $id');
  }

  Future<void> _cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('[Reminders] notification cancelled: $id');
  }

  Future<void> _cancelRowNotifications(ReminderRow row) async {
    final stableId = _notificationId(row);
    await _cancelNotification(stableId);
    if (row.id != stableId) await _cancelNotification(row.id);
  }
}
