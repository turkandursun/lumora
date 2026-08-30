import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_journal/features/auth/domain/auth_validation.dart';
import 'package:mindful_journal/features/auth/domain/password_recovery.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_de.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_en.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_es.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_fr.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_tr.dart';

void main() {
  group('password recovery validation', () {
    PasswordRecoveryValidationIssue? validate({
      String email = 'person@example.com',
      String otp = '12345678',
      String password = 'password8',
      String confirmation = 'password8',
    }) {
      return validatePasswordRecoveryInput(
        email: email,
        otp: otp,
        password: password,
        confirmation: confirmation,
      );
    }

    test('empty and invalid email are rejected', () {
      expect(
        validate(email: '   '),
        PasswordRecoveryValidationIssue.emailRequired,
      );
      expect(
        validate(email: 'not-an-email'),
        PasswordRecoveryValidationIssue.emailInvalid,
      );
    });

    test('OTP must contain exactly eight digits', () {
      expect(
        validate(otp: '123456'),
        PasswordRecoveryValidationIssue.otpInvalid,
      );
      expect(
        validate(otp: '1234567'),
        PasswordRecoveryValidationIssue.otpInvalid,
      );
      expect(
        validate(otp: '12345678'),
        isNull,
      );
      expect(
        validate(otp: '123456789'),
        PasswordRecoveryValidationIssue.otpInvalid,
      );
      expect(
        validate(otp: '1234a678'),
        PasswordRecoveryValidationIssue.otpInvalid,
      );
    });

    test('blank and short passwords are rejected at the shared minimum', () {
      expect(authMinimumPasswordLength, 8);
      expect(
        validate(password: '        ', confirmation: '        '),
        PasswordRecoveryValidationIssue.passwordRequired,
      );
      expect(
        validate(password: '1234567', confirmation: '1234567'),
        PasswordRecoveryValidationIssue.passwordTooShort,
      );
    });

    test('confirmation is required and must match exactly', () {
      expect(
        validate(confirmation: ''),
        PasswordRecoveryValidationIssue.confirmationRequired,
      );
      expect(
        validate(confirmation: 'password9'),
        PasswordRecoveryValidationIssue.passwordMismatch,
      );
      expect(validate(), isNull);
    });
  });

  group('password recovery coordinator', () {
    test('valid OTP updates password, signs out, and clears recovery guard',
        () async {
      final store = PasswordRecoveryFlowStore()..begin('person@example.com');
      final gateway = _FakeRecoveryGateway(observedStore: store);
      final coordinator = PasswordRecoveryCoordinator(
        gateway: gateway,
        flowStore: store,
      );

      await coordinator.complete(
        email: 'person@example.com',
        otp: '12345678',
        password: 'password8',
      );

      expect(gateway.calls, ['verify', 'update', 'signOut']);
      expect(gateway.recoveryWasActiveDuringSignOut, isFalse);
      expect(store.isActive, isFalse);
      expect(store.phase, PasswordRecoveryPhase.completed);
      expect(
        store.redirectFor(
          currentLocation: '/login',
          recoveryLocation: '/reset-password',
          loginLocation: '/login',
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('verify failure stays in recovery and never updates or signs out',
        () async {
      final store = PasswordRecoveryFlowStore();
      final gateway = _FakeRecoveryGateway(
        failVerify: true,
        observedStore: store,
      );
      final coordinator = PasswordRecoveryCoordinator(
        gateway: gateway,
        flowStore: store,
      );

      await expectLater(
        coordinator.complete(
          email: 'person@example.com',
          otp: '12345678',
          password: 'password8',
        ),
        throwsStateError,
      );

      expect(gateway.calls, ['verify']);
      expect(store.isActive, isTrue);
      expect(store.phase, PasswordRecoveryPhase.verifyingOtp);
    });

    test('update failure cannot report completion and retry reuses OTP session',
        () async {
      final store = PasswordRecoveryFlowStore();
      final gateway = _FakeRecoveryGateway(
        failUpdate: true,
        observedStore: store,
      );
      final coordinator = PasswordRecoveryCoordinator(
        gateway: gateway,
        flowStore: store,
      );

      await expectLater(
        coordinator.complete(
          email: 'person@example.com',
          otp: '12345678',
          password: 'password8',
        ),
        throwsStateError,
      );
      expect(store.isActive, isTrue);
      expect(store.phase, PasswordRecoveryPhase.updatingPassword);

      gateway.failUpdate = false;
      await coordinator.complete(
        email: 'person@example.com',
        otp: '12345678',
        password: 'password8',
      );

      expect(gateway.calls, ['verify', 'update', 'update', 'signOut']);
      expect(store.isActive, isFalse);
    });

    test('sign-out failure is retried without repeating password update',
        () async {
      final store = PasswordRecoveryFlowStore();
      final gateway = _FakeRecoveryGateway(
        failSignOut: true,
        observedStore: store,
      );
      final coordinator = PasswordRecoveryCoordinator(
        gateway: gateway,
        flowStore: store,
      );

      await expectLater(
        coordinator.complete(
          email: 'person@example.com',
          otp: '12345678',
          password: 'password8',
        ),
        throwsStateError,
      );
      expect(store.isActive, isTrue);
      expect(store.phase, PasswordRecoveryPhase.awaitingSignOutRetry);

      gateway.failSignOut = false;
      await coordinator.complete(
        email: 'person@example.com',
        otp: '12345678',
        password: 'password8',
      );

      expect(gateway.calls, ['verify', 'update', 'signOut', 'signOut']);
      expect(gateway.recoveryWasActiveDuringSignOut, isFalse);
      expect(store.isActive, isFalse);
      expect(store.phase, PasswordRecoveryPhase.completed);
    });
  });

  test('active recovery always redirects normal authenticated routes', () {
    final store = PasswordRecoveryFlowStore()..begin('person@example.com');

    expect(
      store.redirectFor(
        currentLocation: '/home',
        recoveryLocation: '/reset-password',
        loginLocation: '/login',
        isAuthenticated: true,
      ),
      '/reset-password',
    );
    expect(
      store.redirectFor(
        currentLocation: '/reset-password',
        recoveryLocation: '/reset-password',
        loginLocation: '/login',
        isAuthenticated: true,
      ),
      isNull,
    );
  });

  test('only an explicit normal-auth action clears terminal recovery', () {
    final store = PasswordRecoveryFlowStore()..begin('person@example.com');

    store.prepareForNormalAuthentication();
    expect(store.phase, PasswordRecoveryPhase.awaitingOtp);
    expect(store.blocksNormalAuthRouting, isTrue);

    store.complete();
    expect(store.phase, PasswordRecoveryPhase.completed);
    expect(store.blocksNormalAuthRouting, isTrue);

    store.prepareForNormalAuthentication();
    expect(store.phase, PasswordRecoveryPhase.idle);
    expect(store.blocksNormalAuthRouting, isFalse);
  });

  testWidgets(
      'signedOut refresh reaches login and late recovery auth cannot resurrect',
      (tester) async {
    final store = PasswordRecoveryFlowStore()..begin('person@example.com');
    final authRefresh = ChangeNotifier();
    addTearDown(authRefresh.dispose);
    var isAuthenticated = false;

    final router = GoRouter(
      initialLocation: '/reset-password',
      refreshListenable: authRefresh,
      redirect: (context, state) => store.redirectFor(
        currentLocation: state.matchedLocation,
        recoveryLocation: '/reset-password',
        loginLocation: '/login',
        isAuthenticated: isAuthenticated,
      ),
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const Text('reset-password'),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Text('login'),
        ),
      ],
    );
    addTearDown(router.dispose);
    final gateway = _FakeRecoveryGateway(
      observedStore: store,
      onVerify: () {
        isAuthenticated = true;
        authRefresh.notifyListeners();
      },
      onSignOut: () {
        isAuthenticated = false;
        authRefresh.notifyListeners();
      },
    );
    final coordinator = PasswordRecoveryCoordinator(
      gateway: gateway,
      flowStore: store,
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('reset-password'), findsOneWidget);

    await coordinator.complete(
      email: 'person@example.com',
      otp: '12345678',
      password: 'password8',
    );
    await tester.pumpAndSettle();

    expect(gateway.calls, ['verify', 'update', 'signOut']);
    expect(store.phase, PasswordRecoveryPhase.completed);
    expect(find.text('login'), findsOneWidget);
    expect(find.text('reset-password'), findsNothing);
    expect(router.canPop(), isFalse);

    // Simulate a late passwordRecovery/signedIn auth refresh. It can refresh
    // the router but cannot reopen the terminal recovery flow or route.
    isAuthenticated = true;
    authRefresh.notifyListeners();
    await tester.pumpAndSettle();
    expect(store.phase, PasswordRecoveryPhase.completed);
    expect(find.text('login'), findsOneWidget);
    expect(find.text('reset-password'), findsNothing);
  });

  testWidgets('login replacement leaves no stale recovery page to pop',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const Text('reset-password'),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Text('login'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('reset-password'), findsOneWidget);

    router.go('/login');
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('reset-password'), findsNothing);
    expect(router.canPop(), isFalse);
  });

  test('resend cooldown blocks requests for 60 ticks', () {
    final cooldown = RecoveryResendCooldown();
    cooldown.start();
    expect(cooldown.remainingSeconds, 60);
    expect(cooldown.canResend, isFalse);

    for (var i = 0; i < 59; i++) {
      cooldown.tick();
    }
    expect(cooldown.remainingSeconds, 1);
    expect(cooldown.canResend, isFalse);

    cooldown.tick();
    expect(cooldown.canResend, isTrue);
  });

  test('all supported locales use a non-enumerating request result', () {
    final messages = [
      AppLocalizationsTr().forgotPasswordRequestSuccess,
      AppLocalizationsEn().forgotPasswordRequestSuccess,
      AppLocalizationsDe().forgotPasswordRequestSuccess,
      AppLocalizationsEs().forgotPasswordRequestSuccess,
      AppLocalizationsFr().forgotPasswordRequestSuccess,
    ];

    for (final message in messages) {
      expect(message, isNotEmpty);
    }
    expect(messages[0], contains('kayıtlıysa'));
    expect(messages[1], contains('If this email is registered'));
  });
}

class _FakeRecoveryGateway implements PasswordRecoveryGateway {
  _FakeRecoveryGateway({
    this.failVerify = false,
    this.failUpdate = false,
    this.failSignOut = false,
    this.observedStore,
    this.onVerify,
    this.onSignOut,
  });

  bool failVerify;
  bool failUpdate;
  bool failSignOut;
  final PasswordRecoveryFlowStore? observedStore;
  final void Function()? onVerify;
  final void Function()? onSignOut;
  bool? recoveryWasActiveDuringSignOut;
  final List<String> calls = [];

  @override
  Future<void> requestCode(String email) async {
    calls.add('request');
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    calls.add('verify');
    if (failVerify) throw StateError('verify failed');
    onVerify?.call();
  }

  @override
  Future<void> updatePassword(String password) async {
    calls.add('update');
    if (failUpdate) throw StateError('update failed');
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    recoveryWasActiveDuringSignOut = observedStore?.isActive;
    if (failSignOut) throw StateError('sign-out failed');
    onSignOut?.call();
  }
}
