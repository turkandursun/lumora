import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../domain/auth_validation.dart';
import '../../domain/password_recovery.dart';
import '../providers/auth_provider.dart';

/// OTP-based password recovery. The e-mail template must expose Supabase's
/// eight-digit recovery token; this flow intentionally has no redirect URL.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _cooldown = RecoveryResendCooldown();

  late final PasswordRecoveryCoordinator _coordinator;
  Timer? _cooldownTimer;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _submitting = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email.trim();
    _coordinator = PasswordRecoveryCoordinator(
      gateway: ref.read(passwordRecoveryGatewayProvider),
    );
    if (_emailController.text.isNotEmpty) _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldown.start();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cooldown.tick();
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (_cooldown.canResend) timer.cancel();
    });
  }

  String _validationMessage(
    AppLocalizations l10n,
    PasswordRecoveryValidationIssue issue,
  ) {
    return switch (issue) {
      PasswordRecoveryValidationIssue.emailRequired =>
        l10n.forgotPasswordEmailRequired,
      PasswordRecoveryValidationIssue.emailInvalid =>
        l10n.forgotPasswordEmailInvalid,
      PasswordRecoveryValidationIssue.otpInvalid =>
        l10n.resetPasswordOtpInvalid,
      PasswordRecoveryValidationIssue.passwordRequired =>
        l10n.resetPasswordPasswordRequired,
      PasswordRecoveryValidationIssue.passwordTooShort =>
        l10n.resetPasswordPasswordTooShort(authMinimumPasswordLength),
      PasswordRecoveryValidationIssue.confirmationRequired =>
        l10n.resetPasswordConfirmationRequired,
      PasswordRecoveryValidationIssue.passwordMismatch =>
        l10n.resetPasswordMismatch,
    };
  }

  Future<void> _resend() async {
    if (_submitting || _resending || !_cooldown.canResend) return;
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _snack(l10n.forgotPasswordEmailRequired);
      return;
    }
    if (!isValidAuthEmail(email)) {
      _snack(l10n.forgotPasswordEmailInvalid);
      return;
    }

    setState(() => _resending = true);
    try {
      await ref.read(passwordRecoveryGatewayProvider).requestCode(email);
      if (!mounted) return;
      passwordRecoveryFlowStore.begin(email);
      _startCooldown();
      _snack(l10n.forgotPasswordRequestSuccess);
    } catch (_) {
      _snack(l10n.forgotPasswordRequestError);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final otp = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmation = _confirmationController.text;
    final validationIssue = validatePasswordRecoveryInput(
      email: email,
      otp: otp,
      password: password,
      confirmation: confirmation,
    );
    if (validationIssue != null) {
      _snack(_validationMessage(l10n, validationIssue));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final wasWaitingForVerification = !_coordinator.isVerified;
    try {
      await _coordinator.complete(
        email: email,
        otp: otp,
        password: password,
      );
      if (!mounted) return;
      _snack(l10n.resetPasswordSuccess);
      context.go(AppRoutes.login);
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(wasWaitingForVerification && !_coordinator.isVerified
          ? l10n.resetPasswordInvalidOrExpired
          : l10n.resetPasswordUpdateError);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(l10n.resetPasswordUpdateError);
    }
  }

  void _leaveRecovery() {
    if (_submitting) return;
    passwordRecoveryFlowStore.cancel();
    context.go(AppRoutes.login);
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required Color primary,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      counterText: '',
      labelText: label,
      labelStyle: AstraKit.mutedText(context, isDark, fontSize: 13),
      prefixIcon: Icon(icon, color: primary, size: 20),
      suffixIcon: suffixIcon,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AstraKit.muted(context, isDark).withValues(alpha: 0.4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final fieldsEnabled = !_submitting && !_coordinator.isVerified;
    final passwordFieldsEnabled =
        !_submitting && !_coordinator.isPasswordUpdated;
    final canResend = !_submitting &&
        !_resending &&
        !_coordinator.isVerified &&
        _cooldown.canResend;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveRecovery();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AstraMountainBackground(
          isDark: isDark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ListView(
                children: [
                  Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: _leaveRecovery,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.resetPasswordTitle,
                        style: AstraKit.heading1(
                          context,
                          isDark,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AstraGlassCard(
                    isDark: isDark,
                    primaryColor: primary,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    borderRadius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.resetPasswordIntro,
                          style: AstraKit.body(
                            context,
                            isDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _emailController,
                          enabled: fieldsEnabled,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          style: AstraKit.body(
                            context,
                            isDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: primary,
                          decoration: _fieldDecoration(
                            label: l10n.resetPasswordEmailLabel,
                            icon: Icons.mail_outline_rounded,
                            primary: primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _codeController,
                          enabled: fieldsEnabled,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          maxLength: passwordRecoveryOtpLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: AstraKit.body(
                            context,
                            isDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ).copyWith(letterSpacing: 4),
                          cursorColor: primary,
                          decoration: _fieldDecoration(
                            label: l10n.resetPasswordOtpLabel,
                            icon: Icons.pin_rounded,
                            primary: primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          enabled: passwordFieldsEnabled,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          style: AstraKit.body(
                            context,
                            isDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: primary,
                          decoration: _fieldDecoration(
                            label: l10n.resetPasswordNewPasswordLabel,
                            icon: Icons.lock_outline_rounded,
                            primary: primary,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AstraKit.muted(context, isDark),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmationController,
                          enabled: passwordFieldsEnabled,
                          obscureText: _obscureConfirmation,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => _submit(),
                          style: AstraKit.body(
                            context,
                            isDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          cursorColor: primary,
                          decoration: _fieldDecoration(
                            label: l10n.resetPasswordConfirmPasswordLabel,
                            icon: Icons.lock_reset_rounded,
                            primary: primary,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AstraKit.muted(context, isDark),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.resetPasswordUpdateAction,
                                    style: AstraKit.body(
                                      context,
                                      isDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ).copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: canResend ? _resend : null,
                            child: _resending
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primary,
                                    ),
                                  )
                                : Text(
                                    _cooldown.canResend
                                        ? l10n.resetPasswordResendAction
                                        : l10n.resetPasswordResendCountdown(
                                            _cooldown.remainingSeconds,
                                          ),
                                    style: AstraKit.body(
                                      context,
                                      isDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ).copyWith(color: primary),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
