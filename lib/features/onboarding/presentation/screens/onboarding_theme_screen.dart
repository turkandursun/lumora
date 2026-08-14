import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_avatar.dart';

/// Onboarding — theme picker, shown right after the nickname step.
///
/// Luma's smiling star is the only mascot. Tapping a colour instantly applies
/// that palette to the WHOLE app (this screen's background included), so the
/// user sees exactly what every screen will look like. "Devam et" continues
/// into the storytelling onboarding.
class OnboardingThemeScreen extends ConsumerWidget {
  const OnboardingThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final selectedId = ref.watch(astraPaletteProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Palette gradient background — updates live as a colour is tapped.
      body: AstraMountainBackground(
        isDark: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const LumaAvatar(size: 104),
                const SizedBox(height: 22),
                Text(
                  isTr ? 'Rengini seç' : 'Choose your colour',
                  textAlign: TextAlign.center,
                  style: AstraKit.heading1(false, fontSize: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  isTr
                      ? 'BUNU İSTEDİĞİN ZAMAN AYARLARDAN DEĞİŞTİREBİLİRSİN'
                      : 'YOU CAN CHANGE THIS LATER IN SETTINGS',
                  textAlign: TextAlign.center,
                  style: AstraKit.mutedText(false, fontSize: 12)
                      .copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final p in astraPalettes)
                      GestureDetector(
                        onTap: () =>
                            ref.read(astraPaletteProvider.notifier).select(p.id),
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
                const Spacer(),
                AstraGoldButton(
                  isDark: false,
                  label: isTr ? 'Devam et' : 'Continue',
                  onTap: () => context.go(AppRoutes.onboarding, extra: true),
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
