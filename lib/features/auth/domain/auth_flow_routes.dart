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
        // Existing users (fresh login or a restored session on app open) now
        // land on Luma's "I missed you" greeting first; it then hands off to
        // the daily mood check-in (which self-gates to once per day).
        // Theme + onboarding now happen BEFORE auth, so after authenticating
        // we go straight to the daily mood check-in.
        AuthFlowOrigin.existingLogin || AuthFlowOrigin.restoredSession => mood,
      };

  // Sign-up: after the nickname → mood check-in.
  static String get afterNameEntry => mood;

  static String get afterSignupHobbies => greeting;

  static String get afterOnboarding => mood;

  // After the mood check-in everyone gets the "why do you feel this way today?"
  // reflection screen, then Home.
  static String afterMood({required bool isNewSignup}) => dailyReflection;

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
