import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/app_lock/domain/app_section.dart';

enum _PinAttemptOutcome { success, wrong, lockedOut }

/// Result of a single [AppLockService.attemptUnlock] call — either the PIN
/// matched, it didn't (with attempts remaining before a cooldown kicks in),
/// or a prior cooldown is still in effect.
class PinAttemptResult {
  const PinAttemptResult._(this._outcome, {this.attemptsRemaining, this.lockoutRemaining});

  const PinAttemptResult.success() : this._(_PinAttemptOutcome.success);

  const PinAttemptResult.wrong(int attemptsRemaining)
      : this._(_PinAttemptOutcome.wrong, attemptsRemaining: attemptsRemaining);

  const PinAttemptResult.lockedOut(Duration lockoutRemaining)
      : this._(_PinAttemptOutcome.lockedOut, lockoutRemaining: lockoutRemaining);

  final _PinAttemptOutcome _outcome;

  /// Wrong-PIN guesses left before the cooldown starts. Only set when
  /// [_outcome] is [_PinAttemptOutcome.wrong].
  final int? attemptsRemaining;

  /// Time left before another attempt is allowed. Only set when [_outcome]
  /// is [_PinAttemptOutcome.lockedOut].
  final Duration? lockoutRemaining;

  bool get isSuccess => _outcome == _PinAttemptOutcome.success;
  bool get isLockedOut => _outcome == _PinAttemptOutcome.lockedOut;
}

/// Owns App Lock's persisted state via [FlutterSecureStorage]: a single
/// salted-hashed PIN (never the PIN itself) and the set of [AppSection]s it
/// protects. Also tracks failed-attempt cooldown in memory — shared across
/// every section's PIN screen since they all check the same underlying PIN.
class AppLockService {
  AppLockService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _pinHashKey = 'app_lock_pin_hash';
  static const _pinSaltKey = 'app_lock_pin_salt';
  static const _protectedSectionsKey = 'app_lock_protected_sections';

  static const maxAttempts = 5;
  static const lockoutDuration = Duration(seconds: 30);
  static const minPinLength = 4;
  static const maxPinLength = 6;

  final FlutterSecureStorage _storage;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Hashes and persists [pin] — used both for first-time setup and
  /// "change PIN" (which verifies the old PIN separately before calling
  /// this). Clears any in-progress cooldown so a just-changed PIN isn't
  /// immediately unusable.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hash(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
    _failedAttempts = 0;
    _lockoutUntil = null;
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final storedHash = await _storage.read(key: _pinHashKey);
    if (salt == null || storedHash == null) return false;
    return _hash(pin, salt) == storedHash;
  }

  /// Time left on an active cooldown, or `null` if none is in effect. Also
  /// clears an expired cooldown as a side effect, so callers never need to
  /// separately "reset" it once time has passed.
  Duration? get lockoutRemaining {
    final until = _lockoutUntil;
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    if (!remaining.isNegative) return remaining;
    _lockoutUntil = null;
    _failedAttempts = 0;
    return null;
  }

  /// Verifies [pin], tracking consecutive wrong guesses and imposing a
  /// [lockoutDuration] cooldown after [maxAttempts] failures in a row.
  Future<PinAttemptResult> attemptUnlock(String pin) async {
    final activeLockout = lockoutRemaining;
    if (activeLockout != null) return PinAttemptResult.lockedOut(activeLockout);

    final correct = await verifyPin(pin);
    if (correct) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      return const PinAttemptResult.success();
    }

    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _lockoutUntil = DateTime.now().add(lockoutDuration);
      _failedAttempts = 0;
      return const PinAttemptResult.lockedOut(lockoutDuration);
    }
    return PinAttemptResult.wrong(maxAttempts - _failedAttempts);
  }

  Future<Set<AppSection>> getProtectedSections() async {
    final raw = await _storage.read(key: _protectedSectionsKey);
    if (raw == null || raw.isEmpty) return {};
    return raw
        .split(',')
        .map(AppSectionStorageKey.fromStorageKey)
        .whereType<AppSection>()
        .toSet();
  }

  Future<void> setSectionProtected(AppSection section, bool protected) async {
    final current = await getProtectedSections();
    final next = {...current};
    if (protected) {
      next.add(section);
    } else {
      next.remove(section);
    }
    await _storage.write(
      key: _protectedSectionsKey,
      value: next.map((s) => s.storageKey).join(','),
    );
  }

  String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
