import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_storage_service.dart';
import '../../../../theme/app_theme.dart';

/// Shown on app start. Decides whether to route to onboarding (first
/// launch), straight to home (an existing, still-valid Supabase session —
/// restored synchronously by `Supabase.initialize()` in main.dart before
/// this screen ever mounts), or login (onboarding done, no session).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _onboardingStorage = OnboardingStorageService();

  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    final results = await Future.wait([
      _onboardingStorage.isOnboardingComplete(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    final onboardingComplete = results[0] as bool;

    if (!mounted) return;
    if (!onboardingComplete) {
      context.go(AppRoutes.onboarding);
      return;
    }
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    context.go(hasSession ? AppRoutes.home : AppRoutes.login);
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
                'Lumora',
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
