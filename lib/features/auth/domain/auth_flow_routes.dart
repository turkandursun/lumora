import 'package:flutter/foundation.dart';

import 'registration_flow_state.dart';

/// Explicit origin of an authenticated session.
///
/// Supabase emits `signedIn` for both account creation and normal login, so
/// that event alone must never decide whether onboarding is shown.
enum AuthFlowOrigin {
  freshPasswordSignup,
  freshOAuthSignup,
  existingLogin,
  restoredSession,
}

enum LumaGreetingVariant { preAuth, postSignup, returningUser }

enum MoodFlow { signup, dailyCheckIn }

enum DailyReflectionFlow { signup, dailyCheckIn, standalone }

@immutable
class LumaGreetingRouteData {
  const LumaGreetingRouteData({required this.variant, this.registrationIntent});

  const LumaGreetingRouteData.preAuth()
      : variant = LumaGreetingVariant.preAuth,
        registrationIntent = null;

  const LumaGreetingRouteData.returning()
      : variant = LumaGreetingVariant.returningUser,
        registrationIntent = null;

  final LumaGreetingVariant variant;
  final FreshRegistrationIntent? registrationIntent;
}

@immutable
class MoodRouteData {
  const MoodRouteData(this.flow, {this.registrationIntent});
  final MoodFlow flow;
  final FreshRegistrationIntent? registrationIntent;
}

@immutable
class DailyReflectionRouteData {
  const DailyReflectionRouteData(this.flow, {this.registrationIntent});
  final DailyReflectionFlow flow;
  final FreshRegistrationIntent? registrationIntent;
}

/// Route contract for authentication and the user-scoped registration flow.
abstract final class AuthFlowRoutes {
  static const nameEntry = '/name-entry';
  static const themeSelect = '/theme-select';
  static const onboarding = '/onboarding';
  static const mood = '/welcome';
  static const hobbiesOnboarding = '/hobbies-onboarding';
  static const greeting = '/greeting';
  static const aiRating = '/ai-rating';
  static const onboardingComplete = '/onboarding-complete';
  static const dailyReflection = '/daily-reflection';
  static const home = '/home';

  static String afterAuthentication(AuthFlowOrigin origin) => switch (origin) {
        AuthFlowOrigin.freshPasswordSignup => nameEntry,
        AuthFlowOrigin.freshOAuthSignup => nameEntry,
        AuthFlowOrigin.existingLogin || AuthFlowOrigin.restoredSession => home,
      };

  static String get afterNameEntry => themeSelect;

  static String get afterThemeSelect => onboarding;

  static String get afterSignupHobbies => greeting;

  static String get afterOnboarding => mood;

  static String afterMood({required bool isNewSignup}) => dailyReflection;

  static String get afterSignupDailyReflection => hobbiesOnboarding;

  static String get afterGreeting => home;

  static bool hasFreshSignupIntent(
    Object? extra, {
    String? userId,
    RegistrationStep? step,
  }) {
    if (extra is! FreshRegistrationIntent) return false;
    if (userId != null && extra.userId != userId) return false;
    if (step != null && extra.step != step) return false;
    return true;
  }

  static FreshRegistrationIntent? registrationIntentFromExtra(Object? extra) {
    return switch (extra) {
      FreshRegistrationIntent intent => intent,
      MoodRouteData data => data.registrationIntent,
      DailyReflectionRouteData data => data.registrationIntent,
      LumaGreetingRouteData data => data.registrationIntent,
      _ => null,
    };
  }

  static RegistrationStep? fixedRegistrationStepForRoute(String route) {
    return switch (route) {
      nameEntry => RegistrationStep.nameEntry,
      themeSelect => RegistrationStep.themeSelect,
      onboarding => RegistrationStep.storytellingOnboarding,
      hobbiesOnboarding => RegistrationStep.hobbies,
      _ => null,
    };
  }

  static RegistrationStep? sharedRegistrationStepForRoute(
    String route,
    Object? extra,
  ) {
    return switch (route) {
      mood when extra is MoodRouteData && extra.flow == MoodFlow.signup =>
        RegistrationStep.mood,
      dailyReflection
          when extra is DailyReflectionRouteData &&
              extra.flow == DailyReflectionFlow.signup =>
        RegistrationStep.dailyReflection,
      greeting
          when extra is LumaGreetingRouteData &&
              extra.variant == LumaGreetingVariant.postSignup =>
        RegistrationStep.firstLumaGreeting,
      _ => null,
    };
  }

  /// Pure guard policy used by GoRouter and unit tests.
  ///
  /// [fallbackIntent] is the authoritative in-memory registration intent (from
  /// the flow store). GoRouter re-runs `redirect` on every Supabase auth event
  /// via its refreshListenable, and such a refresh can drop `state.extra`
  /// (notably on mobile, where extra `tokenRefreshed`/`userUpdated` events fire
  /// during signup). Falling back to the store's intent keeps the registration
  /// steps (theme, onboarding, hobbies…) reachable instead of bouncing the user
  /// home when `extra` is momentarily lost.
  static String? registrationGuardRedirect({
    required String route,
    required bool isAuthenticated,
    required String? currentUserId,
    required Object? extra,
    required bool hasMatchingActiveRegistration,
    FreshRegistrationIntent? fallbackIntent,
  }) {
    final requiredStep = fixedRegistrationStepForRoute(route) ??
        sharedRegistrationStepForRoute(route, extra);
    if (requiredStep == null) return null;
    if (!isAuthenticated || currentUserId == null) return '/login';
    final intent = registrationIntentFromExtra(extra) ?? fallbackIntent;
    if (!hasMatchingActiveRegistration ||
        !hasFreshSignupIntent(
          intent,
          userId: currentUserId,
          step: requiredStep,
        )) {
      return home;
    }
    return null;
  }

  static String? greetingGuardRedirect({
    required Object? extra,
    required bool isAuthenticated,
    required bool hasActiveRegistration,
  }) {
    if (extra is! LumaGreetingRouteData) {
      return isAuthenticated ? home : '/login';
    }
    return switch (extra.variant) {
      LumaGreetingVariant.preAuth => isAuthenticated ? home : null,
      LumaGreetingVariant.returningUser =>
        !isAuthenticated ? '/login' : (hasActiveRegistration ? home : null),
      LumaGreetingVariant.postSignup => isAuthenticated ? null : '/login',
    };
  }

  static String routeForRegistrationStep(RegistrationStep step) {
    return switch (step) {
      RegistrationStep.nameEntry => nameEntry,
      RegistrationStep.themeSelect => themeSelect,
      RegistrationStep.storytellingOnboarding => onboarding,
      RegistrationStep.mood => mood,
      RegistrationStep.hobbies => hobbiesOnboarding,
      RegistrationStep.dailyReflection => dailyReflection,
      RegistrationStep.firstLumaGreeting => greeting,
    };
  }

  static Object routeDataForRegistration(FreshRegistrationIntent intent) {
    return switch (intent.step) {
      RegistrationStep.mood =>
        MoodRouteData(MoodFlow.signup, registrationIntent: intent),
      RegistrationStep.dailyReflection => DailyReflectionRouteData(
          DailyReflectionFlow.signup,
          registrationIntent: intent,
        ),
      RegistrationStep.firstLumaGreeting => LumaGreetingRouteData(
          variant: LumaGreetingVariant.postSignup,
          registrationIntent: intent,
        ),
      _ => intent,
    };
  }

  static bool showsOnboarding(AuthFlowOrigin origin) => switch (origin) {
        AuthFlowOrigin.freshPasswordSignup ||
        AuthFlowOrigin.freshOAuthSignup =>
          true,
        AuthFlowOrigin.existingLogin || AuthFlowOrigin.restoredSession => false,
      };

  /// Supabase Flutter does not expose an `isNewUser` flag for OAuth. A signup-
  /// origin attempt is therefore accepted as new only when the server's user
  /// creation and last-sign-in timestamps describe the same first auth event.
  /// Unlike the old "created within five minutes" heuristic, a second login
  /// updates lastSignInAt and no longer restarts onboarding.
  static bool isFirstOAuthAuthentication({
    required String? createdAt,
    required String? lastSignInAt,
  }) {
    final created = DateTime.tryParse(createdAt ?? '')?.toUtc();
    final lastSignIn = DateTime.tryParse(lastSignInAt ?? '')?.toUtc();
    if (created == null || lastSignIn == null) return false;
    return lastSignIn.difference(created).abs() <= const Duration(seconds: 5);
  }
}
