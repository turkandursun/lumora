import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/astra_theme_provider.dart';
import '../../theme/astra_screen_kit.dart';
import '../auth/domain/auth_flow_routes.dart';
import '../auth/domain/registration_flow_state.dart';
import 'privacy_consent.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

/// Shown once, right after registration: a warm, premium gate where the user
/// reviews and accepts the Privacy Policy and Terms of Use before onboarding.
class PrivacyConsentScreen extends ConsumerStatefulWidget {
  const PrivacyConsentScreen({super.key, this.registrationIntent});

  final FreshRegistrationIntent? registrationIntent;

  @override
  ConsumerState<PrivacyConsentScreen> createState() =>
      _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends ConsumerState<PrivacyConsentScreen> {
  bool _agreed = false;
  bool _busy = false;

  Future<void> _accept() async {
    if (!_agreed || _busy) return;
    setState(() => _busy = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) await PrivacyConsent.accept(userId);
    if (!mounted) return;
    final intent = widget.registrationIntent;
    if (intent == null) {
      context.go(AuthFlowRoutes.home);
    } else {
      context.go(AuthFlowRoutes.nameEntry, extra: intent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final palette = AstraKit.palette(context);
    final primary = AstraKit.primary(context, isDark);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Glowing gradient shield badge.
                      AstraEntrance(
                        index: 0,
                        scaleFrom: 0.6,
                        duration: const Duration(milliseconds: 640),
                        child: Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primary, palette.secondary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.45),
                                  blurRadius: 34,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.verified_user_rounded,
                                color: Colors.white, size: 44),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AstraEntrance(
                        index: 1,
                        offset: 20,
                        child: Text(
                          isTr
                              ? 'Gizliliğin güvende'
                              : 'Your privacy is safe',
                          textAlign: TextAlign.center,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 26),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AstraEntrance(
                        index: 2,
                        offset: 20,
                        child: Text(
                          isTr
                              ? 'Yolculuğa başlamadan önce, verilerini nasıl koruduğumuza ve birkaç basit kurala bir göz at.'
                              : 'Before we begin, take a look at how we protect your data and a few simple rules.',
                          textAlign: TextAlign.center,
                          style:
                              AstraKit.mutedText(context, isDark, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 26),
                      AstraEntrance(
                        index: 3,
                        offset: 24,
                        child: _DocCard(
                          icon: Icons.privacy_tip_rounded,
                          title:
                              isTr ? 'Gizlilik Politikası' : 'Privacy Policy',
                          subtitle: isTr
                              ? 'Verilerini nasıl koruyoruz'
                              : 'How we protect your data',
                          isDark: isDark,
                          primary: primary,
                          secondary: palette.secondary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const PrivacyPolicyScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AstraEntrance(
                        index: 4,
                        offset: 24,
                        child: _DocCard(
                          icon: Icons.menu_book_rounded,
                          title: isTr ? 'Kullanım Şartları' : 'Terms of Use',
                          subtitle: isTr
                              ? 'Birlikte huzurlu bir alan'
                              : 'A calm space, together',
                          isDark: isDark,
                          primary: primary,
                          secondary: palette.secondary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const TermsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AstraEntrance(
                        index: 5,
                        offset: 24,
                        child: _AgreeRow(
                          agreed: _agreed,
                          isDark: isDark,
                          primary: primary,
                          label: isTr
                              ? 'Gizlilik Politikası ve Kullanım Şartları\'nı okudum, kabul ediyorum.'
                              : 'I have read and accept the Privacy Policy and Terms of Use.',
                          onTap: () => setState(() => _agreed = !_agreed),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _agreed ? 1 : 0.55,
                  child: AstraGoldButton(
                    isDark: isDark,
                    forceGold: true,
                    height: 56,
                    label: isTr ? 'Kabul Et ve Devam Et' : 'Accept & Continue',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _busy,
                    onTap: _agreed ? _accept : () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A premium document link card: a gradient icon chip, title + subtitle, chevron.
class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color primary;
  final Color secondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        borderRadius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, secondary],
                ),
                boxShadow: [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AstraKit.body(context, isDark,
                          fontSize: 15.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AstraKit.mutedText(context, isDark, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AstraKit.muted(context, isDark)),
          ],
        ),
      ),
    );
  }
}

/// A tappable "I agree" row that lights up in the accent colour when checked.
class _AgreeRow extends StatelessWidget {
  const _AgreeRow({
    required this.agreed,
    required this.isDark,
    required this.primary,
    required this.label,
    required this.onTap,
  });

  final bool agreed;
  final bool isDark;
  final Color primary;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: agreed
              ? primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0x22231845) : const Color(0x44FFFFFF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: agreed ? primary : primary.withValues(alpha: 0.22),
            width: agreed ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: agreed ? primary : Colors.transparent,
                border: Border.all(
                    color: agreed ? primary : primary.withValues(alpha: 0.5),
                    width: 2),
              ),
              child: agreed
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: AstraKit.ink(context, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
