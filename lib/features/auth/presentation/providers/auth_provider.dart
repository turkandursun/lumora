import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Owns email/password sign-in against Supabase auth. Magic-link login
/// will be added here later — this only wires up the password flow.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._client) : super(const AuthState());

  final SupabaseClient _client;

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

  Future<bool> signUpWithPassword({
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
        return false;
      }
      state = state.copyWith(status: AuthStatus.idle);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: _signUpReasonFor(e),
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
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      state = state.copyWith(status: AuthStatus.idle);
      return true;
    } on AuthException catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        failureReason: AuthFailureReason.unknown,
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

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(supabaseClientProvider));
});
