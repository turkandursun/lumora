import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_storage_service.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';

/// One storytelling beat of the onboarding flow.
class _Beat {
  const _Beat({
    required this.icon,
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
    this.eyebrow,
  });

  final IconData icon;
  final String? eyebrow;
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;
}

const List<_Beat> _beats = [
  _Beat(
    icon: Icons.auto_awesome,
    eyebrow: 'ASTRA',
    titleTr: 'İçindeki evrene hoş geldin',
    titleEn: 'Welcome to the universe within',
    bodyTr:
        'Yıldızların ışığında kendine dönüş başlıyor. Acele yok — bu yolculuk tamamen senin ritminde.',
    bodyEn:
        'Under the light of the stars, your return to yourself begins. No rush — this journey moves at your own pace.',
  ),
  _Beat(
    icon: Icons.auto_stories_rounded,
    titleTr: 'Anlarını mühürle',
    titleEn: 'Seal your moments',
    bodyTr:
        'Aklından geçenleri yaz ya da sesinle anlat. Her günlük şifreli ve kilitli; yalnızca sana ait.',
    bodyEn:
        'Write what is on your mind, or speak it aloud. Every entry is encrypted and locked — yours alone.',
  ),
  _Beat(
    icon: Icons.spa_rounded,
    titleTr: 'Yanında bir yol arkadaşı',
    titleEn: 'A companion by your side',
    bodyTr:
        'Luma seni dinler, nazik sorularla düşüncelerini açar. Asla yargılamaz, hep yanındadır.',
    bodyEn:
        'Luma listens and gently opens your thoughts with soft questions. Never judging, always here.',
  ),
  _Beat(
    icon: Icons.shield_moon_rounded,
    titleTr: 'Yolculuk seninle güvende',
    titleEn: 'The journey is safe with you',
    bodyTr:
        'Verilerin şifreli, günlüklerin sadece senin. Hazırsan, ilk adımı birlikte atalım.',
    bodyEn:
        'Your data is encrypted, your journals only yours. When you are ready, we take the first step together.',
  ),
];

/// Lumora's first-touch storytelling onboarding, in the ASTRA visual language:
/// the theme's moon/sun mountain scene fills the screen, and four swipeable
/// beats (welcome · journaling · Luma companion · privacy) fade and rise on
/// frosted gold-glass cards — the same world as the login and journal screens,
/// so the whole first run reads as one continuous experience.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.isNewSignup = false});

  /// True when reached from the sign-up flow — carried through to the mood
  /// check-in so the hobbies step is shown only for new registrations.
  final bool isNewSignup;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _onboardingStorage = OnboardingStorageService();
  double _page = 0;

  int get _pageCount => _beats.length;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await _onboardingStorage.setOnboardingComplete();
    if (!mounted) return;
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (hasSession) {
      context.go(AppRoutes.welcome, extra: widget.isNewSignup);
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _onNextPressed() {
    final current = _page.round();
    if (current == _pageCount - 1) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final gold = AstraKit.gold(isDark);
    final isLastPage = _page.round() == _pageCount - 1;

    return Scaffold(
      body: AstraMountainBackground(
        isDark: isDark,
        useEntryScene: true,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                _buildSkipRow(isDark, gold, isTr, isLastPage),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pageCount,
                    itemBuilder: (context, index) {
                      return _buildAnimatedPage(
                        index,
                        _buildBeat(_beats[index], isDark, gold, isTr),
                      );
                    },
                  ),
                ),
                _buildDots(gold, isDark),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AstraGoldButton(
                    isDark: isDark,
                    forceGold: true,
                    height: 56,
                    label: isLastPage
                        ? (isTr ? 'Yolculuğa Başla' : 'Begin the Journey')
                        : (isTr ? 'Devam' : 'Continue'),
                    onTap: _onNextPressed,
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

  Widget _buildSkipRow(bool isDark, Color gold, bool isTr, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.only(right: 18, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isLastPage ? 0 : 1,
            child: IgnorePointer(
              ignoring: isLastPage,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _completeOnboarding,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: Text(
                    isTr ? 'Atla' : 'Skip',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: gold,
                      shadows: const [
                        Shadow(color: Color(0x88000000), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gentle fade + rise as a beat settles into place — calm rather than snappy.
  Widget _buildAnimatedPage(int index, Widget child) {
    final distance = (index - _page).clamp(-1.0, 1.0).abs();
    return Opacity(
      opacity: 1 - (distance * 0.55),
      child: Transform.translate(
        offset: Offset(0, distance * 22),
        child: child,
      ),
    );
  }

  Widget _buildBeat(_Beat beat, bool isDark, Color gold, bool isTr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Medallion(icon: beat.icon, gold: gold, isDark: isDark),
          const SizedBox(height: 34),
          AstraGlassCard(
            isDark: isDark,
            primaryColor: gold,
            borderRadius: 26,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (beat.eyebrow != null) ...[
                  Text(
                    beat.eyebrow!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  isTr ? beat.titleTr : beat.titleEn,
                  textAlign: TextAlign.center,
                  style: AstraKit.heading1(isDark, fontSize: 23),
                ),
                const SizedBox(height: 14),
                Text(
                  isTr ? beat.bodyTr : beat.bodyEn,
                  textAlign: TextAlign.center,
                  style: AstraKit.body(
                    isDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(Color gold, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (index) {
        final distance = (index - _page).abs();
        final isActive = distance < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? gold : gold.withValues(alpha: 0.28),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// A frosted, gold-ringed circle framing each beat's icon — glowing softly so
/// it reads as a small celestial emblem over the mountain scene.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon, required this.gold, required this.isDark});

  final IconData icon;
  final Color gold;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0x59181026)
            : Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: gold.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.32),
            blurRadius: 34,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, size: 46, color: gold),
    );
  }
}
