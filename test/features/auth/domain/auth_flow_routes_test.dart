import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/auth/domain/auth_flow_routes.dart';

void main() {
  group('AuthFlowRoutes', () {
    test('fresh password signup preserves registration then onboarding', () {
      expect(
        AuthFlowRoutes.afterAuthentication(
          AuthFlowOrigin.freshPasswordSignup,
        ),
        AuthFlowRoutes.nameEntry,
      );
      expect(
        AuthFlowRoutes.afterNameEntry,
        AuthFlowRoutes.onboarding,
      );
      expect(
        AuthFlowRoutes.afterOnboarding,
        AuthFlowRoutes.mood,
      );
      expect(
        AuthFlowRoutes.afterMood(isNewSignup: true),
        AuthFlowRoutes.hobbiesOnboarding,
      );
      expect(AuthFlowRoutes.afterSignupHobbies, AuthFlowRoutes.greeting);
      expect(AuthFlowRoutes.afterGreeting, AuthFlowRoutes.home);
      expect(
        AuthFlowRoutes.showsOnboarding(
          AuthFlowOrigin.freshPasswordSignup,
        ),
        isTrue,
      );
    });

    test('fresh OAuth signup preserves profile setup and onboarding', () {
      expect(
        AuthFlowRoutes.afterAuthentication(AuthFlowOrigin.freshOAuthSignup),
        AuthFlowRoutes.nameEntry,
      );
      expect(
        AuthFlowRoutes.showsOnboarding(AuthFlowOrigin.freshOAuthSignup),
        isTrue,
      );
    });

    test('existing login skips onboarding', () {
      expect(
        AuthFlowRoutes.afterAuthentication(AuthFlowOrigin.existingLogin),
        AuthFlowRoutes.mood,
      );
      expect(
        AuthFlowRoutes.showsOnboarding(AuthFlowOrigin.existingLogin),
        isFalse,
      );
      expect(
        AuthFlowRoutes.afterMood(isNewSignup: false),
        AuthFlowRoutes.greeting,
      );
    });

    test('restored session skips onboarding', () {
      expect(
        AuthFlowRoutes.afterAuthentication(AuthFlowOrigin.restoredSession),
        AuthFlowRoutes.mood,
      );
      expect(
        AuthFlowRoutes.showsOnboarding(AuthFlowOrigin.restoredSession),
        isFalse,
      );
    });

    test('registration-only routes require explicit fresh signup intent', () {
      expect(AuthFlowRoutes.hasFreshSignupIntent(true), isTrue);
      expect(AuthFlowRoutes.hasFreshSignupIntent(false), isFalse);
      expect(AuthFlowRoutes.hasFreshSignupIntent(null), isFalse);
    });

    test('only a just-created OAuth account is considered fresh', () {
      final now = DateTime.utc(2026, 8, 12, 12);

      expect(
        AuthFlowRoutes.isFreshOAuthAccount(
          createdAt: now.subtract(const Duration(minutes: 1)).toIso8601String(),
          now: now,
        ),
        isTrue,
      );
      expect(
        AuthFlowRoutes.isFreshOAuthAccount(
          createdAt: now.subtract(const Duration(minutes: 6)).toIso8601String(),
          now: now,
        ),
        isFalse,
      );
      expect(
        AuthFlowRoutes.isFreshOAuthAccount(
          createdAt: now.add(const Duration(seconds: 1)).toIso8601String(),
          now: now,
        ),
        isFalse,
      );
      expect(
        AuthFlowRoutes.isFreshOAuthAccount(
          createdAt: 'not-a-date',
          now: now,
        ),
        isFalse,
      );
    });
  });
}
