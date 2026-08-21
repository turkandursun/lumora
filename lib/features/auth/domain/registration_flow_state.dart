import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RegistrationPreferencesLoader = Future<SharedPreferences> Function();

enum RegistrationStep {
  nameEntry('name_entry'),
  themeSelect('theme_select'),
  storytellingOnboarding('storytelling_onboarding'),
  mood('mood'),
  dailyReflection('daily_reflection'),
  hobbies('hobbies'),
  firstLumaGreeting('first_luma_greeting');

  const RegistrationStep(this.wireValue);

  final String wireValue;

  static RegistrationStep fromWireValue(Object? value) {
    return RegistrationStep.values.firstWhere(
      (step) => step.wireValue == value,
      orElse: () => RegistrationStep.nameEntry,
    );
  }
}

/// Type-safe navigation proof for one step of an authenticated registration.
class FreshRegistrationIntent {
  const FreshRegistrationIntent({
    required this.userId,
    required this.step,
  });

  final String userId;
  final RegistrationStep step;

  bool matches(String expectedUserId, RegistrationStep expectedStep) =>
      userId == expectedUserId && step == expectedStep;
}

/// Owns the single active, user-scoped first-registration journey.
///
/// The persisted marker lets an email-confirmation flow resume after a login,
/// while the synchronous in-memory value lets GoRouter guards make a decision
/// without trusting a client-provided boolean.
class RegistrationFlowStore {
  RegistrationFlowStore({
    RegistrationPreferencesLoader? preferencesLoader,
    DateTime Function()? now,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _now = now ?? DateTime.now;

  static const oauthSignupAttemptKey = 'registration_oauth_signup_attempt_v1';
  static const oauthLoginAttemptKey = 'registration_oauth_login_attempt_v1';
  static const _oauthAttemptTtl = Duration(minutes: 10);

  final RegistrationPreferencesLoader _preferencesLoader;
  final DateTime Function() _now;

  String? _activeUserId;
  RegistrationStep? _activeStep;
  int _restoreGeneration = 0;

  String? get activeUserId => _activeUserId;
  RegistrationStep? get activeStep => _activeStep;

  static String markerKey(String userId) => 'registration_pending_$userId';

  bool hasActiveIntentFor(String userId) =>
      _activeUserId == userId && _activeStep != null;

  bool allows(FreshRegistrationIntent intent) =>
      _activeUserId == intent.userId && _activeStep == intent.step;

  FreshRegistrationIntent? intentFor(String userId) {
    final step = _activeStep;
    if (_activeUserId != userId || step == null) return null;
    return FreshRegistrationIntent(userId: userId, step: step);
  }

  Future<FreshRegistrationIntent> begin(String userId) async {
    _restoreGeneration++;
    _activeUserId = userId;
    _activeStep = RegistrationStep.nameEntry;
    final intent = FreshRegistrationIntent(
      userId: userId,
      step: RegistrationStep.nameEntry,
    );
    await _persistStep(userId, intent.step);
    return intent;
  }

  Future<FreshRegistrationIntent?> restore(String userId) async {
    final generation = ++_restoreGeneration;
    _activeUserId = null;
    _activeStep = null;
    final Object? stored;
    try {
      final prefs = await _preferencesLoader();
      stored = prefs.get(markerKey(userId));
    } catch (error) {
      debugPrint('[RegistrationFlow] Resume marker read failed: $error');
      return null;
    }
    if (generation != _restoreGeneration ||
        stored == null ||
        (stored is bool && !stored)) {
      return null;
    }

    // Older builds may have persisted a boolean marker. A true legacy marker
    // safely resumes at the first authenticated registration step.
    final step = stored is String
        ? RegistrationStep.fromWireValue(stored)
        : RegistrationStep.nameEntry;
    _activeUserId = userId;
    _activeStep = step;
    return FreshRegistrationIntent(userId: userId, step: step);
  }

  Future<FreshRegistrationIntent> advance(
    FreshRegistrationIntent current,
    RegistrationStep nextStep,
  ) async {
    if (!allows(current)) {
      throw const RegistrationIntentMismatchException();
    }
    _activeStep = nextStep;
    final next = FreshRegistrationIntent(
      userId: current.userId,
      step: nextStep,
    );
    await _persistStep(current.userId, nextStep);
    return next;
  }

  Future<void> complete(FreshRegistrationIntent current) async {
    if (!allows(current)) {
      throw const RegistrationIntentMismatchException();
    }
    _restoreGeneration++;
    _activeUserId = null;
    _activeStep = null;
    await _removeMarker(current.userId);
  }

  Future<void> clearForUser(String? userId) async {
    _restoreGeneration++;
    if (userId != null && _activeUserId == userId) {
      _activeUserId = null;
      _activeStep = null;
    }
    try {
      final prefs = await _preferencesLoader();
      if (userId != null) await prefs.remove(markerKey(userId));
      await prefs.remove(oauthSignupAttemptKey);
      await prefs.remove(oauthLoginAttemptKey);
    } catch (error) {
      debugPrint('[RegistrationFlow] Logout marker cleanup failed: $error');
    }
  }

  /// Records only the short-lived origin of an OAuth redirect. It is not a
  /// fresh-registration decision and is consumed exactly once after auth.
  Future<void> markOAuthSignupAttempt() async {
    await _markOAuthAttempt(oauthSignupAttemptKey);
  }

  Future<void> markOAuthLoginAttempt() async {
    await _markOAuthAttempt(oauthLoginAttemptKey);
  }

  Future<void> _markOAuthAttempt(String key) async {
    try {
      final prefs = await _preferencesLoader();
      await prefs.setInt(
        key,
        _now().toUtc().millisecondsSinceEpoch,
      );
    } catch (error) {
      debugPrint('[RegistrationFlow] OAuth origin save failed: $error');
    }
  }

  Future<void> clearOAuthSignupAttempt() async {
    await _clearOAuthAttempt(oauthSignupAttemptKey);
  }

  Future<void> clearOAuthLoginAttempt() async {
    await _clearOAuthAttempt(oauthLoginAttemptKey);
  }

  Future<void> _clearOAuthAttempt(String key) async {
    try {
      final prefs = await _preferencesLoader();
      await prefs.remove(key);
    } catch (error) {
      debugPrint('[RegistrationFlow] OAuth origin cleanup failed: $error');
    }
  }

  Future<bool> consumeOAuthSignupAttempt() async {
    return await consumeOAuthSignupAttemptStartedAt() != null;
  }

  /// Consumes the persisted signup origin and returns when that OAuth attempt
  /// began. The timestamp survives a web full-page redirect and lets the
  /// callback distinguish a user created by this attempt from an older Google
  /// account that merely used the sign-up button to sign in again.
  Future<DateTime?> consumeOAuthSignupAttemptStartedAt() {
    return _consumeOAuthAttemptStartedAt(oauthSignupAttemptKey);
  }

  Future<bool> consumeOAuthLoginAttempt() async {
    return await _consumeOAuthAttemptStartedAt(oauthLoginAttemptKey) != null;
  }

  Future<DateTime?> _consumeOAuthAttemptStartedAt(String key) async {
    final int? startedAtMs;
    try {
      final prefs = await _preferencesLoader();
      startedAtMs = prefs.getInt(key);
      await prefs.remove(key);
    } catch (error) {
      debugPrint('[RegistrationFlow] OAuth origin read failed: $error');
      return null;
    }
    if (startedAtMs == null) return null;
    final startedAt =
        DateTime.fromMillisecondsSinceEpoch(startedAtMs, isUtc: true);
    final age = _now().toUtc().difference(startedAt);
    return !age.isNegative && age <= _oauthAttemptTtl ? startedAt : null;
  }

  Future<void> _persistStep(String userId, RegistrationStep step) async {
    try {
      final prefs = await _preferencesLoader();
      await prefs.setString(markerKey(userId), step.wireValue);
    } catch (error) {
      // In-memory intent remains authoritative for the active process. A local
      // storage failure must not strand an already authenticated user.
      debugPrint('[RegistrationFlow] Step marker save failed: $error');
    }
  }

  Future<void> _removeMarker(String userId) async {
    try {
      final prefs = await _preferencesLoader();
      await prefs.remove(markerKey(userId));
    } catch (error) {
      debugPrint('[RegistrationFlow] Completion marker cleanup failed: $error');
    }
  }
}

class RegistrationIntentMismatchException implements Exception {
  const RegistrationIntentMismatchException();
}

final registrationFlowStore = RegistrationFlowStore();
