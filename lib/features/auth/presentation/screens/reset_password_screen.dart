import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_screen_kit.dart';

/// Second half of the "forgot password" flow. The user has just been e-mailed
/// a 6-digit recovery code; here they enter that code plus a new password.
///
/// This uses OTP recovery ([OtpType.recovery]) rather than a magic-link/deep
/// link, so it works identically on web, Android and iOS with no deep-link or
/// redirect-URL configuration. On success the account's password is updated
/// and the user is sent back to the login screen to sign in fresh.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isTr => Localizations.localeOf(context).languageCode == 'tr';

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _resend() async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);
      _snack(_isTr
          ? 'Yeni bir kod mailine gönderildi.'
          : 'A new code has been sent to your email.');
    } catch (_) {
      _snack(_isTr
          ? 'Kod gönderilemedi, tekrar dene.'
          : 'Could not send the code, please try again.');
    }
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.length < 6) {
      _snack(_isTr
          ? 'Mailine gelen kodu gir.'
          : 'Enter the code from your email.');
      return;
    }
    if (password.length < 6) {
      _snack(_isTr
          ? 'Yeni şifren en az 6 karakter olmalı.'
          : 'Your new password must be at least 6 characters.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = Supabase.instance.client;
      // 1) Verify the recovery code — this opens a temporary session.
      await client.auth.verifyOTP(
        type: OtpType.recovery,
        email: widget.email,
        token: code,
      );
      // 2) Set the new password on that session.
      await client.auth.updateUser(UserAttributes(password: password));
      // 3) Sign out so the user logs in fresh with the new password.
      await client.auth.signOut();
      if (!mounted) return;
      _snack(_isTr
          ? 'Şifren güncellendi. Yeni şifrenle giriş yapabilirsin. 🌸'
          : 'Your password has been updated. You can sign in now. 🌸');
      context.go(AppRoutes.login);
    } on AuthException catch (_) {
      setState(() => _submitting = false);
      _snack(_isTr
          ? 'Kod hatalı veya süresi dolmuş. Kodu kontrol et ya da yenisini iste.'
          : 'The code is wrong or expired. Check it or request a new one.');
    } catch (_) {
      setState(() => _submitting = false);
      _snack(_isTr
          ? 'Bir şeyler ters gitti, tekrar dene.'
          : 'Something went wrong, please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    return Scaffold(
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
                      onTap: () => context.go(AppRoutes.login),
                    ),
                    const SizedBox(width: 12),
                    Text(_isTr ? 'Şifreyi Sıfırla' : 'Reset Password',
                        style: AstraKit.heading1(isDark, fontSize: 22)),
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
                        _isTr
                            ? '${widget.email} adresine gönderdiğimiz kodu gir ve yeni şifreni belirle.'
                            : 'Enter the code we sent to ${widget.email} and choose a new password.',
                        style: AstraKit.body(isDark, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: AstraKit.body(isDark, fontSize: 18, fontWeight: FontWeight.w700)
                            .copyWith(letterSpacing: 4),
                        cursorColor: primary,
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: _isTr ? 'Doğrulama kodu' : 'Verification code',
                          labelStyle: AstraKit.mutedText(isDark, fontSize: 13),
                          prefixIcon: Icon(Icons.pin_rounded, color: primary, size: 20),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 1.4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AstraKit.muted(isDark).withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w600),
                        cursorColor: primary,
                        decoration: InputDecoration(
                          labelText: _isTr ? 'Yeni şifre' : 'New password',
                          labelStyle: AstraKit.mutedText(isDark, fontSize: 13),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AstraKit.muted(isDark),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primary, width: 1.4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AstraKit.muted(isDark).withValues(alpha: 0.4)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isTr ? 'Şifreyi Güncelle' : 'Update Password',
                                  style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w800)
                                      .copyWith(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _submitting ? null : _resend,
                          child: Text(
                            _isTr ? 'Kodu tekrar gönder' : 'Resend code',
                            style: AstraKit.body(isDark, fontSize: 13, fontWeight: FontWeight.w700)
                                .copyWith(color: primary),
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
    );
  }
}
