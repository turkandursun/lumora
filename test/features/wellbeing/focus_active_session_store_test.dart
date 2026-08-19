import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/wellbeing/data/focus_active_session_store.dart';
import 'package:mindful_journal/features/wellbeing/domain/active_focus_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'focus_last_date': '2026-08-18',
      'focus_count_today': 4,
      'focus_goal': 8,
      'focus_streak': 2,
      'focus_streak_date': '2026-08-18',
    });
  });

  test('active session and daily goal are isolated by user id', () async {
    final store = SharedPreferencesFocusLocalStateStore();
    final now = DateTime.utc(2026, 8, 19, 10);
    await store.saveActiveSession(_session('user-a', now));
    await store.saveDailyGoal('user-a', 8);
    await store.saveDailyGoal('user-b', 3);

    expect((await store.loadActiveSession('user-a'))?.userId, 'user-a');
    expect(await store.loadActiveSession('user-b'), isNull);
    expect(await store.loadDailyGoal('user-a'), 8);
    expect(await store.loadDailyGoal('user-b'), 3);
  });

  test('legacy global focus preferences are removed and never migrated',
      () async {
    final store = SharedPreferencesFocusLocalStateStore();
    await store.clearLegacyGlobalPreferences();
    final preferences = await SharedPreferences.getInstance();

    for (final key in SharedPreferencesFocusLocalStateStore.legacyGlobalKeys) {
      expect(preferences.get(key), isNull);
    }
    expect(await store.loadDailyGoal('new-user'), 5);
  });

  test('corrupt or cross-account active state is rejected', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      SharedPreferencesFocusLocalStateStore.activeSessionKey('user-b'),
      '{bad json',
    );
    final store = SharedPreferencesFocusLocalStateStore();

    expect(await store.loadActiveSession('user-b'), isNull);
    expect(
      preferences.getString(
        SharedPreferencesFocusLocalStateStore.activeSessionKey('user-b'),
      ),
      isNull,
    );
  });

  test('daily goal is constrained to the supported 1-12 range', () async {
    final store = SharedPreferencesFocusLocalStateStore();
    await store.saveDailyGoal('user-a', 99);
    expect(await store.loadDailyGoal('user-a'), 12);
  });
}

ActiveFocusSession _session(String userId, DateTime now) => ActiveFocusSession(
      sessionUuid: 'session-id',
      userId: userId,
      phase: FocusPhase.focus,
      focusDurationSeconds: 1500,
      breakDurationSeconds: 300,
      phaseStartedAt: now,
      targetEndAt: now.add(const Duration(minutes: 25)),
      accumulatedPausedSeconds: 0,
      round: 1,
      taskLabel: 'Read',
      notificationTitle: 'title',
      notificationBody: 'body',
    );
