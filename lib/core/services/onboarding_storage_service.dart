import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists whether the user has already been through onboarding, so
/// the splash screen knows whether to route to onboarding or straight
/// to login on subsequent launches.
class OnboardingStorageService {
  OnboardingStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _onboardingCompleteKey = 'onboarding_completed';

  final FlutterSecureStorage _storage;

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: _onboardingCompleteKey);
    return value == 'true';
  }

  Future<void> setOnboardingComplete() {
    return _storage.write(key: _onboardingCompleteKey, value: 'true');
  }

  /// Explicitly marks onboarding as not completed. Used after sign-up so
  /// a fresh account always sees onboarding, even on a device that
  /// previously had another completed account.
  Future<void> setOnboardingIncomplete() {
    return _storage.write(key: _onboardingCompleteKey, value: 'false');
  }
}
