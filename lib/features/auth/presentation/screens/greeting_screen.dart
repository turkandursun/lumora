import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_avatar.dart';

/// A warm greeting beat shown right after the user picks their mood: Luma's
/// star appears and "types" a hello, letter by letter, then hands off to Home.
/// Uses the same theme-aware scene (sun / moon) as the rest of the app.
class GreetingScreen extends ConsumerStatefulWidget {
  const GreetingScreen({super.key});

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _full = AppLocalizations.of(context).greetingWelcomeBack;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 55), (t) {
      if (_i >= _full.length) {
        t.cancel();
        if (mounted) setState(() => _done = true);
        // Linger on the greeting for a while before handing off to Home.
        _handoffTimer = Timer(const Duration(seconds: 7), _goHome);
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

  void _goHome() {
    if (mounted) context.go(AppRoutes.home);
  }

  void _skip() {
    if (!_done) {
      _typeTimer?.cancel();
      setState(() {
        _shown = _full;
        _done = true;
      });
      _handoffTimer?.cancel();
      _handoffTimer = Timer(const Duration(milliseconds: 900), _goHome);
    } else {
      _handoffTimer?.cancel();
      _goHome();
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
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
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
                    style: AstraKit.heading1(isDark, fontSize: 22)
                        .copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 40),
                  AnimatedOpacity(
                    opacity: _done ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      isTr ? 'Devam etmek için dokun' : 'Tap to continue',
                      style: AstraKit.mutedText(isDark, fontSize: 13),
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
