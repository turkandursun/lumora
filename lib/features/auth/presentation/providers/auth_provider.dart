import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env.dart';
import '../../domain/password_recovery.dart';

typedef GoogleOAuthLauncher = Future<bool> Function(String redirectTo);

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

enum AuthStatus { idle, submitting, error }

/// Sign-in/sign-up failure categories. Kept string-free so the
/// presentation layer can map each reason to a localized, warm message.
enum AuthFailureReason {
  invalidCredentials,
  emailNotConfirmed,
  emailAlreadyInUse,
  unknown,
}

class AuthState {
  const AuthState({this.status = AuthStatus.idle, this.failureReason});

  final AuthStatus status;
  final AuthFailureReason? failureReason;

  bool get isSubmitting => status == AuthStatus.submitting;

  AuthState copyWith({
    required AuthStatus status,
    AuthFailureReason? failureReason,
  }) {
    return AuthState(status: status, failureReason: failureReason);
  }
}

class PasswordSignUpResult {
  const PasswordSignUpResult({
    required this.succeeded,
    this.userId,
    this.hasSession = false,
  });

  const PasswordSignUpResult.failure()
      : succeeded = false,
        userId = null,
        hasSession = false;

  final bool succeeded;
  final String? userId;
  final bool hasSession;
}

/// Owns email/password sign-in against Supabase auth. Magic-link login
/// will be added here later — this only wires up the password flow.
class AuthController extends StateNotifier<AuthState> {
  AuthController(
    this._client, {
    GoogleOAuthLauncher? googleOAuthLauncher,
  })  : _googleOAuthLauncher = googleOAuthLauncher,
        super(const AuthState());

  final SupabaseClient _client;
  final GoogleOAuthLauncher? _googleOAuthLauncher;

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.submitting);
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          failureReason: AuthFailureReason.unknown,
        );
        return false;
      }
      state = state.copyWith(status: AuthStatus.idle);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: _reasonFor(e),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: AuthFailureReason.unknown,
      );
      return false;
    }
  }

  AuthFailureReason _reasonFor(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return AuthFailureReason.invalidCredentials;
    }
    if (message.contains('email not confirmed')) {
      return AuthFailureReason.emailNotConfirmed;
    }
    return AuthFailureReason.unknown;
  }

  Future<PasswordSignUpResult> signUpWithPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.submitting);
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: (fullName == null || fullName.trim().isEmpty)
            ? null
            : {'full_name': fullName.trim()},
      );
      if (response.user == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          failureReason: AuthFailureReason.unknown,
        );
        return const PasswordSignUpResult.failure();
      }
      state = state.copyWith(status: AuthStatus.idle);
      return PasswordSignUpResult(
        succeeded: true,
        userId: response.user!.id,
        hasSession: response.session != null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: _signUpReasonFor(e),
      );
      return const PasswordSignUpResult.failure();
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: AuthFailureReason.unknown,
      );
      return const PasswordSignUpResult.failure();
    }
  }

  /// Kicks off Supabase's Google OAuth flow. This only launches the
  /// provider's consent screen — on web that's a full-page redirect away
  /// from the app, so it never resolves with a signed-in session here.
  /// The actual sign-in is observed later via `auth.onAuthStateChange`
  /// (see the login/sign up screens), which fires once Supabase detects
  /// the returning session, whether the app reloaded (web) or stayed
  /// alive (native).
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.submitting);
    try {
      final redirectTo = Env.googleOAuthRedirect(
        isWeb: kIsWeb,
        currentUri: kIsWeb ? Uri.base : null,
      );
      final launched = await (_googleOAuthLauncher?.call(redirectTo) ??
          _client.auth.signInWithOAuth(
            OAuthProvider.google,
            redirectTo: redirectTo,
          ));
      state = state.copyWith(
        status: launched ? AuthStatus.idle : AuthStatus.error,
        failureReason: launched ? null : AuthFailureReason.unknown,
      );
      return launched;
    } on AuthException catch (error) {
      debugPrint(
        '[Auth] Google sign-in failed type=${error.runtimeType}',
      );
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: AuthFailureReason.unknown,
      );
      return false;
    } catch (error) {
      debugPrint(
        '[Auth] Google sign-in failed type=${error.runtimeType}',
      );
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: AuthFailureReason.unknown,
      );
      return false;
    }
  }

  AuthFailureReason _signUpReasonFor(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already registered')) {
      return AuthFailureReason.emailAlreadyInUse;
    }
    return AuthFailureReason.unknown;
  }
}

class SupabasePasswordRecoveryGateway implements PasswordRecoveryGateway {
  SupabasePasswordRecoveryGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> requestCode(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email.trim(),
      token: otp.trim(),
      type: OtpType.recovery,
    );
    if (response.session == null) {
      throw const AuthException('Recovery session was not created.');
    }
  }

  @override
  Future<void> updatePassword(String password) =>
      _client.auth.updateUser(UserAttributes(password: password));

  @override
  Future<void> signOut() => _client.auth.signOut();
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(supabaseClientProvider));
});

final passwordRecoveryGatewayProvider = Provider<PasswordRecoveryGateway>(
  (ref) => SupabasePasswordRecoveryGateway(ref.watch(supabaseClientProvider)),
);
