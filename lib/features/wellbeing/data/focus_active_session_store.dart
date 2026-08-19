import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/active_focus_session.dart';

abstract interface class FocusLocalStateStore {
  Future<ActiveFocusSession?> loadActiveSession(String userId);
  Future<void> saveActiveSession(ActiveFocusSession session);
  Future<void> clearActiveSession(String userId);
  Future<int> loadDailyGoal(String userId);
  Future<void> saveDailyGoal(String userId, int goal);
  Future<void> clearLegacyGlobalPreferences();
}

class SharedPreferencesFocusLocalStateStore implements FocusLocalStateStore {
  SharedPreferencesFocusLocalStateStore({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesLoader;

  static String activeSessionKey(String userId) =>
      'focus_active_session_v2_$userId';
  static String dailyGoalKey(String userId) => 'focus_goal_v2_$userId';

  static const legacyGlobalKeys = <String>{
    'focus_last_date',
    'focus_count_today',
    'focus_goal',
    'focus_streak',
    'focus_streak_date',
  };

  @override
  Future<ActiveFocusSession?> loadActiveSession(String userId) async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(activeSessionKey(userId));
    if (raw == null) return null;
    try {
      final session = ActiveFocusSession.fromJson(jsonDecode(raw));
      if (session?.userId == userId) return session;
    } catch (_) {
      // Corrupt device-only timer state must never block the focus feature.
    }
    await preferences.remove(activeSessionKey(userId));
    return null;
  }

  @override
  Future<void> saveActiveSession(ActiveFocusSession session) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(
      activeSessionKey(session.userId),
      jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clearActiveSession(String userId) async {
    final preferences = await _preferencesLoader();
    await preferences.remove(activeSessionKey(userId));
  }

  @override
  Future<int> loadDailyGoal(String userId) async {
    final preferences = await _preferencesLoader();
    return (preferences.getInt(dailyGoalKey(userId)) ?? 5).clamp(1, 12);
  }

  @override
  Future<void> saveDailyGoal(String userId, int goal) async {
    final preferences = await _preferencesLoader();
    await preferences.setInt(dailyGoalKey(userId), goal.clamp(1, 12));
  }

  @override
  Future<void> clearLegacyGlobalPreferences() async {
    final preferences = await _preferencesLoader();
    for (final key in legacyGlobalKeys) {
      await preferences.remove(key);
    }
  }
}
