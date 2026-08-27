import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has accepted the current privacy policy version.
/// Bump [version] whenever the policy materially changes to re-prompt everyone.
class PrivacyConsent {
  PrivacyConsent._();

  static const int version = 1;

  static String _key(String userId) => 'privacy_accepted_${userId}_v$version';

  /// True if [userId] has already accepted the current policy version.
  static Future<bool> hasAccepted(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_key(userId)) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> accept(String userId) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key(userId), true);
    } catch (_) {}
  }
}
