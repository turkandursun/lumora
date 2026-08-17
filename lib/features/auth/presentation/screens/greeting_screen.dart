import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_avatar.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../domain/auth_flow_routes.dart';
import '../../domain/registration_flow_state.dart';

/// A warm greeting beat shown right after the user picks their mood: Luma's
/// star appears and "types" a hello, letter by letter, then hands off to Home.
/// Uses the same theme-aware scene (sun / moon) as the rest of the app.
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
  String _shown = '';
  int _i = 0;
  bool _done = false;
  bool _started = false;
  String _full = '';
  Timer? _typeTimer;
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
    _full = switch (widget.variant) {
      LumaGreetingVariant.preAuth => l10n.greetingPreAuth,
      LumaGreetingVariant.postSignup => nickname == null
          ? l10n.greetingPostSignupNoName
          : l10n.greetingPostSignup(nickname),
      LumaGreetingVariant.returningUser => nickname == null
          ? l10n.greetingReturningNoName
          : l10n.greetingReturning(nickname),
    };
    _typeTimer = Timer.periodic(const Duration(milliseconds: 55), (t) {
      if (_i >= _full.length) {
        t.cancel();
        if (mounted) setState(() => _done = true);
        // Linger on the greeting for a while before handing off to Home.
        _handoffTimer = Timer(const Duration(seconds: 7), _goNext);
        return;
      }
      if (mounted) {
        setState(() {
          _i++;
          _shown = _full.substring(0, _i);
        });
      }
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
      _typeTimer?.cancel();
      setState(() {
        _shown = _full;
        _done = true;
      });
      _handoffTimer?.cancel();
      _handoffTimer = Timer(const Duration(milliseconds: 900), _goNext);
    } else {
      _handoffTimer?.cancel();
      _goNext();
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _handoffTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: AstraMountainBackground(
          isDark: isDark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LumaAvatar(size: 132, speaking: !_done),
                  const SizedBox(height: 32),
                  Text(
                    _shown,
                    textAlign: TextAlign.center,
                    style: AstraKit.heading1(context, isDark, fontSize: 22)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 40),
                  AnimatedOpacity(
                    opacity: _done ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      AppLocalizations.of(context).greetingTapToContinue,
                      style: AstraKit.mutedText(context, isDark, fontSize: 13),
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
