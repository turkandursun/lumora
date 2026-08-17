import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';
import '../../../mood/presentation/providers/mood_providers.dart';

/// Auth bootstrap only: logged-out users enter Login, completed authenticated
/// sessions enter Home, and an explicitly pending registration resumes safely.
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
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    // The storytelling onboarding now comes *after* login/sign-up, so the
    // splash no longer gates on it here.
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasSession) {
      context.go(
        AppRoutes.greeting,
        extra: const LumaGreetingRouteData.preAuth(),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go(AppRoutes.login);
      return;
    }

    // Avoid a default-palette flash: wait only for the fast user-scoped local
    // cache. Cloud palette validation keeps running in the provider.
    await bootstrapAstraPaletteForCurrentUser(ref);

    // Preserve existing startup backup/sync before user-owned screens render.
    await ref.read(cloudBackupServiceProvider).syncOnStartup();
    if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id) {
      return;
    }

    FreshRegistrationIntent? intent;
    final signupOAuthOrigin =
        await registrationFlowStore.consumeOAuthSignupAttempt();
    if (signupOAuthOrigin &&
        AuthFlowRoutes.isFirstOAuthAuthentication(
          createdAt: user.createdAt,
          lastSignInAt: user.lastSignInAt,
        )) {
      intent = await registrationFlowStore.begin(user.id);
    } else {
      intent = await registrationFlowStore.restore(user.id);
    }
    if (!mounted || Supabase.instance.client.auth.currentUser?.id != user.id) {
      return;
    }

    if (intent != null) {
      context.go(
        AuthFlowRoutes.routeForRegistrationStep(intent.step),
        extra: AuthFlowRoutes.routeDataForRegistration(intent),
      );
    } else {
      final hasMood =
          await ref.read(moodLogRepositoryProvider).hasMoodForToday();
      if (!mounted ||
          Supabase.instance.client.auth.currentUser?.id != user.id) {
        return;
      }
      if (hasMood) {
        context.go(AuthFlowRoutes.home);
      } else {
        context.go(
          AuthFlowRoutes.greeting,
          extra: const LumaGreetingRouteData.returning(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AstraKit.palette(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: palette.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.cardBackground,
                  border: Border.all(color: palette.softBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: palette.focusGlow,
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.spa_outlined,
                  color: palette.activeAccent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ASTRA',
                style: AstraKit.wordmark(context, false, fontSize: 32),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(palette.activeAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
