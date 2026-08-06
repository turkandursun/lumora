import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    show AuthState;

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_storage_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

const _minPasswordLength = 8;
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Shared ASTRA palette — identical to the login screen so the two read as one
// continuous design.
const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE5C890);
const _goldDeep = Color(0xFFB08922);

/// Lumora's ASTRA sign-up screen — the visual twin of [LoginScreen]. The same
/// moon (dark) / sun (light) celestial scene fills the background; over it sit
/// the ASTRA wordmark and tagline, a dark frosted-glass panel (name · email ·
/// password · confirm password fields with the gold sparkle boxes, a gold
/// "Hesap Oluştur" button, a Google button and the sign-in link) and a bottom
/// crisis-support line. A fresh sign-up routes straight into the ASTRA
/// storytelling onboarding — the old purple "meet Luma" swipe screen was
/// removed.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _onboardingStorage = OnboardingStorageService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleSubmitting = false;
  String? _formError;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Google sign-in redirects the whole page away on web, so this screen's
    // own await never resumes there — instead we listen for the session
    // Supabase detects once the browser returns (or, on native, once the
    // system browser hands control back to the running app).
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _routeAfterGoogleSignIn();
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onCreateAccountPressed() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? error;
    if (name.isEmpty) {
      error = isTr ? 'Adını gir.' : 'Enter your name.';
    } else if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      error = isTr ? 'Geçerli bir mail adresi gir.' : 'Enter a valid email.';
    } else if (password.length < _minPasswordLength) {
      error = isTr
          ? 'Şifre en az $_minPasswordLength karakter olmalı.'
          : 'Password must be at least $_minPasswordLength characters.';
    } else if (confirm != password) {
      error = isTr ? 'Şifreler eşleşmiyor.' : 'Passwords do not match.';
    }
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() => _formError = null);
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .signUpWithPassword(email: email, password: password, fullName: name);
    if (!success || !mounted) return;

    await _onboardingStorage.setOnboardingIncomplete();
    // Fresh account: wipe any local data left by a previous account on this
    // device so the new user starts clean and account-isolated.
    await ref.read(cloudBackupServiceProvider).onSignIn();
    if (!mounted) return;
    context.go(AppRoutes.onboarding, extra: true);
  }

  Future<void> _onGoogleSignInPressed() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSubmitting = true);
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleSubmitting = false);
  }

  /// Google sign-in from the sign-up screen is treated as a new signup: run
  /// the ASTRA onboarding, which then shows the hobbies step. (Returning users
  /// normally use the login screen's Google button, which skips it.)
  Future<void> _routeAfterGoogleSignIn() async {
    await ref.read(cloudBackupServiceProvider).onSignIn();
    if (!mounted) return;
    context.go(AppRoutes.onboarding, extra: true);
  }

  void _onLoginTap() => context.go(AppRoutes.login);

  String? _serverError(AppLocalizations l10n, AuthFailureReason? reason) {
    if (reason == null) return null;
    switch (reason) {
      case AuthFailureReason.emailAlreadyInUse:
        return l10n.signupErrorEmailAlreadyInUse;
      case AuthFailureReason.invalidCredentials:
      case AuthFailureReason.emailNotConfirmed:
      case AuthFailureReason.unknown:
        return l10n.loginErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;

    // Clean celestial scene (no baked text) so the wordmark and panel can be
    // laid out precisely — moon for the dark theme, sun for the light theme.
    // Same assets as the login screen.
    final bgAsset = isDark
        ? 'assets/images/astra_dark_plain.png'
        : 'assets/images/astra_sun_bg_g5.png';

    final errorMessage =
        _formError ?? _serverError(l10n, authState.failureReason);

    final wordmarkColor = isDark ? _goldSoft : const Color(0xFF6B4A12);
    final taglineColor =
        isDark ? const Color(0xE6EAD9A8) : const Color(0xCC5A481F);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'astra_bg',
            child: Image.asset(bgAsset, fit: BoxFit.cover),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ResponsiveContent(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Back to login.
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    _CircleBack(onTap: () =>
                                        Navigator.of(context).maybePop()),
                                  ],
                                ),
                              ),
                              SizedBox(height: constraints.maxHeight * 0.02),
                              // ASTRA wordmark
                              Text(
                                'ASTRA',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cinzel(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 6,
                                  color: wordmarkColor,
                                  shadows: [
                                    Shadow(
                                      color: (isDark ? _gold : Colors.white)
                                          .withValues(alpha: 0.55),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isTr
                                    ? '“Yıldızların ışığı, içindeki evreni aydınlatır.”'
                                    : '“The light of the stars illuminates the universe within.”',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.philosopher(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: taglineColor,
                                ),
                              ),
                              const Spacer(flex: 2),
                              _animated(
                                  _buildPanel(isTr, authState, errorMessage)),
                              const Spacer(flex: 1),
                              // Kriz desteği (her zaman erişilebilir).
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => CrisisSupportSheet.show(context),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 6, bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.health_and_safety_outlined,
                                          size: 15,
                                          color: _goldSoft),
                                      const SizedBox(width: 6),
                                      Text(
                                        isTr ? 'Kriz desteği' : 'Crisis support',
                                        style: GoogleFonts.philosopher(
                                          fontSize: 13,
                                          color: _goldSoft,
                                          shadows: const [
                                            Shadow(
                                                color: Color(0xAA000000),
                                                blurRadius: 8),
                                          ],
                                        ),
                                      ),
                                    ],
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _animated(Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.18, 0.85, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  Widget _buildPanel(
      bool isTr, AuthState authState, String? errorMessage) {
    final loading = authState.isSubmitting || _isGoogleSubmitting;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1A24).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isTr ? 'Hesap Oluştur' : 'Create Account',
                  style: GoogleFonts.philosopher(
                    color: _goldSoft,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 18),

              Text(isTr ? 'Adınız' : 'Your Name', style: _labelStyle()),
              const SizedBox(height: 8),
              _StarField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 16),

              Text(isTr ? 'Mail Adresiniz' : 'Your Email', style: _labelStyle()),
              const SizedBox(height: 8),
              _StarField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 16),

              Text(isTr ? 'Şifreniz' : 'Your Password', style: _labelStyle()),
              const SizedBox(height: 8),
              _StarField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                trailing: _visibilityToggle(
                  obscured: _obscurePassword,
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),

              Text(isTr ? 'Şifre (Tekrar)' : 'Confirm Password',
                  style: _labelStyle()),
              const SizedBox(height: 8),
              _StarField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _onCreateAccountPressed(),
                trailing: _visibilityToggle(
                  obscured: _obscureConfirmPassword,
                  onTap: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),

              // Error (client validation or server failure)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: errorMessage == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _buildError(errorMessage),
                      ),
              ),
              const SizedBox(height: 24),

              // Hesap Oluştur
              _GoldButton(
                label: isTr ? 'Hesap Oluştur' : 'Create Account',
                isLoading: loading,
                onTap: _onCreateAccountPressed,
              ),
              const SizedBox(height: 16),

              // Google
              GoogleSignInButton(
                label: isTr ? 'Google ile devam et' : 'Continue with Google',
                isLoading: _isGoogleSubmitting,
                onPressed: _onGoogleSignInPressed,
              ),
              const SizedBox(height: 22),

              // Giriş yap
              Center(
                child: GestureDetector(
                  onTap: _onLoginTap,
                  behavior: HitTestBehavior.opaque,
                  child: RichText(
                    text: TextSpan(
                      text: isTr
                          ? 'Zaten hesabın var mı? '
                          : 'Already have an account? ',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      children: [
                        TextSpan(
                          text: isTr ? 'Giriş yap' : 'Sign in',
                          style: const TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: _gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visibilityToggle({required bool obscured, required VoidCallback onTap}) {
    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: _gold.withValues(alpha: 0.85),
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  TextStyle _labelStyle() => GoogleFonts.philosopher(
        color: _gold,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  Widget _buildError(String message) {
    const errorColor = Color(0xFFE07A7A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: errorColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small gold-outlined circular back button — matches the login/signup palette.
class _CircleBack extends StatelessWidget {
  const _CircleBack({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: _gold.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 17, color: _goldSoft),
      ),
    );
  }
}

/// Gold-bordered input box with three sparkle stars shown while empty — the
/// exact box from the login design, made into a real text field.
class _StarField extends StatelessWidget {
  const _StarField({
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final rightPad = trailing != null ? 46.0 : 18.0;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onSubmitted: onSubmitted,
            textAlign: TextAlign.start,
            style: GoogleFonts.philosopher(color: Colors.white, fontSize: 15),
            cursorColor: _gold,
            decoration: InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.only(left: 18, right: rightPad),
            ),
          ),
          // Sparkle stars only while the field is empty.
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.isNotEmpty) return const SizedBox.shrink();
                  const star =
                      Icon(Icons.star, color: Color(0x80D4AF37), size: 16);
                  return Padding(
                    padding: EdgeInsets.only(left: 18, right: rightPad),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [star, star, star],
                    ),
                  );
                },
              ),
            ),
          ),
          if (trailing != null)
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(child: trailing),
            ),
        ],
      ),
    );
  }
}

/// Gold gradient button with a loading state — identical to login's.
class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [_goldSoft, _goldDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.philosopher(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
