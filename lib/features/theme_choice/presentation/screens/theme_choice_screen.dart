import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../theme/app_theme.dart';

/// SharedPreferences key holding the chosen entry-background theme
/// ('light' = sunset / 'dark' = moon).
const astraThemeKey = 'astra_bg_theme';

/// The full-screen background asset for the chosen theme, defaulting to the
/// dark (moon) scene.
Future<String> astraBackgroundAsset() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(astraThemeKey) == 'light'
      ? 'assets/images/astra_sun_entry_g3.png'
      : 'assets/images/astra_dark.png';
}

/// Shown once at the very start: a small day/night toggle near the top
/// live-previews the light (sunset) or dark (moon) ASTRA scene. Tapping
/// anywhere else continues into the app.
class ThemeChoiceScreen extends StatefulWidget {
  const ThemeChoiceScreen({super.key});

  @override
  State<ThemeChoiceScreen> createState() => _ThemeChoiceScreenState();
}

class _ThemeChoiceScreenState extends State<ThemeChoiceScreen> {
  bool _dark = true;

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(astraThemeKey, _dark ? 'dark' : 'light');
    if (!mounted) return;
    // Go straight to the entry screen (no splash loading page in between) so
    // the shared 'astra_bg' Hero makes it read as one continuous screen where
    // only the sign-in box appears over the same scene.
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    context.go(hasSession ? AppRoutes.welcome : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _confirm,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Shared background element with the login / signup screens, so the
            // transition looks like the same scene with only the box appearing.
            Hero(
              tag: 'astra_bg',
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                // Force each frame to fill the whole screen — without this the
                // image shrinks to its aspect ratio, leaving grey top/bottom bands.
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, if (current != null) current],
                ),
                child: Image.asset(
                  _dark
                      ? 'assets/images/astra_dark.png'
                      : 'assets/images/astra_sun_entry_g3.png',
                  key: ValueKey(_dark),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.14)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    Text(
                      isTr ? 'Temanı seç' : 'Choose your theme',
                      style: AppTheme.bodyFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ).copyWith(shadows: const [
                        Shadow(color: Color(0xAA000000), blurRadius: 8),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    _DayNightToggle(
                      dark: _dark,
                      onChanged: (v) => setState(() => _dark = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact day/night sliding toggle: sun on the light side, moon + stars
/// on the dark side, with a knob that slides between them.
class _DayNightToggle extends StatelessWidget {
  const _DayNightToggle({required this.dark, required this.onChanged});

  final bool dark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const width = 138.0;
    const height = 58.0;
    return GestureDetector(
      onTap: () => onChanged(!dark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: dark ? 0 : 1,
                child: const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.wb_sunny_rounded,
                        color: Color(0xFFFF9A21), size: 26),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: dark ? 1 : 0,
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.nightlight_round,
                            color: Color(0xFFF4D14E), size: 22),
                      ),
                      Positioned(
                        right: 30,
                        top: 12,
                        child: Icon(Icons.star_rounded,
                            color: Color(0xFFF4D14E), size: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              alignment: dark ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.all(6),
                width: height - 12,
                height: height - 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
