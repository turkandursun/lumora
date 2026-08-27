import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    show AuthState;

import '../../../../core/providers/astra_palette_provider.dart';
import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/luma_animated_avatar.dart';
import '../../../../theme/responsive_content.dart';
import '../../../profile/data/profile_repository.dart';
import '../../domain/auth_flow_routes.dart';
import '../../domain/registration_flow_state.dart';
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
  bool _didRouteAfterGoogleSignIn = false;
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
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (_isGoogleSignInFlow && state.event == AuthChangeEvent.signedIn) {
        _isGoogleSignInFlow = false;
        _routeAfterGoogleSignIn();
      }
    });
    // Web OAuth can recreate this screen after a full-page redirect. The
    // one-shot persisted OAuth origin is consumed by the same guarded helper.
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_routeAfterGoogleSignIn());
      });
    }
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
    final result = await ref
        .read(authControllerProvider.notifier)
        .signUpWithPassword(email: email, password: password);
    if (!result.succeeded || !mounted) return;

    final userId = result.userId;
    if (userId == null) return;
    final intent = await registrationFlowStore.begin(userId);
    if (!mounted) return;

    if (!result.hasSession) {
      // Email confirmation is enabled: keep the user-scoped pending step, but
      // never enter authenticated onboarding without a real session. The next
      // successful login restores this exact account's registration.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).loginErrorEmailNotConfirmed,
          ),
        ),
      );
      context.go(AppRoutes.login);
      return;
    }

    // Fresh account: wipe any local data left by a previous account on this
    // device so the new user starts clean and account-isolated.
    await ref.read(cloudBackupServiceProvider).onSignIn();
    await bootstrapAstraPaletteForCurrentUser(ref);
    if (!mounted) return;
    // Privacy Policy + Terms acceptance gate, then the normal onboarding flow.
    context.go(AppRoutes.privacyConsent, extra: intent);
  }

  Future<void> _onGoogleSignInPressed() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isGoogleSubmitting = true;
      _isGoogleSignInFlow = true;
    });
    await registrationFlowStore.clearOAuthLoginAttempt();
    await registrationFlowStore.markOAuthSignupAttempt();
    final launched =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _isGoogleSubmitting = false;
      if (!launched) {
        _isGoogleSignInFlow = false;
        unawaited(registrationFlowStore.clearOAuthSignupAttempt());
      }
    });
  }

  /// OAuth emits the same `signedIn` event for new and existing accounts.
  /// Only a user created during this sign-up attempt receives onboarding;
  /// returning Google users continue through the normal login flow.
  Future<void> _routeAfterGoogleSignIn() async {
    if (_didRouteAfterGoogleSignIn) return;
    _didRouteAfterGoogleSignIn = true;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _didRouteAfterGoogleSignIn = false;
      return;
    }
    final signupAttemptStartedAt =
        await registrationFlowStore.consumeOAuthSignupAttemptStartedAt();
    final isFreshSignup = AuthFlowRoutes.shouldBeginFreshOAuthRegistration(
      signupAttemptStartedAt: signupAttemptStartedAt,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
      evaluatedAt: DateTime.now(),
    );
    final FreshRegistrationIntent? intent;
    if (isFreshSignup) {
      try {
        await ProfileRepository().initializeFreshProfileDefaults(user.id);
      } catch (error) {
        debugPrint(
          '[Auth] Fresh Google profile initialization deferred '
          'type=${error.runtimeType}',
        );
      }
      intent = await registrationFlowStore.begin(user.id);
    } else {
      // An existing account must not be enrolled again, but a genuinely
      // unfinished registration (for example after email confirmation) still
      // resumes its own persisted, user-scoped step.
      intent = await registrationFlowStore.restore(user.id);
    }

    await ref.read(cloudBackupServiceProvider).onSignIn();
    await bootstrapAstraPaletteForCurrentUser(ref);
    if (!mounted) return;
    if (isFreshSignup && intent != null) {
      // Privacy Policy + Terms acceptance gate before onboarding.
      context.go(AppRoutes.privacyConsent, extra: intent);
    } else {
      context.go(
        AuthFlowRoutes.greeting,
        extra: const LumaGreetingRouteData.returning(),
      );
    }
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
    // The registration screen always presents in the light theme, even when the
    // rest of the app is in dark mode. We override this subtree's palette tokens
    // to the always-light variant and render everything below it, so every
    // context-driven AstraKit colour resolves light regardless of app theme.
    final basePalette = ref.watch(activePaletteProvider);
    final lightTokens =
        AstraThemeTokens.fromPalette(basePalette, brightness: Brightness.light);
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [lightTokens],
      ),
      child: Builder(
        builder: (context) => _buildContent(context, basePalette),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AstraPalette palette) {
    const isDark = false;
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

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
                final compact = constraints.maxHeight < 760;
                final lumaSize = (constraints.maxWidth * 0.27).clamp(
                  90.0,
                  compact ? 96.0 : 110.0,
                );
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
                                    _CircleBack(
                                        onTap: () =>
                                            Navigator.of(context).maybePop()),
                                  ],
                                ),
                              ),
                              SizedBox(height: compact ? 0 : 4),
                              AstraEntrance(
                                index: 0,
                                intervalMs: 130,
                                offset: 20,
                                child: Center(
                                  child: LumaAnimatedAvatar(size: lumaSize),
                                ),
                              ),
                              SizedBox(height: compact ? 0 : 4),
                              AstraEntrance(
                                index: 1,
                                intervalMs: 130,
                                offset: 20,
                                child: Text('ASTRA',
                                    textAlign: TextAlign.center,
                                    style: AstraKit.wordmark(context, false,
                                        fontSize: 38)),
                              ),
                              const SizedBox(height: 6),
                              AstraEntrance(
                                index: 2,
                                intervalMs: 130,
                                offset: 20,
                                child: Text(
                                  isTr
                                      ? 'Kendine bir alan aç.'
                                      : 'Make space for yourself.',
                                  textAlign: TextAlign.center,
                                  style: AstraKit.mutedText(context, false,
                                      fontSize: 13.5),
                                ),
                              ),
                              const Spacer(),
                              _animated(_buildPanel(context, isDark, isTr,
                                  authState, errorMessage)),
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
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  Widget _buildPanel(BuildContext context, bool isDark, bool isTr,
      AuthState authState, String? errorMessage) {
    final loading = authState.isSubmitting || _isGoogleSubmitting;
    final gold = AstraKit.gold(context, isDark);

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
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
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
                  style: AstraKit.mutedText(context, isDark, fontSize: 13.5),
                  children: [
                    TextSpan(
                      text: isTr ? 'Giriş yap' : 'Sign in',
                      style: AstraKit.body(context, isDark,
                              fontSize: 13.5, color: gold)
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
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
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
