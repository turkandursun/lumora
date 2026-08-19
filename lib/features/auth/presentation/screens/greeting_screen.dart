import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_liquid_background.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_animated_avatar.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../domain/auth_flow_routes.dart';
import '../../domain/registration_flow_state.dart';

/// A warm greeting beat shown right after the user picks their mood: Luma's
/// star floats in over a gently undulating liquid background, and the greeting
/// rises into place line by line (a calm, staggered reveal) rather than being
/// typed out. Then it hands off to Home.
class GreetingScreen extends ConsumerStatefulWidget {
  const GreetingScreen({
    super.key,
    required this.variant,
    this.registrationIntent,
  });

  final LumaGreetingVariant variant;
  final FreshRegistrationIntent? registrationIntent;

  @override
  ConsumerState<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends ConsumerState<GreetingScreen> {
  bool _done = false;
  bool _started = false;
  List<String> _lines = const [];
  Timer? _doneTimer;
  Timer? _handoffTimer;
  bool _navigating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final l10n = AppLocalizations.of(context);
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fullName = (metadata?['full_name'] as String?)?.trim();
    final nickname = fullName == null || fullName.isEmpty
        ? null
        : fullName.split(RegExp(r'\s+')).first;
    final full = switch (widget.variant) {
      LumaGreetingVariant.preAuth => l10n.greetingPreAuth,
      LumaGreetingVariant.postSignup => nickname == null
          ? l10n.greetingPostSignupNoName
          : l10n.greetingPostSignup(nickname),
      LumaGreetingVariant.returningUser => nickname == null
          ? l10n.greetingReturningNoName
          : l10n.greetingReturning(nickname),
    };
    _lines = full
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Let the staggered reveal finish, then reveal the "tap to continue" hint
    // and start the gentle auto-handoff.
    final revealMs = 500 + _lines.length * 260 + 500;
    _doneTimer = Timer(Duration(milliseconds: revealMs), () {
      if (!mounted) return;
      setState(() => _done = true);
      _handoffTimer = Timer(const Duration(seconds: 7), _goNext);
    });
  }

  Future<void> _goNext() async {
    if (_navigating || !mounted) return;
    _navigating = true;
    if (widget.variant == LumaGreetingVariant.preAuth) {
      context.go(AppRoutes.login);
      return;
    }
    final current = widget.registrationIntent;
    if (widget.variant == LumaGreetingVariant.postSignup && current != null) {
      try {
        await registrationFlowStore.complete(current);
      } on RegistrationIntentMismatchException {
        // A stale registration result must not keep the user in onboarding.
      }
    }
    if (!mounted) return;
    if (widget.variant == LumaGreetingVariant.returningUser) {
      final hasMood =
          await ref.read(moodLogRepositoryProvider).hasMoodForToday();
      if (!mounted) return;
      if (hasMood) {
        context.go(AuthFlowRoutes.home);
      } else {
        context.go(
          AuthFlowRoutes.mood,
          extra: const MoodRouteData(MoodFlow.dailyCheckIn),
        );
      }
      return;
    }
    context.go(AuthFlowRoutes.home);
  }

  void _skip() {
    if (!_done) {
      // Reveal everything at once, then a short beat before handing off.
      _doneTimer?.cancel();
      setState(() => _done = true);
      _handoffTimer?.cancel();
      _handoffTimer = Timer(const Duration(milliseconds: 900), _goNext);
    } else {
      _handoffTimer?.cancel();
      _goNext();
    }
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _handoffTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraLiquidBackground(
        intensity: 1.15,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Luma's star with a soft glow halo behind it for depth.
                  AstraEntrance(
                    index: 0,
                    offset: 0,
                    scaleFrom: 0.55,
                    duration: const Duration(milliseconds: 720),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.32),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const LumaAnimatedAvatar(
                        size: 132,
                        mode: LumaAnimationMode.speaking,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // The greeting rises into place, one line at a time.
                  for (var i = 0; i < _lines.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: AstraEntrance(
                        index: i + 1,
                        intervalMs: 260,
                        offset: 26,
                        scaleFrom: 0.92,
                        duration: const Duration(milliseconds: 560),
                        child: Text(
                          _lines[i],
                          textAlign: TextAlign.center,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 22)
                                  .copyWith(height: 1.4),
                        ),
                      ),
                    ),
                  const SizedBox(height: 42),
                  AnimatedSlide(
                    offset: Offset(0, _done ? 0 : 0.4),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _done ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: _TapHint(
                        label: l10n.greetingTapToContinue,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A gently pulsing "tap to continue" hint, so the idle state still feels alive.
class _TapHint extends StatefulWidget {
  const _TapHint({
    required this.label,
    required this.isDark,
    required this.primary,
  });

  final String label;
  final bool isDark;
  final Color primary;

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: 0.6 + 0.4 * _c.value,
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded,
              size: 15, color: widget.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: AstraKit.mutedText(context, widget.isDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
