import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/database/tables/goals_table.dart';
import 'package:mindful_journal/core/database/tables/reminders_table.dart';
import 'package:mindful_journal/core/services/local_user_data_cleanup_service.dart';
import 'package:mindful_journal/core/services/focus_notification_ids.dart';
import 'package:mindful_journal/core/services/reminder_notification_ids.dart';
import 'package:mindful_journal/core/services/reminder_notifier.dart';
import 'package:mindful_journal/features/wellbeing/domain/active_focus_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late _FakeReminderNotifier notifier;
  late LocalUserDataCleanupService cleaner;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'mood_log_v1': <String>['private'],
      'period_days_v1': <String>['2026-08-12'],
      'period_days_v2_user-a': <String>['2026-08-12T00:00:00.000'],
      'period_days_v2_user-b': <String>['2026-08-13T00:00:00.000'],
      'period_symptoms_v2_user-a': <String>['2026-08-12:cramps'],
      'period_symptoms_v2_user-b': <String>['2026-08-13:headache'],
      'journal_streak_count': 5,
      'astra_bg_theme_user-a': 'dark',
      'astra_bg_theme_user-b': 'light',
      'astra_palette_id_v1': 'berrySand',
      'astra_palette_id_v2_user-a': 'berry_sand',
      'astra_palette_id_v2_user-b': 'sage_veil',
      'hobbies_user-a_v1': <String>['reading'],
      'hobbies_user-b_v1': <String>['walking'],
      'quote_favorites_migrated_v1_user-a': true,
      'quote_favorites_migrated_v1_user-b': true,
      'goals_streak_count_user-a': 3,
      'goals_streak_count_user-b': 4,
      'visit_last_date_v1_user-a': '2026-08-12',
      'cloud_last_user_id': 'user-a',
      'cloud_synced_marker_v1': 'now',
      'registration_oauth_signup_attempt_v1': 123,
      'focus_last_date': '2026-08-12',
      'focus_count_today': 2,
      'focus_goal': 4,
      'focus_streak': 3,
      'focus_streak_date': '2026-08-12',
      'focus_goal_v2_user-a': 6,
      'focus_goal_v2_user-b': 3,
      'focus_active_session_v2_user-a': jsonEncode(
        _activeSession('user-a').toJson(),
      ),
      'luma_ambient_sound_muted': true,
      'breathing_last_mode': 'box',
    });
    database = AppDatabase.forTesting(NativeDatabase.memory());
    notifier = _FakeReminderNotifier();
    cleaner = LocalUserDataCleanupService(
      database: database,
      notifications: notifier,
    );
  });

  tearDown(() => database.close());

  test('permanent deletion clears user A rows but preserves user B and quotes',
      () async {
    await _seedAccount(database, 'user-a', cloudSuffix: 'a');
    await _seedAccount(database, 'user-b', cloudSuffix: 'b');
    await database.into(database.dailyQuestionAnswers).insert(
          DailyQuestionAnswersCompanion.insert(
            date: DateTime(2026, 8, 12),
            questionIndex: 1,
            answerText: 'legacy answer',
            createdAt: DateTime(2026, 8, 12),
            updatedAt: DateTime(2026, 8, 12),
          ),
        );
    await database.into(database.quotes).insert(
          QuotesCompanion.insert(
            id: 'fq_global',
            textTr: 'Söz',
            textEn: 'Quote',
            isActive: true,
            source: 'famous',
            updatedAt: DateTime(2026, 8, 12),
          ),
        );

    final userAReminder = (await (database.select(database.reminders)
          ..where((table) => table.userId.equals('user-a')))
        .getSingle());
    await cleaner.clearDeletedAccount('user-a');

    expect(await _countOwnedRows(database, 'user-a'), everyElement(0));
    expect(await _countOwnedRows(database, 'user-b'), everyElement(1));
    expect(await database.select(database.dailyQuestionAnswers).get(), isEmpty);
    expect(await database.select(database.quotes).get(), hasLength(1));
    expect(
      notifier.cancelled,
      contains(reminderNotificationId(userAReminder.supabaseId!)),
    );
    expect(notifier.cancelled, contains(userAReminder.id));
    expect(
      notifier.cancelled,
      contains(focusNotificationId('user-a:active-focus-a')),
    );
  });

  test('account preferences are cleared without deleting device preferences',
      () async {
    await cleaner.clearDeletedAccount('user-a');
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.get('mood_log_v1'), isNull);
    expect(prefs.get('period_days_v1'), isNull);
    expect(prefs.get('period_days_v2_user-a'), isNull);
    expect(prefs.get('period_symptoms_v2_user-a'), isNull);
    expect(prefs.get('journal_streak_count'), isNull);
    expect(prefs.get('astra_bg_theme_user-a'), isNull);
    expect(prefs.get('astra_palette_id_v1'), isNull);
    expect(prefs.get('astra_palette_id_v2_user-a'), isNull);
    expect(prefs.get('hobbies_user-a_v1'), isNull);
    expect(prefs.get('quote_favorites_migrated_v1_user-a'), isNull);
    expect(prefs.get('goals_streak_count_user-a'), isNull);
    expect(prefs.get('visit_last_date_v1_user-a'), isNull);
    expect(prefs.get('cloud_last_user_id'), isNull);
    expect(prefs.get('cloud_synced_marker_v1'), isNull);
    expect(prefs.get('registration_oauth_signup_attempt_v1'), isNull);
    expect(prefs.get('focus_last_date'), isNull);
    expect(prefs.get('focus_count_today'), isNull);
    expect(prefs.get('focus_goal'), isNull);
    expect(prefs.get('focus_streak'), isNull);
    expect(prefs.get('focus_streak_date'), isNull);
    expect(prefs.get('focus_goal_v2_user-a'), isNull);
    expect(prefs.get('focus_active_session_v2_user-a'), isNull);

    expect(prefs.getString('astra_bg_theme_user-b'), 'light');
    expect(prefs.getString('astra_palette_id_v2_user-b'), 'sage_veil');
    expect(prefs.getStringList('hobbies_user-b_v1'), ['walking']);
    expect(
      prefs.getStringList('period_days_v2_user-b'),
      ['2026-08-13T00:00:00.000'],
    );
    expect(
      prefs.getStringList('period_symptoms_v2_user-b'),
      ['2026-08-13:headache'],
    );
    expect(prefs.getBool('quote_favorites_migrated_v1_user-b'), true);
    expect(prefs.getInt('goals_streak_count_user-b'), 4);
    expect(prefs.getInt('focus_goal_v2_user-b'), 3);
    expect(prefs.getBool('luma_ambient_sound_muted'), true);
    expect(prefs.getString('breathing_last_mode'), 'box');
  });

  test('ordinary logout keeps current user pending goals', () async {
    await _seedAccount(database, 'user-a', cloudSuffix: 'a');
    await cleaner.clearSignedOutAccount('user-a');

    final goals = await (database.select(database.goals)
          ..where((table) => table.userId.equals('user-a')))
        .get();
    expect(goals, hasLength(1));
    expect(goals.single.syncState, 'pending');
    expect(
      await (database.select(database.focusSessions)
            ..where((table) => table.userId.equals('user-a')))
          .get(),
      hasLength(1),
    );
    expect(
      await (database.select(database.journalEntries)
            ..where((table) => table.userId.equals('user-a')))
          .get(),
      isEmpty,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get('focus_active_session_v2_user-a'), isNull);
    expect(prefs.getInt('focus_goal_v2_user-a'), 6);
    expect(
      prefs.getStringList('period_days_v2_user-a'),
      ['2026-08-12T00:00:00.000'],
    );
    expect(
      prefs.getStringList('period_symptoms_v2_user-a'),
      ['2026-08-12:cramps'],
    );
  });

  test('ordinary logout retains the scoped palette fast cache', () async {
    await cleaner.clearSignedOutAccount('user-a');
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.get('astra_palette_id_v1'), isNull);
    expect(prefs.getString('astra_palette_id_v2_user-a'), 'berry_sand');
    expect(prefs.getString('astra_palette_id_v2_user-b'), 'sage_veil');
  });
}

Future<void> _seedAccount(
  AppDatabase database,
  String userId, {
  required String cloudSuffix,
}) async {
  final now = DateTime(2026, 8, 12);
  await database.into(database.reminders).insert(
        RemindersCompanion.insert(
          title: 'Reminder',
          iconKey: 'custom',
          frequency: ReminderFrequency.daily,
          hour: 9,
          minute: 0,
          userId: Value(userId),
          supabaseId: Value('reminder-$cloudSuffix'),
        ),
      );
  await database.into(database.goals).insert(
        GoalsCompanion.insert(
          title: 'Goal',
          iconKey: 'custom',
          unit: GoalUnit.custom,
          target: 1,
          frequency: GoalFrequency.daily,
          periodStart: now,
          userId: Value(userId),
          supabaseId: Value('goal-$cloudSuffix'),
          syncState: const Value('pending'),
        ),
      );
  await database.into(database.focusSessions).insert(
        FocusSessionsCompanion.insert(
          sessionUuid: 'focus-$cloudSuffix',
          userId: userId,
          plannedDurationSeconds: 1500,
          actualDurationSeconds: 1500,
          startedAt: now,
          endedAt: now.add(const Duration(minutes: 25)),
        ),
      );
  await database.into(database.dreams).insert(
        DreamsCompanion.insert(
          date: now,
          content: 'Dream',
          userId: Value(userId),
          supabaseId: Value('dream-$cloudSuffix'),
        ),
      );
  await database.into(database.journalEntries).insert(
        JournalEntriesCompanion.insert(
          createdAt: now,
          content: 'Journal',
          userId: Value(userId),
          supabaseId: Value('journal-$cloudSuffix'),
        ),
      );
  await database.into(database.activities).insert(
        ActivitiesCompanion.insert(
          createdAt: now,
          activityIdsJson: '[]',
          activityText: 'Activity',
          userId: Value(userId),
          supabaseId: Value('activity-$cloudSuffix'),
        ),
      );
  await database.into(database.letters).insert(
        LettersCompanion.insert(
          createdAt: now,
          openAt: now,
          title: 'Letter',
          body: 'Body',
          userId: Value(userId),
          supabaseId: Value('letter-$cloudSuffix'),
        ),
      );
  await database.into(database.quoteFavorites).insert(
        QuoteFavoritesCompanion.insert(
          userId: userId,
          quoteId: 'fq_$cloudSuffix',
          isFavorite: true,
          syncState: 'synced',
          changedAt: now,
        ),
      );
}

Future<List<int>> _countOwnedRows(AppDatabase database, String userId) async {
  return [
    (await (database.select(database.reminders)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.goals)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.focusSessions)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.dreams)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.journalEntries)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.activities)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.letters)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
    (await (database.select(database.quoteFavorites)
              ..where((table) => table.userId.equals(userId)))
            .get())
        .length,
  ];
}

ActiveFocusSession _activeSession(String userId) {
  final now = DateTime.utc(2026, 8, 12, 10);
  return ActiveFocusSession(
    sessionUuid: 'active-focus-a',
    userId: userId,
    phase: FocusPhase.focus,
    focusDurationSeconds: 1500,
    breakDurationSeconds: 300,
    phaseStartedAt: now,
    targetEndAt: now.add(const Duration(minutes: 25)),
    accumulatedPausedSeconds: 0,
    round: 1,
    notificationTitle: 'title',
    notificationBody: 'body',
  );
}

class _FakeReminderNotifier implements ReminderNotifier {
  final cancelled = <int>[];

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<Set<int>> pendingNotificationIds() async => const {};

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required ReminderFrequency frequency,
    int? weekday,
    required int hour,
    required int minute,
  }) async {}
}
