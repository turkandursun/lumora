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

/// Small, persistence-free route policy for authentication and registration.
/// A fresh signup is carried by the screen that actually initiated account
/// creation; existing login and restored sessions can never enter onboarding.
abstract final class AuthFlowRoutes {
  static const nameEntry = '/name-entry';
  static const onboarding = '/onboarding';
  static const mood = '/welcome';
  static const hobbiesOnboarding = '/hobbies-onboarding';
  static const greeting = '/greeting';
  static const home = '/home';

  static String afterAuthentication(AuthFlowOrigin origin) => switch (origin) {
        AuthFlowOrigin.freshPasswordSignup => nameEntry,
        AuthFlowOrigin.freshOAuthSignup => nameEntry,
        AuthFlowOrigin.existingLogin || AuthFlowOrigin.restoredSession => mood,
      };

  static String get afterNameEntry => onboarding;

  static String get afterSignupHobbies => greeting;

  static String get afterOnboarding => mood;

  static String afterMood({required bool isNewSignup}) =>
      isNewSignup ? hobbiesOnboarding : greeting;

  static String get afterGreeting => home;

  static bool hasFreshSignupIntent(Object? extra) => extra == true;

  static bool showsOnboarding(AuthFlowOrigin origin) => switch (origin) {
        AuthFlowOrigin.freshPasswordSignup ||
        AuthFlowOrigin.freshOAuthSignup =>
          true,
        AuthFlowOrigin.existingLogin || AuthFlowOrigin.restoredSession => false,
      };

  /// Supabase OAuth does not expose a dedicated "new account" auth event.
  /// The user creation timestamp is therefore used only on the sign-up
  /// screen to distinguish a just-created OAuth account from an existing one.
  static bool isFreshOAuthAccount({
    required String? createdAt,
    DateTime? now,
  }) {
    final created = DateTime.tryParse(createdAt ?? '')?.toUtc();
    if (created == null) return false;
    final difference = (now ?? DateTime.now()).toUtc().difference(created);
    return !difference.isNegative && difference <= const Duration(minutes: 5);
  }
}
