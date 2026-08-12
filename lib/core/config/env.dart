/// Supabase environment configuration.
///
/// Values are supplied at build/run time so no secrets are committed,
/// e.g.:
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///                --dart-define=SUPABASE_ANON_KEY=your-anon-key
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qlluvbcupscxsygyiiyk.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_kR9QlrVrHkG0sjxsGBMXiw_YmG46C9e',
  );

  /// Deep link that Supabase redirects back to after a native (Android/iOS)
  /// Google OAuth sign-in. Must exactly match:
  ///   • the intent-filter scheme/host in android/app/src/main/AndroidManifest.xml
  ///   • the iOS CFBundleURLSchemes entry in ios/Runner/Info.plist
  ///   • a Redirect URL registered in the Supabase dashboard
  ///     (Authentication → URL Configuration → Redirect URLs)
  /// On web this is unused — Supabase returns to the site URL instead.
  static const oauthNativeRedirect = 'lumora://login-callback/';
}
