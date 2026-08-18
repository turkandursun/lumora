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
import '../../domain/registration_flow_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Soft gold used by the small in-panel crisis-support link.
const _goldSoft = Color(0xFFE5C890);

/// Lumora's ASTRA login screen. The moon (dark theme) or sun (light theme)
/// celestial scene fills the background; over it sit the ASTRA wordmark and
/// tagline, a dark frosted-glass sign-in panel (email + password fields with
/// three sparkle stars, remember-me / forgot-password, a gold "Yolculuğa
/// Başla" button, a Google button and the sign-up link) and the bottom
/// "tap to begin" line. The whole scene switches with the chosen theme.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGoogleSubmitting = false;
  bool _obscurePassword = true;
  String? _formError;
  bool _didRouteAfterSignIn = false;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _routeAfterSignIn();
      }
    });
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_routeAfterSignIn());
      });
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onLoginPressed() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? error;
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      error = isTr ? 'Geçerli bir mail adresi gir.' : 'Enter a valid email.';
    } else if (password.isEmpty) {
      error = isTr ? 'Şifreni gir.' : 'Enter your password.';
    }
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() => _formError = null);
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithPassword(email: email, password: password);
    if (!success || !mounted) return;
    await _routeAfterSignIn();
  }

  Future<void> _onGoogleSignInPressed() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSubmitting = true);
    // A login-origin OAuth attempt can never create fresh-registration intent.
    await registrationFlowStore.clearOAuthSignupAttempt();
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleSubmitting = false);
  }

  Future<void> _onForgotPassword() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final email = _emailController.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      _showSnack(isTr
          ? 'Önce mail adresini yaz, sıfırlama bağlantısını oraya gönderelim.'
          : 'Enter your email first so we can send a reset link.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showSnack(isTr
          ? 'Mailine 6 haneli bir kod gönderildi.'
          : 'A 6-digit code has been sent to your email.');
      // Take the user to the code + new-password screen so the reset actually
      // completes inside the app (no deep link needed).
      context.push(AppRoutes.resetPassword, extra: email);
    } catch (_) {
      if (!mounted) return;
      _showSnack(isTr
          ? 'Bağlantı gönderilemedi, tekrar dene.'
          : 'Could not send the link, please try again.');
    }
  }

  Future<void> _routeAfterSignIn() async {
    if (_didRouteAfterSignIn) return;
    _didRouteAfterSignIn = true;
    await ref.read(cloudBackupServiceProvider).onSignIn();
    await bootstrapAstraPaletteForCurrentUser(ref);
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _didRouteAfterSignIn = false;
      return;
    }
    final intent = await registrationFlowStore.restore(userId);
    if (!mounted || Supabase.instance.client.auth.currentUser?.id != userId) {
      return;
    }
    if (intent != null) {
      context.go(
        AuthFlowRoutes.routeForRegistrationStep(intent.step),
        extra: AuthFlowRoutes.routeDataForRegistration(intent),
      );
      return;
    }
    context.go(
      AuthFlowRoutes.greeting,
      extra: const LumaGreetingRouteData.returning(),
    );
  }

  void _onSignUpTap() => context.go(AppRoutes.signup);

  String? _serverError(AppLocalizations l10n, AuthFailureReason? reason) {
    if (reason == null) return null;
    switch (reason) {
      case AuthFailureReason.invalidCredentials:
        return l10n.loginErrorInvalidCredentials;
      case AuthFailureReason.emailNotConfirmed:
        return l10n.loginErrorEmailNotConfirmed;
      case AuthFailureReason.emailAlreadyInUse:
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

    // Background follows the current reactive palette so the auth screens
    // match the rest of the app without mutable global theme state.
    final palette = AstraKit.palette(context);

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
                              const SizedBox(height: 54),
                              AstraEntrance(
                                index: 0,
                                intervalMs: 130,
                                offset: 20,
                                child: Text('ASTRA',
                                    textAlign: TextAlign.center,
                                    style: AstraKit.wordmark(context, false,
                                        fontSize: 40)),
                              ),
                              const SizedBox(height: 6),
                              AstraEntrance(
                                index: 1,
                                intervalMs: 130,
                                offset: 20,
                                child: Text(
                                  isTr
                                      ? 'Yaz. Konuş. Rahatla.'
                                      : 'Write. Talk. Breathe.',
                                  textAlign: TextAlign.center,
                                  style: AstraKit.mutedText(context, false,
                                      fontSize: 13.5),
                                ),
                              ),
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
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  Widget _buildPanel(
      bool isDark, bool isTr, AuthState authState, String? errorMessage) {
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _onLoginPressed(),
            suffixIcon: _visibilityToggle(
              obscured: _obscurePassword,
              color: gold,
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 10),

          // Şifremi unuttum (session is kept by Supabase; no misleading
          // "remember me" toggle that doesn't actually change behavior).
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _onForgotPassword,
                child: Text(
                  isTr ? 'Şifremi unuttum?' : 'Forgot password?',
                  style:
                      AstraKit.body(context, isDark, fontSize: 13, color: gold)
                          .copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: gold,
                  ),
                ),
              ),
            ],
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

          // Yolculuğa Başla
          AstraGoldButton(
            isDark: isDark,
            forceGold: true,
            label: isTr ? 'Yolculuğa Başla' : 'Begin the Journey',
            isLoading: loading,
            onTap: _onLoginPressed,
          ),
          const SizedBox(height: 12),

          // Google
          GoogleSignInButton(
            label: isTr ? 'Google ile giriş yap' : 'Sign in with Google',
            isLoading: _isGoogleSubmitting,
            onPressed: _onGoogleSignInPressed,
          ),
          const SizedBox(height: 16),

          // Kaydolun
          Center(
            child: GestureDetector(
              onTap: _onSignUpTap,
              behavior: HitTestBehavior.opaque,
              child: RichText(
                text: TextSpan(
                  text: isTr ? 'Hesabınız yok mu? ' : "Don't have an account? ",
                  style: AstraKit.mutedText(context, isDark, fontSize: 13.5),
                  children: [
                    TextSpan(
                      text: isTr ? 'Kaydolun' : 'Sign up',
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
/// Lives inside the sign-in / sign-up panels so it stays clear of the scene's
/// baked bottom line.
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
