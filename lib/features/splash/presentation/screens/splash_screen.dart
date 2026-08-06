import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/theme_choice/presentation/screens/theme_choice_screen.dart';
import '../../../../theme/app_theme.dart';

/// Shown on app start. Decides whether to route to onboarding (first
/// launch), straight to home (an existing, still-valid Supabase session —
/// restored synchronously by `Supabase.initialize()` in main.dart before
/// this screen ever mounts), or login (onboarding done, no session).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    final prefs = results[0] as SharedPreferences;

    if (!mounted) return;
    // Very first thing: let the user pick a light/dark ASTRA theme.
    if (prefs.getString(astraThemeKey) == null) {
      context.go(AppRoutes.themeChoice);
      return;
    }
    // The storytelling onboarding now comes *after* login/sign-up, so the
    // splash no longer gates on it here.
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (hasSession) {
      // On a fresh device this pulls the user's cloud backup down before any
      // screen reads local data, so nothing looks "lost" after a reinstall.
      await ref.read(cloudBackupServiceProvider).syncOnStartup();
      if (!mounted) return;
    }
    // Route logged-in users through the mood check-in. It gates itself to the
    // first app entry of each calendar day, so on later opens the same day it
    // silently forwards to home.
    context.go(hasSession ? AppRoutes.welcome : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gradientTop,
              AppTheme.gradientMid,
              AppTheme.gradientBottom,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.glassSurface,
                  border: Border.all(color: AppTheme.glassBorder, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.glowShadow,
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ASTRA',
                style: AppTheme.displayFont(
                  fontSize: 32,
                  color: AppTheme.onGradientText,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
