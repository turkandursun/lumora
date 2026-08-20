import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/calendar/data/period_repository.dart';
import '../../features/calendar/data/symptom_repository.dart';
import '../../features/wellbeing/data/focus_active_session_store.dart';
import '../../features/wellbeing/domain/active_focus_session.dart';
import '../database/app_database.dart';
import 'focus_notification_ids.dart';
import 'reminder_notification_ids.dart';
import 'reminder_notifier.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

/// Removes only one account's local cache after logout or permanent deletion.
///
/// Global catalogue/device preferences (quotes, LUMA sound, breathing mode)
/// are intentionally retained. Legacy preferences that contain user data but
/// have no user id are removed because they cannot be safely attributed to a
/// different account.
class LocalUserDataCleanupService {
  LocalUserDataCleanupService({
    required AppDatabase database,
    required ReminderNotifier notifications,
    SharedPreferencesLoader? preferencesLoader,
  })  : _db = database,
        _notifications = notifications,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final AppDatabase _db;
  final ReminderNotifier _notifications;
  final SharedPreferencesLoader _preferencesLoader;

  Future<void> clearDeletedAccount(String userId) {
    return _clear(userId, includeGoals: true);
  }

  Future<void> clearSignedOutAccount(String userId) {
    // Goal rows can contain offline pending work and are intentionally retained
    // on ordinary logout. Permanent account deletion removes them as well.
    return _clear(userId, includeGoals: false);
  }

  Future<void> _clear(
    String userId, {
    required bool includeGoals,
  }) async {
    final reminderRows = await (_db.select(_db.reminders)
          ..where((table) => table.userId.equals(userId)))
        .get();
    for (final row in reminderRows) {
      final identity =
          row.supabaseId ?? 'local:${row.userId ?? 'guest'}:${row.id}';
      final stableId = reminderNotificationId(identity);
      await _notifications.cancel(stableId);
      if (row.id != stableId) await _notifications.cancel(row.id);
    }

    await _db.transaction(() async {
      await (_db.delete(_db.reminders)
            ..where((table) => table.userId.equals(userId)))
          .go();
      if (includeGoals) {
        await (_db.delete(_db.goals)
              ..where((table) => table.userId.equals(userId)))
            .go();
        await (_db.delete(_db.focusSessions)
              ..where((table) => table.userId.equals(userId)))
            .go();
      }
      await (_db.delete(_db.dreams)
            ..where((table) => table.userId.equals(userId)))
          .go();
      await (_db.delete(_db.journalEntries)
            ..where((table) => table.userId.equals(userId)))
          .go();
      await (_db.delete(_db.activities)
            ..where((table) => table.userId.equals(userId)))
          .go();
      await (_db.delete(_db.letters)
            ..where((table) => table.userId.equals(userId)))
          .go();
      await (_db.delete(_db.quoteFavorites)
            ..where((table) => table.userId.equals(userId)))
          .go();

      // This legacy table has no ownership column. Auth transitions already
      // treat it as current-account-only, so keeping it would leak answers to
      // the next account on this device.
      await _db.delete(_db.dailyQuestionAnswers).go();
    });

    await _clearPreferences(
      userId,
      removeDurableAccountCache: includeGoals,
    );
  }

  Future<void> _clearPreferences(
    String userId, {
    required bool removeDurableAccountCache,
  }) async {
    final prefs = await _preferencesLoader();
    const unscopedUserDataKeys = <String>{
      'activities_v1',
      'letters_v1',
      'mood_log_v1',
      'period_days_v1',
      'period_symptoms_v1',
      'journal_streak_count',
      'journal_streak_last_entry_date',
      'rewards_seen_badges_v1',
      'rewards_seen_level_v1',
      'favorite_quote_ids',
      'streak_banner_shown_date',
      'hobbies_v1',
      'hobbies_onboarded_v1',
      'reminders_seeded',
      'goals_seeded',
      'journal_entry_photos',
      'cloud_synced_marker_v1',
      // Owner is unknowable; never migrate this global palette cache.
      'astra_palette_id_v1',
      'registration_oauth_signup_attempt_v1',
      'focus_last_date',
      'focus_count_today',
      'focus_goal',
      'focus_streak',
      'focus_streak_date',
    };
    final scopedKeys = <String>{
      'astra_bg_theme_$userId',
      'hobbies_${userId}_v1',
      'hobbies_onboarded_v1_$userId',
      'quote_favorites_migrated_v1_$userId',
      'goals_streak_count_$userId',
      'goals_streak_last_active_date_$userId',
      'visit_last_date_v1_$userId',
      'reminders_seeded_$userId',
      'goals_seeded_$userId',
      'pending_onboarding_$userId',
      'registration_pending_$userId',
      'mood_log_v2_$userId',
      'reminders_gratitude_cleanup_v1_$userId',
      'reminders_default_disabled_fix_v1_$userId',
      SharedPreferencesFocusLocalStateStore.activeSessionKey(userId),
    };

    if (removeDurableAccountCache) {
      scopedKeys.add('astra_palette_id_v2_$userId');
      scopedKeys.add(periodDaysStorageKey(userId));
      scopedKeys.add(periodSymptomsStorageKey(userId));
      scopedKeys.add(
        SharedPreferencesFocusLocalStateStore.dailyGoalKey(userId),
      );
    }

    final activeRaw = prefs.getString(
      SharedPreferencesFocusLocalStateStore.activeSessionKey(userId),
    );
    if (activeRaw != null) {
      try {
        final active = ActiveFocusSession.fromJson(jsonDecode(activeRaw));
        if (active != null && active.userId == userId) {
          await _notifications.cancel(
            focusNotificationId('$userId:${active.sessionUuid}'),
          );
        }
      } catch (_) {
        // Corrupt timer state is removed below and has no trusted identity.
      }
    }

    for (final key in {...unscopedUserDataKeys, ...scopedKeys}) {
      await prefs.remove(key);
    }
    if (prefs.getString('cloud_last_user_id') == userId) {
      await prefs.remove('cloud_last_user_id');
    }
  }
}
