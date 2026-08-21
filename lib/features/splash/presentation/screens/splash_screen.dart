import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../profile/data/profile_repository.dart';

/// Auth bootstrap only: logged-out users enter Login, completed authenticated
/// sessions enter Home, and an explicitly pending registration resumes safely.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _autoTimer;
  bool _navigated = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    // A gentle "breathing" pulse so the star feels alive.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    // Hold the welcome for a while, but let an impatient user tap to skip.
    _autoTimer = Timer(const Duration(seconds: 15), _decideNextRoute);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _decideNextRoute() async {
    if (_navigated) return;
    _navigated = true;
    _autoTimer?.cancel();

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
    final signupOAuthAttemptStartedAt =
        await registrationFlowStore.consumeOAuthSignupAttemptStartedAt();
    final signupOAuthOrigin = signupOAuthAttemptStartedAt != null;
    final loginOAuthOrigin =
        await registrationFlowStore.consumeOAuthLoginAttempt();
    if (AuthFlowRoutes.shouldBeginFreshOAuthRegistration(
      signupAttemptStartedAt: signupOAuthAttemptStartedAt,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
      evaluatedAt: DateTime.now(),
    )) {
      try {
        await ProfileRepository().initializeFreshProfileDefaults(user.id);
      } catch (error) {
        debugPrint(
          '[Auth] Fresh Google profile initialization deferred '
          'type=${error.runtimeType}',
        );
      }
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
    } else if (signupOAuthOrigin || loginOAuthOrigin) {
      // A web OAuth callback recreates the app at Splash. Preserve the manual
      // Google login experience instead of treating it as a silent session
      // restore when today's mood already exists.
      context.go(
        AuthFlowRoutes.greeting,
        extra: const LumaGreetingRouteData.returning(),
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

  /// The registered nickname (first word of the profile's full name), if a
  /// session is active — used for the warm "Hoş geldin, X" line.
  String? get _nickname {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fullName = (metadata?['full_name'] as String?)?.trim();
    if (fullName == null || fullName.isEmpty) return null;
    return fullName.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final nickname = _nickname;
    final greeting = nickname == null
        ? (isTr ? 'Hoş geldin!' : 'Welcome!')
        : (isTr ? 'Hoş geldin, $nickname!' : 'Welcome, $nickname!');
    final size = MediaQuery.sizeOf(context);
    final starSize = (size.width * 0.5).clamp(180.0, 260.0);
    const glow = Color(0xFFFFC46B);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _decideNextRoute, // tap anywhere to skip the wait
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // Deep starry-night gradient, like the reference.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15112E), Color(0xFF241A4C), Color(0xFF3A2A6B)],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Shooting stars + sparkles behind everything.
              const Positioned.fill(
                child: CustomPaint(painter: _ShootingStarsPainter()),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    // Center: the glowing, gently breathing Luma star.
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = Curves.easeInOut.transform(_pulse.value);
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: glow.withValues(alpha: 0.30 + 0.18 * t),
                                blurRadius: 60 + 30 * t,
                                spreadRadius: 6 + 6 * t,
                              ),
                            ],
                          ),
                          child: Transform.scale(
                            scale: 0.96 + 0.07 * t,
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/luma_star_closed.png',
                        width: starSize,
                        height: starSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'ASTRA',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: const Color(0xFFFFE7BE),
                        shadows: const [
                          Shadow(color: Color(0x99FFC46B), blurRadius: 26),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      greeting.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _ContinueButton(
                      label: isTr ? 'DEVAM ET' : 'CONTINUE',
                      onTap: _decideNextRoute,
                    ),
                    const SizedBox(height: 46),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft gradient pill "Devam et →" button.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF9A86EC), Color(0xFF6C8BE0)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C8BE0).withValues(alpha: 0.5),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Paints bold, clean shooting-star comets (a bright head + a tapering, fading
/// tail) plus scattered sparkle-stars across the upper sky, echoing the
/// reference art. All comets are parallel, streaking down toward the mascot.
class _ShootingStarsPainter extends CustomPainter {
  const _ShootingStarsPainter();

  static Offset _norm(Offset o) => o / o.distance;

  static Path _starPath(Offset c, double r) {
    final inner = r * 0.4;
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = i * (math.pi / 2) - math.pi / 2;
      final tip = c + Offset(math.cos(a), math.sin(a)) * r;
      final mid = c +
          Offset(math.cos(a + math.pi / 4), math.sin(a + math.pi / 4)) * inner;
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(mid.dx, mid.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shared streak direction (from the upper-right tail down toward the star).
    final dir = _norm(const Offset(-0.9, 1.0));
    final perp = Offset(-dir.dy, dir.dx);

    // Each comet: tailX%, tailY%, length (% of width), head width (px).
    const comets = <List<double>>[
      [1.00, 0.03, 0.36, 9.0],
      [0.82, 0.00, 0.30, 6.5],
      [1.08, 0.15, 0.32, 7.5],
      [0.66, 0.05, 0.24, 5.0],
      [0.90, 0.22, 0.28, 6.0],
    ];
    for (final c in comets) {
      final tail = Offset(c[0] * w, c[1] * h);
      final head = tail + dir * (c[2] * w);
      final hw = c[3];
      final p1 = head + perp * (hw / 2);
      final p2 = head - perp * (hw / 2);

      // Tapering tail: bright at the head, fully transparent at the tail tip.
      final tailPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(tail.dx, tail.dy)
        ..close();
      canvas.drawPath(
        tailPath,
        Paint()
          ..shader = ui.Gradient.linear(
            head,
            tail,
            const [Color(0xF7FFE7A6), Color(0x00FFE7A6)],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
      );

      // Soft halo + crisp core + a little sparkle-star at the head.
      canvas.drawCircle(
        head,
        hw * 1.05,
        Paint()
          ..color = const Color(0xFFFFEFC4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(head, hw * 0.34, Paint()..color = Colors.white);
      canvas.drawPath(
        _starPath(head, hw * 1.9),
        Paint()..color = const Color(0xF2FFF6DC),
      );
    }

    // Scattered sparkle-stars (a mix of tiny 4-point stars and dots).
    const stars = <List<double>>[
      [0.16, 0.10, 4.0],
      [0.50, 0.07, 5.0],
      [0.76, 0.13, 4.5],
      [0.30, 0.20, 3.2],
      [0.86, 0.27, 3.6],
      [0.62, 0.24, 3.0],
    ];
    for (final s in stars) {
      canvas.drawPath(
        _starPath(Offset(s[0] * w, s[1] * h), s[2]),
        Paint()..color = const Color(0xCCFFF3D0),
      );
    }
    const dots = <List<double>>[
      [0.22, 0.15, 1.4],
      [0.40, 0.12, 1.1],
      [0.68, 0.05, 1.2],
      [0.12, 0.24, 1.3],
      [0.45, 0.27, 1.2],
      [0.90, 0.10, 1.1],
      [0.55, 0.32, 1.0],
      [0.80, 0.20, 1.2],
      [0.34, 0.30, 1.0],
    ];
    final dotPaint = Paint()..color = const Color(0xB3FFF1C4);
    for (final d in dots) {
      canvas.drawCircle(Offset(d[0] * w, d[1] * h), d[2], dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
