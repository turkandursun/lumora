import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_avatar.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';

/// Onboarding — theme picker, shown right after the nickname step.
///
/// Luma's smiling star is the only mascot. Tapping a colour instantly applies
/// that palette to the WHOLE app. On "Devam et" a star bursts open in the
/// chosen colour, filling the screen, then hands off to the storytelling
/// onboarding. The persistent mascot star stays yellow everywhere else — only
/// this one-off transition is coloured.
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

class _OnboardingThemeScreenState extends ConsumerState<OnboardingThemeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2250),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        unawaited(_finishRegistrationStep());
      }
    });

  bool _bursting = false;
<<<<<<< Updated upstream
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
=======
  // The wash behind the growing star matches the chosen palette, so the burst
  // blends straight into the themed onboarding screen that follows.
  Color _fillColor = const Color(0xFFF8E3A6);
>>>>>>> Stashed changes

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_bursting) return;
    _fillColor = ref.read(activePaletteProvider).gradientBottom;
    setState(() => _bursting = true);
    _burst.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final selectedId = ref.watch(astraPaletteProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AstraMountainBackground(
            isDark: false,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Hidden during the burst so only the animating star shows.
                    _bursting
                        ? const SizedBox(width: 104, height: 104)
                        : const AstraEntrance(
                            index: 0,
                            intervalMs: 130,
                            offset: 20,
                            child: LumaAvatar(size: 104),
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
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700),
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
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
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
          // One-off coloured star burst that fills the screen on "Devam et".
          if (_bursting)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) {
                    final h = MediaQuery.sizeOf(context).height;
                    final v = _burst.value;
                    // Phase 1 (0 → 0.42): star glides smoothly from the top to
                    // the centre. Phase 2 (0.42 → 1): it grows to fill.
                    final move =
                        Curves.easeInOut.transform((v / 0.42).clamp(0.0, 1.0));
                    final grow = Curves.easeInCubic
                        .transform(((v - 0.42) / 0.58).clamp(0.0, 1.0));
                    // Paint-only translate (no relayout) → perfectly smooth.
                    final ty = (-h * 0.30) * (1 - move); // top → centre
                    final scale = 1.0 + grow * 46;
                    final fill = ((grow - 0.05) * 1.7).clamp(0.0, 1.0);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // A soft warm wash (not theme-coloured) so the corners
                        // fill in as the star grows.
                        Opacity(
                          opacity: fill,
                          child: ColoredBox(color: _fillColor),
                        ),
                        // The real yellow Luma star — unchanged colour. Isolated
                        // in its own layer so only it repaints each frame.
                        Center(
                          child: RepaintBoundary(
                            child: Transform.translate(
                              offset: Offset(0, ty),
                              child: Transform.scale(
                                scale: scale,
                                child: Image.asset(
                                  'assets/images/luma_star_closed.png',
                                  width: 104,
                                  height: 104,
                                  filterQuality: FilterQuality.low,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
