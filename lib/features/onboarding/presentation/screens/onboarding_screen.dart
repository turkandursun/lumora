import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';

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
        'Aklından geçenleri yaz ya da sesinle anlat. Her günlük yalnızca sana ait ve gizli kalır.',
    bodyEn:
        'Write what is on your mind, or speak it aloud. Every entry stays private — yours alone.',
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
    icon: Icons.format_quote_rounded,
    titleTr: 'Günün sözleri bir kaydırma uzağında',
    titleEn: 'Daily wisdom is a swipe away',
    bodyTr:
        'Ana ekranda sağa kaydır; ünlü düşünürlerin ilham veren sözleri tek tek karşına gelsin. Sevdiğini favorine ekle ya da paylaş.',
    bodyEn:
        'Swipe right on the home screen and meet inspiring words from great thinkers, one at a time. Favorite the ones you love, or share them.',
  ),
  _Beat(
    icon: Icons.shield_moon_rounded,
    titleTr: 'Yolculuk seninle güvende',
    titleEn: 'The journey is safe with you',
    bodyTr:
        'Günlüklerin sadece senin, bu alan tamamen sana ait. Hazırsan, ilk adımı birlikte atalım.',
    bodyEn:
        'Your journals are yours alone, this space is entirely yours. When you are ready, we take the first step together.',
  ),
];

/// ASTRA's first-touch storytelling onboarding, in the current visual language:
/// the theme's moon/sun mountain scene fills the screen, and four swipeable
/// beats (welcome · journaling · Luma companion · privacy) fade and rise on
/// frosted gold-glass cards — the same world as the login and journal screens,
/// so the whole first run reads as one continuous experience.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.registrationIntent,
  });

  final FreshRegistrationIntent? registrationIntent;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
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
    final current = widget.registrationIntent;
    if (current == null) {
      if (mounted) context.go(AppRoutes.home);
      return;
    }
    try {
      final next = await registrationFlowStore.advance(
        current,
        RegistrationStep.mood,
      );
      if (mounted) {
        context.go(
          AuthFlowRoutes.afterOnboarding,
          extra: MoodRouteData(
            MoodFlow.signup,
            registrationIntent: next,
          ),
        );
      }
    } on RegistrationIntentMismatchException {
      if (mounted) context.go(AppRoutes.home);
    }
  }

  void _onNextPressed() {
    final current = _page.round();
    if (current == _pageCount - 1) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The onboarding journey always presents in the light theme — a branded
    // pre-app experience — even when the app itself is in dark mode. We override
    // this subtree's palette tokens to the always-light variant so every
    // context-driven AstraKit colour resolves light regardless of app theme.
    final basePalette = ref.watch(activePaletteProvider);
    final lightTokens =
        AstraThemeTokens.fromPalette(basePalette, brightness: Brightness.light);
    return Theme(
      data: Theme.of(context).copyWith(extensions: [lightTokens]),
      child: Builder(builder: (context) => _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    const isDark = false;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final gold = AstraKit.gold(context, isDark);
    final isLastPage = _page.round() == _pageCount - 1;

    return Scaffold(
      body: AstraMountainBackground(
        isDark: isDark,
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
                        _buildBeat(context, _beats[index], isDark, gold, isTr),
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
                onTap: () => _completeOnboarding(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  /// Reflectly-style page motion: as a beat leaves it eases back (scales down),
  /// softly fades and drifts, while the arriving beat blooms up to full size and
  /// full opacity. Layered over the PageView's own horizontal glide this reads
  /// as a smooth, springy cross-fade rather than a flat slide.
  Widget _buildAnimatedPage(int index, Widget child) {
    final delta = index - _page; // signed distance from the settled page
    final distance = delta.abs().clamp(0.0, 1.0);
    final scale = 1 - distance * 0.16;
    final opacity = (1 - distance * 0.9).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        // A touch of horizontal parallax plus a gentle downward drift as the
        // beat recedes — the incoming beat rises into place.
        offset: Offset(delta * -26, distance * 26),
        child: Transform.scale(
          scale: scale,
          child: child,
        ),
      ),
    );
  }

  Widget _buildBeat(
      BuildContext context, _Beat beat, bool isDark, Color gold, bool isTr) {
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
                  style: AstraKit.heading1(context, isDark, fontSize: 23),
                ),
                const SizedBox(height: 14),
                Text(
                  isTr ? beat.bodyTr : beat.bodyEn,
                  textAlign: TextAlign.center,
                  style: AstraKit.body(
                    context,
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
  const _Medallion(
      {required this.icon, required this.gold, required this.isDark});

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
