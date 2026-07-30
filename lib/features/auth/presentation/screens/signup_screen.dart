import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase
    show AuthState;

import '../../../../core/router/app_router.dart';
import '../../../../core/services/onboarding_storage_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/pastel_auth.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/lumora_auth_decor.dart';

const _minPasswordLength = 8;
final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Lumora's sign-up screen — a soft pastel "cherry-blossom dawn" surface:
/// a bright blossom-path photo backdrop with a frosted-glass account card.
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
    final disclaimer = isTr
        ? 'Bu bir terapi hizmeti değildir. Profesyonel destek için 112\'yi arayabilirsin.'
        : 'This is not a therapy service. For professional support, you can call 112.';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3E6E9),
      body: PastelAuthBackground(
        bottomOverlay: AuthDisclaimerBanner(
          message: disclaimer,
          highlight: '112',
          onTap: () => CrisisSupportSheet.show(context),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
              child: ResponsiveContent(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _animated(0.0, 0.55, _buildBrand()),
                      const SizedBox(height: 26),
                      _animated(0.18, 0.75, _buildFormCard(authState)),
                      const SizedBox(height: 20),
                      _animated(0.35, 0.9, _buildFooter()),
                      _animated(
                        0.4,
                        0.95,
                        PastelCrisisLink(
                          label: isTr ? 'Kriz desteği' : 'Crisis support',
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
      ),
    );
  }

  Widget _buildBrand() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const SizedBox(height: 4),
        const Butterfly(),
        const SizedBox(height: 10),
        Text('ASTRA', textAlign: TextAlign.center, style: PastelAuthPalette.wordmark()),
        const SizedBox(height: 8),
        Text(
          l10n.signupTagline,
          textAlign: TextAlign.center,
          style: PastelAuthPalette.tagline(),
        ),
        const SizedBox(height: 12),
        Icon(Icons.favorite, size: 15, color: PastelAuthPalette.accent.withValues(alpha: 0.85)),
      ],
    );
  }

  Widget _buildFormCard(AuthState authState) {
    final l10n = AppLocalizations.of(context);
    return PastelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.signupTitle,
            textAlign: TextAlign.center,
            style: PastelAuthPalette.heading(),
          ),
          const SizedBox(height: 20),
          _buildNameField(),
          const SizedBox(height: 14),
          _buildEmailField(),
          const SizedBox(height: 14),
          _buildPasswordField(),
          _buildPasswordHelper(),
          const SizedBox(height: 14),
          _buildConfirmPasswordField(),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: authState.failureReason == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildErrorMessage(
                      _errorMessage(l10n, authState.failureReason!),
                    ),
                  ),
          ),
          const SizedBox(height: 22),
          PastelButton(
            label: l10n.signupButtonLabel,
            isLoading: authState.isSubmitting || _isGoogleSubmitting,
            onPressed: _onCreateAccountPressed,
          ),
          const SizedBox(height: 22),
          PastelLabeledDivider(label: l10n.authOrDivider),
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

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PastelAuthPalette.accentPink.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PastelAuthPalette.accentPink.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined, size: 16, color: PastelAuthPalette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: PastelAuthPalette.body(fontSize: 13, color: PastelAuthPalette.plumDeep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.name],
      style: PastelAuthPalette.body(color: PastelAuthPalette.plumDeep),
      cursorColor: PastelAuthPalette.accent,
      decoration: pastelFieldDecoration(
        hint: l10n.signupNameHint,
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildEmailField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      style: PastelAuthPalette.body(color: PastelAuthPalette.plumDeep),
      cursorColor: PastelAuthPalette.accent,
      decoration: pastelFieldDecoration(
        hint: l10n.loginEmailHint,
        icon: Icons.mail_outline_rounded,
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return l10n.loginEmailValidationEmpty;
        if (!_emailRegex.hasMatch(email)) return l10n.loginEmailValidationInvalid;
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      style: PastelAuthPalette.body(color: PastelAuthPalette.plumDeep),
      cursorColor: PastelAuthPalette.accent,
      onChanged: (_) => setState(() {}),
      decoration: pastelFieldDecoration(
        hint: l10n.loginPasswordHint,
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: PastelAuthPalette.plumMuted,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        final password = value ?? '';
        if (password.isEmpty) return l10n.loginPasswordValidationEmpty;
        if (password.length < _minPasswordLength) {
          return l10n.signupPasswordValidationTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordHelper() {
    final l10n = AppLocalizations.of(context);
    final meetsLength = _passwordController.text.length >= _minPasswordLength;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(
            meetsLength ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 14,
            color: meetsLength ? PastelAuthPalette.accent : PastelAuthPalette.plumMuted,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.signupPasswordHelper,
            style: PastelAuthPalette.body(
              fontSize: 12.5,
              color: meetsLength ? PastelAuthPalette.accent : PastelAuthPalette.plumMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      style: PastelAuthPalette.body(color: PastelAuthPalette.plumDeep),
      cursorColor: PastelAuthPalette.accent,
      onFieldSubmitted: (_) => _onCreateAccountPressed(),
      decoration: pastelFieldDecoration(
        hint: l10n.signupConfirmPasswordHint,
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: PastelAuthPalette.plumMuted,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ),
      validator: (value) {
        final confirm = value ?? '';
        if (confirm.isEmpty) return l10n.signupConfirmPasswordValidationEmpty;
        if (confirm != _passwordController.text) {
          return l10n.signupConfirmPasswordValidationMismatch;
        }
        return null;
      },
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.signupLoginPrompt,
          style: PastelAuthPalette.body(fontSize: 14, color: PastelAuthPalette.plumDeep),
        ),
        TextButton(
          onPressed: _onLoginTap,
          child: Text(
            l10n.loginButtonLabel,
            style: PastelAuthPalette.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PastelAuthPalette.accent,
            ),
          ),
        ),
      ],
    );
  }
}
