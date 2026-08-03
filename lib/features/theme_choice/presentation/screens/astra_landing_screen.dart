import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';

/// The branded ASTRA entry screen: the chosen full-screen scene (sunset or
/// moon, both with the ASTRA wordmark baked in) that the user taps to head
/// into the login form. Shares its background image and a Hero tag with
/// [LoginScreen]/[SignupScreen] so tapping through reads as one continuous
/// page rather than a jump between two screens.
class AstraLandingScreen extends ConsumerWidget {
  const AstraLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final asset = isDark ? 'assets/images/astra_dark.png' : 'assets/images/astra_sun_entry_g3.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'astra_bg',
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
            // Small theme toggle so the user can flip sunset/moon here too.
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.28),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => ref
                      .read(astraThemeProvider.notifier)
                      .setTheme(isDark ? AstraThemeMode.light : AstraThemeMode.dark),
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
