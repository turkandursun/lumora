import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    show AuthState;

import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/responsive_content.dart';
import '../../domain/auth_flow_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

const _minPasswordLength = 8;
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Soft gold used by the small in-panel crisis-support link.
const _goldSoft = Color(0xFFE5C890);

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleSubmitting = false;
  bool _isGoogleSignInFlow = false;
  String? _formError;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    // Google sign-in redirects the whole page away on web, so this screen's
    // own await never resumes there — instead we listen for the session
    // Supabase detects once the browser returns (or, on native, once the
    // system browser hands control back to the running app).
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) {
      if (_isGoogleSignInFlow && state.event == AuthChangeEvent.signedIn) {
        _isGoogleSignInFlow = false;
        _routeAfterGoogleSignIn();
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onCreateAccountPressed() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? error;
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
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

    // The name is collected on the next screen so this panel stays short enough
    // to show the ASTRA wordmark + tagline.
    final success = await ref
        .read(authControllerProvider.notifier)
        .signUpWithPassword(email: email, password: password);
    if (!success || !mounted) return;

    // Fresh account: wipe any local data left by a previous account on this
    // device so the new user starts clean and account-isolated.
    await ref.read(cloudBackupServiceProvider).onSignIn();
    if (!mounted) return;
    context.go(
      AuthFlowRoutes.afterAuthentication(
        AuthFlowOrigin.freshPasswordSignup,
      ),
      extra: true,
    );
  }

  Future<void> _onGoogleSignInPressed() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isGoogleSubmitting = true;
      _isGoogleSignInFlow = true;
    });
    final launched =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _isGoogleSubmitting = false;
      if (!launched) _isGoogleSignInFlow = false;
    });
  }

  /// OAuth emits the same `signedIn` event for new and existing accounts.
  /// Only a user created during this sign-up attempt receives onboarding;
  /// returning Google users continue through the normal login flow.
  Future<void> _routeAfterGoogleSignIn() async {
    await ref.read(cloudBackupServiceProvider).onSignIn();
    if (!mounted) return;
    final isFreshSignup = AuthFlowRoutes.isFreshOAuthAccount(
      createdAt: Supabase.instance.client.auth.currentUser?.createdAt,
    );
    final origin = isFreshSignup
        ? AuthFlowOrigin.freshOAuthSignup
        : AuthFlowOrigin.existingLogin;
    context.go(
      AuthFlowRoutes.afterAuthentication(origin),
      extra: isFreshSignup ? true : null,
    );
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

    // Background follows the user's chosen palette so the auth screens match
    // the rest of the app.
    final palette = ref.watch(activePaletteProvider);

    final errorMessage =
        _formError ?? _serverError(l10n, authState.failureReason);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: palette.backgroundGradient),
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
                              // The scene's baked ASTRA wordmark + moon fill the
                              // top; this spacer drops the panel into the empty
                              // lower area, keeping the wordmark above it.
                              const Spacer(),
                              _animated(_buildPanel(
                                  isDark, isTr, authState, errorMessage)),
                              const SizedBox(height: 12),
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
      bool isDark, bool isTr, AuthState authState, String? errorMessage) {
    final loading = authState.isSubmitting || _isGoogleSubmitting;
    final gold = AstraKit.gold(isDark);

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: gold,
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AstraTextField(
            isDark: isDark,
            primaryColor: gold,
            label: isTr ? 'Mail Adresiniz' : 'Your Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 14),
          AstraTextField(
            isDark: isDark,
            primaryColor: gold,
            label: isTr ? 'Şifreniz' : 'Your Password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: _visibilityToggle(
              obscured: _obscurePassword,
              color: gold,
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 14),
          AstraTextField(
            isDark: isDark,
            primaryColor: gold,
            label: isTr ? 'Şifre (Tekrar)' : 'Confirm Password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _onCreateAccountPressed(),
            suffixIcon: _visibilityToggle(
              obscured: _obscureConfirmPassword,
              color: gold,
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
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildError(errorMessage),
                  ),
          ),
          const SizedBox(height: 18),

          // Hesap Oluştur
          AstraGoldButton(
            isDark: isDark,
            forceGold: true,
            label: isTr ? 'Hesap Oluştur' : 'Create Account',
            isLoading: loading,
            onTap: _onCreateAccountPressed,
          ),
          const SizedBox(height: 12),

          // Google
          GoogleSignInButton(
            label: isTr ? 'Google ile devam et' : 'Continue with Google',
            isLoading: _isGoogleSubmitting,
            onPressed: _onGoogleSignInPressed,
          ),
          const SizedBox(height: 16),

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
                  style: AstraKit.mutedText(isDark, fontSize: 13.5),
                  children: [
                    TextSpan(
                      text: isTr ? 'Giriş yap' : 'Sign in',
                      style: AstraKit.body(isDark, fontSize: 13.5, color: gold)
                          .copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Kriz desteği — inside the panel so it never collides with the
          // scene's baked bottom line.
          Center(child: _CrisisSupportLink(isTr: isTr)),
        ],
      ),
    );
  }

  Widget _visibilityToggle({
    required bool obscured,
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: color.withValues(alpha: 0.85),
        size: 20,
      ),
      onPressed: onTap,
    );
  }

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

/// Crisis-support link (shield icon + label) that opens the support sheet.
/// Lives inside the panel so it stays clear of the scene's baked bottom line.
class _CrisisSupportLink extends StatelessWidget {
  const _CrisisSupportLink({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => CrisisSupportSheet.show(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.health_and_safety_outlined,
              size: 15, color: _goldSoft),
          const SizedBox(width: 6),
          Text(
            isTr ? 'Kriz desteği' : 'Crisis support',
            style: GoogleFonts.philosopher(fontSize: 13, color: _goldSoft),
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
          border: Border.all(color: _goldSoft.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 17, color: _goldSoft),
      ),
    );
  }
}


