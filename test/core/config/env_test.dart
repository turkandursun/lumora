import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/config/env.dart';
import 'package:mindful_journal/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Google OAuth redirect', () {
    test('web uses the current origin including its development port', () {
      final redirect = Env.googleOAuthRedirect(
        isWeb: true,
        currentUri: Uri.parse(
          'http://localhost:3000/signup?source=google#oauth',
        ),
      );

      expect(redirect, 'http://localhost:3000');
    });

    test('web production callback keeps https origin and drops route state',
        () {
      final redirect = Env.googleOAuthRedirect(
        isWeb: true,
        currentUri: Uri.parse('https://app.astra.example/login?next=home'),
      );

      expect(redirect, 'https://app.astra.example');
    });

    test('mobile uses the registered Lumora deep-link contract', () {
      expect(
        Env.googleOAuthRedirect(
          isWeb: false,
          currentUri: Uri.parse('http://localhost:3000'),
        ),
        'lumora://login-callback/',
      );
    });

    test('invalid web base fails locally instead of using a dashboard fallback',
        () {
      expect(
        () => Env.googleOAuthRedirect(
          isWeb: true,
          currentUri: Uri.parse('file:///index.html'),
        ),
        throwsStateError,
      );
    });

    test('cancelled OAuth launch fails safely without throwing', () async {
      final client = SupabaseClient('http://localhost:54321', 'test-key');
      final controller = AuthController(
        client,
        googleOAuthLauncher: (_) async => false,
      );
      addTearDown(client.dispose);

      await expectLater(controller.signInWithGoogle(), completion(isFalse));
      expect(controller.state.status, AuthStatus.error);
      expect(controller.state.failureReason, AuthFailureReason.unknown);
    });
  });
}
