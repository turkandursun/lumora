import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    show AuthState;

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_storage_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/pastel_auth.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

const _minPasswordLength = 8;
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Lumora's sign-up screen — the same gold-on-moonlit-mountain ASTRA look
/// as login and the rest of the app, so the account-creation flow doesn't
/// feel like a different app from what's behind it.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _onboardingStorage = OnboardingStorageService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleSubmitting = false;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Google sign-in redirects the whole page away on web, so this
    // screen's own await never resumes there — instead we listen for the
    // session Supabase detects once the browser returns (or, on native,
    // once the system browser hands control back to the running app).
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _routeAfterGoogleSignIn();
      }
    });
  }

  Animation<double> _fade(double start, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade(start, end));
  }

  Widget _animated(double start, double end, Widget child) {
    return FadeTransition(
      opacity: _fade(start, end),
      child: SlideTransition(position: _slide(start, end), child: child),
    );
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .signUpWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );
    if (!success || !mounted) return;

    await _onboardingStorage.setOnboardingIncomplete();
    if (!mounted) return;
    context.go(AppRoutes.lumaOnboarding);
  }

  Future<void> _onGoogleSignInPressed() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSubmitting = true);
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleSubmitting = false);
  }

  /// Google sign-in from the sign-up screen is treated as a new signup: meet
  /// Luma, run onboarding, then pick hobbies. (Returning users normally use
  /// the login screen's Google button, which skips the hobbies step.)
  Future<void> _routeAfterGoogleSignIn() async {
    if (!mounted) return;
    context.go(AppRoutes.lumaOnboarding);
  }

  void _onLoginTap() {
    context.go(AppRoutes.login);
  }

  String _errorMessage(AppLocalizations l10n, AuthFailureReason reason) {
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
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.gold(isDark);
    final disclaimer = isTr
        ? 'Bu bir terapi hizmeti değildir. Profesyonel destek için 112\'yi arayabilirsin.'
        : 'This is not a therapy service. For professional support, you can call 112.';

    // Same branded scene as the tap-through landing screen (ASTRA wordmark,
    // tagline and moon/sun already baked into the artwork) — the shared
    // Hero tag makes navigating here read as one continuous page.
    final bgAsset = isDark ? 'assets/images/astra_dark.png' : 'assets/images/astra_sun_entry_g3.png';

    return Scaffold(
      // Kept false so the background never resizes/gaps when the keyboard
      // opens — the scroll view below adds its own bottom inset instead.
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'astra_bg',
            child: Image.asset(bgAsset, fit: BoxFit.cover),
          ),
          Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          AstraCircleIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            isDark: isDark,
                            primaryColor: primary,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                              26, 0, 26, 12 + MediaQuery.viewInsetsOf(context).bottom),
                          child: ResponsiveContent(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Reserves space for the wordmark/moon
                                  // already painted into the background.
                                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.32),
                                  _animated(0.18, 0.75, _buildFormCard(authState, isDark, primary)),
                                  const SizedBox(height: 20),
                                  _animated(0.35, 0.9, _buildFooter(isDark, primary)),
                                  _animated(
                                    0.4,
                                    0.95,
                                    PastelCrisisLink(
                                      label: isTr ? 'Kriz desteği' : 'Crisis support',
                                      accentColor: primary,
                                      textStyle: ({fontSize = 15, fontWeight = FontWeight.w500, color = Colors.black}) =>
                                          AstraKit.body(isDark, fontSize: fontSize, fontWeight: fontWeight, color: color),
                                      onTap: () => CrisisSupportSheet.show(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: AuthDisclaimerBanner(
                    message: disclaimer,
                    highlight: '112',
                    accentColor: primary,
                    textColor: AstraKit.ink(isDark),
                    fillColor: isDark ? const Color(0xCC1A1233) : const Color(0xCCFFF8EE),
                    borderColor: primary.withValues(alpha: 0.35),
                    textStyle: ({fontSize = 12.5, color = Colors.black}) =>
                        AstraKit.body(isDark, fontSize: fontSize, color: color),
                    onTap: () => CrisisSupportSheet.show(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AuthState authState, bool isDark, Color primary) {
    final l10n = AppLocalizations.of(context);
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 28,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.signupTitle, textAlign: TextAlign.center, style: AstraKit.heading1(isDark, fontSize: 24)),
          const SizedBox(height: 22),
          AstraTextField(
            isDark: isDark,
            primaryColor: primary,
            label: l10n.signupNameHint,
            controller: _nameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          AstraTextField(
            isDark: isDark,
            primaryColor: primary,
            label: l10n.loginEmailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            prefixIcon: Icons.mail_outline_rounded,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return l10n.loginEmailValidationEmpty;
              if (!_emailRegex.hasMatch(email)) return l10n.loginEmailValidationInvalid;
              return null;
            },
          ),
          const SizedBox(height: 16),
          AstraTextField(
            isDark: isDark,
            primaryColor: primary,
            label: l10n.loginPasswordHint,
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: Icons.lock_outline_rounded,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AstraKit.muted(isDark),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.isEmpty) return l10n.loginPasswordValidationEmpty;
              if (password.length < _minPasswordLength) {
                return l10n.signupPasswordValidationTooShort;
              }
              return null;
            },
          ),
          _buildPasswordHelper(isDark, primary),
          const SizedBox(height: 16),
          AstraTextField(
            isDark: isDark,
            primaryColor: primary,
            label: l10n.signupConfirmPasswordHint,
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: Icons.lock_outline_rounded,
            onFieldSubmitted: (_) => _onCreateAccountPressed(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AstraKit.muted(isDark),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              final confirm = value ?? '';
              if (confirm.isEmpty) return l10n.signupConfirmPasswordValidationEmpty;
              if (confirm != _passwordController.text) {
                return l10n.signupConfirmPasswordValidationMismatch;
              }
              return null;
            },
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: authState.failureReason == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildErrorMessage(_errorMessage(l10n, authState.failureReason!), isDark),
                  ),
          ),
          const SizedBox(height: 22),
          AstraGoldButton(
            isDark: isDark,
            forceGold: true,
            label: l10n.signupButtonLabel,
            isLoading: authState.isSubmitting || _isGoogleSubmitting,
            onTap: _onCreateAccountPressed,
          ),
          const SizedBox(height: 22),
          AstraLabeledDivider(isDark: isDark, label: l10n.authOrDivider, primaryColor: primary),
          const SizedBox(height: 22),
          GoogleSignInButton(
            label: l10n.authContinueWithGoogle,
            isLoading: _isGoogleSubmitting,
            onPressed: _onGoogleSignInPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message, bool isDark) {
    const errorColor = Color(0xFFE07A7A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: errorColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AstraKit.body(isDark, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordHelper(bool isDark, Color primary) {
    final l10n = AppLocalizations.of(context);
    final meetsLength = _passwordController.text.length >= _minPasswordLength;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(
            meetsLength ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 14,
            color: meetsLength ? primary : AstraKit.muted(isDark),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.signupPasswordHelper,
            style: AstraKit.mutedText(isDark, fontSize: 12.5).copyWith(
              color: meetsLength ? primary : AstraKit.muted(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, Color primary) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.signupLoginPrompt,
          style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        TextButton(
          onPressed: _onLoginTap,
          child: Text(
            l10n.loginButtonLabel,
            style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w700, color: primary),
          ),
        ),
      ],
    );
  }
}
