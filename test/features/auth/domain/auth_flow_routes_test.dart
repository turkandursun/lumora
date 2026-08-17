import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/auth/domain/auth_flow_routes.dart';
import 'package:mindful_journal/features/auth/domain/registration_flow_state.dart';

void main() {
  group('AuthFlowRoutes contract', () {
    test('new registration follows the complete product sequence', () {
      expect(
        AuthFlowRoutes.afterAuthentication(
          AuthFlowOrigin.freshPasswordSignup,
        ),
        AuthFlowRoutes.nameEntry,
      );
      expect(AuthFlowRoutes.afterNameEntry, AuthFlowRoutes.themeSelect);
      expect(AuthFlowRoutes.afterThemeSelect, AuthFlowRoutes.onboarding);
      expect(AuthFlowRoutes.afterOnboarding, AuthFlowRoutes.mood);
      expect(
        AuthFlowRoutes.afterMood(isNewSignup: true),
        AuthFlowRoutes.dailyReflection,
      );
      expect(
        AuthFlowRoutes.afterSignupDailyReflection,
        AuthFlowRoutes.hobbiesOnboarding,
      );
      expect(
        AuthFlowRoutes.afterSignupHobbies,
        AuthFlowRoutes.greeting,
      );
      expect(AuthFlowRoutes.afterGreeting, AuthFlowRoutes.home);
    });

    test('fresh OAuth signup starts the same registration flow', () {
      expect(
        AuthFlowRoutes.afterAuthentication(AuthFlowOrigin.freshOAuthSignup),
        AuthFlowRoutes.nameEntry,
      );
      expect(
        AuthFlowRoutes.showsOnboarding(AuthFlowOrigin.freshOAuthSignup),
        isTrue,
      );
    });

    test('existing login and restored session both go directly Home', () {
      expect(
        AuthFlowRoutes.afterAuthentication(AuthFlowOrigin.existingLogin),
        AuthFlowRoutes.home,
      );
      expect(
        AuthFlowRoutes.afterAuthentication(AuthFlowOrigin.restoredSession),
        AuthFlowRoutes.home,
      );
      expect(
        AuthFlowRoutes.showsOnboarding(AuthFlowOrigin.existingLogin),
        isFalse,
      );
      expect(
        AuthFlowRoutes.showsOnboarding(AuthFlowOrigin.restoredSession),
        isFalse,
      );
    });

    test('daily mood always continues to reason before Home', () {
      expect(
        AuthFlowRoutes.afterMood(isNewSignup: false),
        AuthFlowRoutes.dailyReflection,
      );
      expect(
        AuthFlowRoutes.sharedRegistrationStepForRoute(
          AuthFlowRoutes.dailyReflection,
          null,
        ),
        isNull,
      );
    });

    test('typed registration route data preserves the corrected sequence', () {
      const moodIntent = FreshRegistrationIntent(
        userId: 'user-a',
        step: RegistrationStep.mood,
      );
      const reflectionIntent = FreshRegistrationIntent(
        userId: 'user-a',
        step: RegistrationStep.dailyReflection,
      );
      const greetingIntent = FreshRegistrationIntent(
        userId: 'user-a',
        step: RegistrationStep.firstLumaGreeting,
      );
      expect(
        AuthFlowRoutes.routeDataForRegistration(moodIntent),
        isA<MoodRouteData>()
            .having((data) => data.flow, 'flow', MoodFlow.signup),
      );
      expect(
        AuthFlowRoutes.routeDataForRegistration(reflectionIntent),
        isA<DailyReflectionRouteData>().having(
          (data) => data.flow,
          'flow',
          DailyReflectionFlow.signup,
        ),
      );
      expect(
        AuthFlowRoutes.routeDataForRegistration(greetingIntent),
        isA<LumaGreetingRouteData>().having(
          (data) => data.variant,
          'variant',
          LumaGreetingVariant.postSignup,
        ),
      );
    });

    test('registration step maps to the expected route', () {
      expect(
        AuthFlowRoutes.routeForRegistrationStep(RegistrationStep.nameEntry),
        AuthFlowRoutes.nameEntry,
      );
      expect(
        AuthFlowRoutes.routeForRegistrationStep(RegistrationStep.themeSelect),
        AuthFlowRoutes.themeSelect,
      );
      expect(
        AuthFlowRoutes.routeForRegistrationStep(
          RegistrationStep.storytellingOnboarding,
        ),
        AuthFlowRoutes.onboarding,
      );
      expect(
        AuthFlowRoutes.routeForRegistrationStep(RegistrationStep.mood),
        AuthFlowRoutes.mood,
      );
      expect(
        AuthFlowRoutes.routeForRegistrationStep(RegistrationStep.hobbies),
        AuthFlowRoutes.hobbiesOnboarding,
      );
      expect(
        AuthFlowRoutes.routeForRegistrationStep(
          RegistrationStep.dailyReflection,
        ),
        AuthFlowRoutes.dailyReflection,
      );
      expect(
        AuthFlowRoutes.routeForRegistrationStep(
          RegistrationStep.firstLumaGreeting,
        ),
        AuthFlowRoutes.greeting,
      );
    });
  });

  group('registration route guards', () {
    const themeIntent = FreshRegistrationIntent(
      userId: 'user-a',
      step: RegistrationStep.themeSelect,
    );

    test('no-session theme access redirects to auth entry', () {
      expect(
        AuthFlowRoutes.registrationGuardRedirect(
          route: AuthFlowRoutes.themeSelect,
          isAuthenticated: false,
          currentUserId: null,
          extra: themeIntent,
          hasMatchingActiveRegistration: false,
        ),
        '/login',
      );
    });

    test('existing authenticated user cannot enter theme select', () {
      expect(
        AuthFlowRoutes.registrationGuardRedirect(
          route: AuthFlowRoutes.themeSelect,
          isAuthenticated: true,
          currentUserId: 'user-a',
          extra: null,
          hasMatchingActiveRegistration: false,
        ),
        AuthFlowRoutes.home,
      );
    });

    test('matching user, step and active intent allow theme select', () {
      expect(
        AuthFlowRoutes.registrationGuardRedirect(
          route: AuthFlowRoutes.themeSelect,
          isAuthenticated: true,
          currentUserId: 'user-a',
          extra: themeIntent,
          hasMatchingActiveRegistration: true,
        ),
        isNull,
      );
    });

    test('user A intent cannot authorize user B', () {
      expect(
        AuthFlowRoutes.registrationGuardRedirect(
          route: AuthFlowRoutes.themeSelect,
          isAuthenticated: true,
          currentUserId: 'user-b',
          extra: themeIntent,
          hasMatchingActiveRegistration: true,
        ),
        AuthFlowRoutes.home,
      );
    });

    test('wrong registration step cannot jump forward', () {
      expect(
        AuthFlowRoutes.registrationGuardRedirect(
          route: AuthFlowRoutes.hobbiesOnboarding,
          isAuthenticated: true,
          currentUserId: 'user-a',
          extra: themeIntent,
          hasMatchingActiveRegistration: true,
        ),
        AuthFlowRoutes.home,
      );
    });

    test('standalone daily reflection is not treated as onboarding', () {
      expect(
        AuthFlowRoutes.registrationGuardRedirect(
          route: AuthFlowRoutes.dailyReflection,
          isAuthenticated: true,
          currentUserId: 'user-a',
          extra: null,
          hasMatchingActiveRegistration: false,
        ),
        isNull,
      );
    });
  });

  group('LUMA greeting variants', () {
    test('pre-auth greeting needs no session and authenticated users skip it',
        () {
      expect(
        AuthFlowRoutes.greetingGuardRedirect(
          extra: const LumaGreetingRouteData.preAuth(),
          isAuthenticated: false,
          hasActiveRegistration: false,
        ),
        isNull,
      );
      expect(
        AuthFlowRoutes.greetingGuardRedirect(
          extra: const LumaGreetingRouteData.preAuth(),
          isAuthenticated: true,
          hasActiveRegistration: false,
        ),
        AuthFlowRoutes.home,
      );
    });

    test('returning greeting requires auth but not registration intent', () {
      expect(
        AuthFlowRoutes.greetingGuardRedirect(
          extra: const LumaGreetingRouteData.returning(),
          isAuthenticated: false,
          hasActiveRegistration: false,
        ),
        '/login',
      );
      expect(
        AuthFlowRoutes.greetingGuardRedirect(
          extra: const LumaGreetingRouteData.returning(),
          isAuthenticated: true,
          hasActiveRegistration: false,
        ),
        isNull,
      );
    });

    test('post-signup carries the exact user-scoped registration intent', () {
      const intent = FreshRegistrationIntent(
        userId: 'user-a',
        step: RegistrationStep.firstLumaGreeting,
      );
      const data = LumaGreetingRouteData(
        variant: LumaGreetingVariant.postSignup,
        registrationIntent: intent,
      );
      expect(
        AuthFlowRoutes.registrationIntentFromExtra(data),
        same(intent),
      );
    });
  });

  group('OAuth account classification', () {
    test('only the server first-auth timestamp pair is considered new', () {
      final created = DateTime.utc(2026, 8, 17, 12);
      expect(
        AuthFlowRoutes.isFirstOAuthAuthentication(
          createdAt: created.toIso8601String(),
          lastSignInAt:
              created.add(const Duration(seconds: 2)).toIso8601String(),
        ),
        isTrue,
      );
      expect(
        AuthFlowRoutes.isFirstOAuthAuthentication(
          createdAt: created.toIso8601String(),
          lastSignInAt:
              created.add(const Duration(seconds: 20)).toIso8601String(),
        ),
        isFalse,
      );
      expect(
        AuthFlowRoutes.isFirstOAuthAuthentication(
          createdAt: created.toIso8601String(),
          lastSignInAt: null,
        ),
        isFalse,
      );
    });
  });
}
