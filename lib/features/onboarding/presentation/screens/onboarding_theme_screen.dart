import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_animated_avatar.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';

/// Onboarding — theme picker, shown right after the nickname step.
///
/// Luma's smiling star is the only mascot. Tapping a colour instantly applies
/// that palette to the whole app; Continue hands off through the router's
/// shared soft page transition.
class OnboardingThemeScreen extends ConsumerStatefulWidget {
  const OnboardingThemeScreen({
    super.key,
    required this.registrationIntent,
  });

  final FreshRegistrationIntent? registrationIntent;

  @override
  ConsumerState<OnboardingThemeScreen> createState() =>
      _OnboardingThemeScreenState();
}

class _OnboardingThemeScreenState extends ConsumerState<OnboardingThemeScreen> {
  bool _navigated = false;

  Future<void> _finishRegistrationStep() async {
    if (_navigated) return;
    _navigated = true;
    final current = widget.registrationIntent;
    if (current == null) {
      if (mounted) context.go(AppRoutes.home);
      return;
    }
    try {
      final next = await registrationFlowStore.advance(
        current,
        RegistrationStep.storytellingOnboarding,
      );
      if (mounted) context.go(AuthFlowRoutes.afterThemeSelect, extra: next);
    } on RegistrationIntentMismatchException {
      if (mounted) context.go(AppRoutes.home);
    }
  }

  void _onContinue() {
    if (_navigated) return;
    unawaited(_finishRegistrationStep());
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final selectedId = ref.watch(astraPaletteProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const AstraEntrance(
                  index: 0,
                  intervalMs: 130,
                  offset: 20,
                  child: LumaAnimatedAvatar(size: 100),
                ),
                const SizedBox(height: 22),
                AstraEntrance(
                  index: 1,
                  intervalMs: 130,
                  offset: 20,
                  child: Text(
                    isTr ? 'Rengini seç' : 'Choose your colour',
                    textAlign: TextAlign.center,
                    style: AstraKit.heading1(context, false, fontSize: 26),
                  ),
                ),
                const SizedBox(height: 10),
                AstraEntrance(
                  index: 2,
                  intervalMs: 130,
                  offset: 20,
                  child: Text(
                    isTr
                        ? 'BUNU İSTEDİĞİN ZAMAN AYARLARDAN DEĞİŞTİREBİLİRSİN'
                        : 'YOU CAN CHANGE THIS LATER IN SETTINGS',
                    textAlign: TextAlign.center,
                    style: AstraKit.mutedText(context, false, fontSize: 12)
                        .copyWith(
                            letterSpacing: 1.1, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                AstraEntrance(
                  index: 3,
                  intervalMs: 130,
                  offset: 20,
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final p in astraPalettes)
                        GestureDetector(
                          onTap: () => ref
                              .read(astraPaletteProvider.notifier)
                              .select(p.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: p.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: p.id == selectedId
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.6),
                                width: p.id == selectedId ? 4 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: p.id == selectedId
                                ? Icon(Icons.check_rounded,
                                    color: p.onPrimary, size: 28)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                AstraEntrance(
                  index: 4,
                  intervalMs: 130,
                  offset: 20,
                  child: AstraGoldButton(
                    isDark: false,
                    label: isTr ? 'Devam et' : 'Continue',
                    onTap: _onContinue,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
