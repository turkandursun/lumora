import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_storage_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../auth/presentation/widgets/lumora_auth_decor.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/onboarding_photo_background.dart';

/// Lumora's first-touch storytelling onboarding — four swipeable beats
/// (welcome, journaling, AI companion, privacy) shown once, right after
/// sign up, each set against its own pastel ocean/sky photo that crossfades
/// in as the user swipes between pages.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 4;

  final _pageController = PageController();
  final _onboardingStorage = OnboardingStorageService();
  double _page = 0;

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
      context.go(AppRoutes.welcome, extra: true);
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
    final l10n = AppLocalizations.of(context);
    final isLastPage = _page.round() == _pageCount - 1;
    final pages = _buildPages(l10n);

    return Scaffold(
      backgroundColor: SakuraHomePalette.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: OnboardingPhotoBackground(pageIndex: _page.round()),
          ),
          SafeArea(
            child: ResponsiveContent(
              child: Column(
                children: [
                  _buildSkipRow(l10n, isLastPage),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedPage(index, pages[index]);
                      },
                    ),
                  ),
                  _buildDots(),
                  const SizedBox(height: 28),
                  _buildActionButton(l10n, isLastPage),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<OnboardingPage> _buildPages(AppLocalizations l10n) {
    return [
      OnboardingPage(
        eyebrow: l10n.onboardingWelcomeEyebrow,
        illustration: const Icon(
          Icons.spa_outlined,
          size: 46,
          color: LumoraPalette.primaryPurple,
        ),
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
      ),
      OnboardingPage(
        illustration: Transform.scale(scale: 2.1, child: const Butterfly()),
        title: l10n.onboardingJournalingTitle,
        body: l10n.onboardingJournalingBody,
      ),
      OnboardingPage(
        illustration: const Icon(
          Icons.auto_awesome_outlined,
          size: 42,
          color: LumoraPalette.primaryPurple,
        ),
        title: l10n.onboardingCompanionTitle,
        body: l10n.onboardingCompanionBody,
      ),
      OnboardingPage(
        illustration: const Icon(
          Icons.lock_outline_rounded,
          size: 42,
          color: LumoraPalette.primaryPurple,
        ),
        title: l10n.onboardingPrivacyTitle,
        body: l10n.onboardingPrivacyBody,
      ),
    ];
  }

  /// Subtle fade + rise as a page settles into place — calm rather than
  /// snappy, matching the app's soft tone.
  Widget _buildAnimatedPage(int index, Widget child) {
    final distance = (index - _page).clamp(-1.0, 1.0).abs();
    return Opacity(
      opacity: 1 - (distance * 0.6),
      child: Transform.translate(
        offset: Offset(0, distance * 18),
        child: child,
      ),
    );
  }

  Widget _buildSkipRow(AppLocalizations l10n, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isLastPage ? 0 : 1,
            child: IgnorePointer(
              ignoring: isLastPage,
              child: _SkipButton(
                label: l10n.onboardingSkip,
                onTap: _completeOnboarding,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (index) {
        final distance = (index - _page).abs();
        final isActive = distance < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? LumoraPalette.primaryPurple
                : SakuraHomePalette.textDeep.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(AppLocalizations l10n, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: LumoraPalette.ctaGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: LumoraPalette.primaryPurple.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _onNextPressed,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isLastPage ? l10n.onboardingGetStarted : l10n.onboardingNext,
                  key: ValueKey(isLastPage),
                  style: LumoraPalette.bodyStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass pill for the top-right "Skip" affordance — same translucent
/// white fill/border treatment as [OnboardingPage]'s illustration medallion,
/// so it reads as a tappable control against the photo backdrop instead of
/// a stray label.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.85)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: LumoraPalette.bodyStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textDeep.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
