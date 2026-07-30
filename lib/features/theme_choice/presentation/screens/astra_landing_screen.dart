import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import 'theme_choice_screen.dart';

/// The branded ASTRA entry screen: the chosen full-screen scene (sunset or
/// moon, both with the ASTRA wordmark baked in) that the user taps to head
/// into the login form.
class AstraLandingScreen extends StatefulWidget {
  const AstraLandingScreen({super.key});

  @override
  State<AstraLandingScreen> createState() => _AstraLandingScreenState();
}

class _AstraLandingScreenState extends State<AstraLandingScreen> {
  String _asset = 'assets/images/astra_dark.png';

  @override
  void initState() {
    super.initState();
    astraBackgroundAsset().then((a) {
      if (mounted) setState(() => _asset = a);
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final next = prefs.getString(astraThemeKey) == 'light' ? 'dark' : 'light';
    await prefs.setString(astraThemeKey, next);
    if (!mounted) return;
    setState(() => _asset = next == 'light'
        ? 'assets/images/astra_sun_entry.png'
        : 'assets/images/astra_dark.png');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _asset.contains('dark');
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_asset, fit: BoxFit.cover),
            // Small theme toggle so the user can flip sunset/moon here too.
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.28),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: _toggleTheme,
                  icon: Icon(
                    isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
