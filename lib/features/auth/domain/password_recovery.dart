abstract interface class PasswordRecoveryGateway {
  Future<void> requestCode(String email);

  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  });

  Future<void> updatePassword(String password);

  Future<void> signOut();
}

/// Short-lived navigation state only. No OTP, password or recovery token is
/// persisted here. Its sole purpose is preventing the temporary recovery
/// session from entering the normal returning-user route flow.
enum PasswordRecoveryPhase {
  idle,
  awaitingOtp,
  verifyingOtp,
  updatingPassword,
  signingOut,
  awaitingSignOutRetry,
  completed,
}

class PasswordRecoveryFlowStore {
  PasswordRecoveryPhase _phase = PasswordRecoveryPhase.idle;
  String? _email;

  PasswordRecoveryPhase get phase => _phase;

  /// Whether navigation should remain locked to the reset-password screen.
  /// During sign-out this becomes false so the signedOut router refresh can
  /// deterministically replace recovery with Login.
  bool get isActive => switch (_phase) {
        PasswordRecoveryPhase.awaitingOtp ||
        PasswordRecoveryPhase.verifyingOtp ||
        PasswordRecoveryPhase.updatingPassword ||
        PasswordRecoveryPhase.awaitingSignOutRetry =>
          true,
        PasswordRecoveryPhase.idle ||
        PasswordRecoveryPhase.signingOut ||
        PasswordRecoveryPhase.completed =>
          false,
      };

  /// Temporary recovery auth events must not enter returning-user routing,
  /// including late events delivered while sign-out is finishing.
  bool get blocksNormalAuthRouting => _phase != PasswordRecoveryPhase.idle;

  String? get email => _email;

  void begin(String email) {
    _setEmail(email);
    _phase = PasswordRecoveryPhase.awaitingOtp;
  }

  String? redirectFor({
    required String currentLocation,
    required String recoveryLocation,
    required String loginLocation,
    required bool isAuthenticated,
  }) {
    if (isActive) {
      return currentLocation == recoveryLocation ? null : recoveryLocation;
    }
    if (currentLocation != recoveryLocation) return null;

    // A signedOut refresh can occur before the screen's awaited signOut call
    // resumes. Once the temporary session is gone, Login is authoritative.
    // An idle/completed direct visit is also never a valid recovery flow.
    if (_phase != PasswordRecoveryPhase.signingOut || !isAuthenticated) {
      return loginLocation;
    }
    return null;
  }

  void markVerifyingOtp(String email) {
    _setEmail(email);
    _phase = PasswordRecoveryPhase.verifyingOtp;
  }

  void markUpdatingPassword(String email) {
    _setEmail(email);
    _phase = PasswordRecoveryPhase.updatingPassword;
  }

  void markSigningOut(String email) {
    _setEmail(email);
    _phase = PasswordRecoveryPhase.signingOut;
  }

  void markSignOutRetry(String email) {
    _setEmail(email);
    _phase = PasswordRecoveryPhase.awaitingSignOutRetry;
  }

  void complete() {
    _phase = PasswordRecoveryPhase.completed;
    _email = null;
  }

  /// Clears the terminal recovery marker only for an explicit new normal-auth
  /// action. Merely rebuilding Login cannot let a delayed recovery auth event
  /// escape into returning-user routing.
  void prepareForNormalAuthentication() {
    if (_phase == PasswordRecoveryPhase.completed) {
      _phase = PasswordRecoveryPhase.idle;
    }
  }

  void cancel() {
    _phase = PasswordRecoveryPhase.idle;
    _email = null;
  }

  void _setEmail(String email) {
    final normalized = email.trim();
    if (normalized.isNotEmpty) _email = normalized;
  }
}

final passwordRecoveryFlowStore = PasswordRecoveryFlowStore();

/// Keeps recovery idempotent inside one screen lifetime. If password update or
/// sign-out fails after OTP verification, retrying does not consume the OTP a
/// second time or repeat an already successful password update.
class PasswordRecoveryCoordinator {
  PasswordRecoveryCoordinator({
    required PasswordRecoveryGateway gateway,
    PasswordRecoveryFlowStore? flowStore,
  })  : _gateway = gateway,
        _flowStore = flowStore ?? passwordRecoveryFlowStore;

  final PasswordRecoveryGateway _gateway;
  final PasswordRecoveryFlowStore _flowStore;
  bool _isVerified = false;
  bool _isPasswordUpdated = false;

  bool get isVerified => _isVerified;
  bool get isPasswordUpdated => _isPasswordUpdated;

  Future<void> complete({
    required String email,
    required String otp,
    required String password,
  }) async {
    if (!_isVerified) {
      _flowStore.markVerifyingOtp(email);
      await _gateway.verifyRecoveryOtp(email: email.trim(), otp: otp.trim());
      _isVerified = true;
    }
    if (!_isPasswordUpdated) {
      _flowStore.markUpdatingPassword(email);
      await _gateway.updatePassword(password);
      _isPasswordUpdated = true;
    }
    // Supabase emits signedOut while signOut is completing. Stop forcing the
    // reset route first, while still blocking late recovery signedIn events.
    _flowStore.markSigningOut(email);
    try {
      await _gateway.signOut();
    } catch (_) {
      // Password update already succeeded, but recovery is not complete until
      // the temporary session is safely closed. Keep the screen guarded so a
      // retry only repeats sign-out and cannot enter the normal auth flow.
      _flowStore.markSignOutRetry(email);
      rethrow;
    }
    _flowStore.complete();
  }
}

class RecoveryResendCooldown {
  RecoveryResendCooldown({this.durationSeconds = 60});

  final int durationSeconds;
  int _remainingSeconds = 0;

  int get remainingSeconds => _remainingSeconds;
  bool get canResend => _remainingSeconds == 0;

  void start() => _remainingSeconds = durationSeconds;

  void tick() {
    if (_remainingSeconds > 0) _remainingSeconds--;
  }
}
