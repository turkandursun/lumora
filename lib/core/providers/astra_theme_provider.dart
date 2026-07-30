import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/theme_choice/presentation/screens/theme_choice_screen.dart';

/// Represents the active theme chosen by the user
enum AstraThemeMode {
  dark,  // Moon / Ay Teması (Mor alttonlu)
  light, // Sun / Güneş Teması (Sarı alttonlu)
}

class AstraThemeNotifier extends StateNotifier<AstraThemeMode> {
  AstraThemeNotifier() : super(AstraThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeStr = prefs.getString(astraThemeKey);
      if (themeStr == 'light') {
        state = AstraThemeMode.light;
      } else {
        state = AstraThemeMode.dark;
      }
    } catch (_) {
      state = AstraThemeMode.dark;
    }
  }

  Future<void> setTheme(AstraThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(astraThemeKey, mode == AstraThemeMode.light ? 'light' : 'dark');
  }
}

final astraThemeProvider = StateNotifierProvider<AstraThemeNotifier, AstraThemeMode>((ref) {
  return AstraThemeNotifier();
});
