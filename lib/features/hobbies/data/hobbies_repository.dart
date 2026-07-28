import 'package:shared_preferences/shared_preferences.dart';

const _hobbiesKey = 'hobbies_v1';
const _onboardedKey = 'hobbies_onboarded_v1';

/// On-device store for the user's chosen hobbies — a set of ids (preset ids
/// like `reading`, or the free-text a user typed for a custom hobby).
class HobbiesRepository {
  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hobbiesKey) ?? const []).toSet();
  }

  Future<void> save(Set<String> hobbies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hobbiesKey, hobbies.toList());
  }

  /// Whether the user has already been through the one-time hobby prompt.
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  Future<void> setOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }
}

