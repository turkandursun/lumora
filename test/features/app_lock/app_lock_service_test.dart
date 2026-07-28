import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/app_lock_service.dart';
import 'package:mindful_journal/features/app_lock/domain/app_section.dart';

/// In-memory stand-in for the secure-storage backing store — no real
/// platform channel available under `flutter test`. Only the
/// storage-touching methods are overridden; [AppLockService.attemptUnlock]
/// and [AppLockService.lockoutRemaining] are the real, unmodified
/// production logic (they only depend on [verifyPin], which is overridden
/// below).
class _InMemoryAppLockService extends AppLockService {
  String? _pin;
  Set<AppSection> _protected = {};

  @override
  Future<bool> hasPin() async => _pin != null;

  @override
  Future<void> setPin(String pin) async => _pin = pin;

  @override
  Future<bool> verifyPin(String pin) async => _pin != null && _pin == pin;

  @override
  Future<Set<AppSection>> getProtectedSections() async => _protected;

  @override
  Future<void> setSectionProtected(AppSection section, bool protected) async {
    _protected = protected ? {..._protected, section} : ({..._protected}..remove(section));
  }
}

void main() {
  late _InMemoryAppLockService service;

  setUp(() {
    service = _InMemoryAppLockService();
  });

  group('PIN setup and verification', () {
    test('no PIN set: hasPin is false and verifyPin always fails', () async {
      expect(await service.hasPin(), isFalse);
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('setPin then verifyPin: correct PIN succeeds, wrong PIN fails', () async {
      await service.setPin('1234');
      expect(await service.hasPin(), isTrue);
      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
    });

    test('supports 4 to 6 digit PINs', () async {
      await service.setPin('123456');
      expect(await service.verifyPin('123456'), isTrue);
      expect(await service.verifyPin('12345'), isFalse);
    });
  });

  group('protected sections', () {
    test('defaults to empty', () async {
      expect(await service.getProtectedSections(), isEmpty);
    });

    test('toggling a section on persists it; toggling off removes it', () async {
      await service.setSectionProtected(AppSection.journalWriting, true);
      expect(await service.getProtectedSections(), {AppSection.journalWriting});

      await service.setSectionProtected(AppSection.aiChat, true);
      expect(
        await service.getProtectedSections(),
        {AppSection.journalWriting, AppSection.aiChat},
      );

      await service.setSectionProtected(AppSection.journalWriting, false);
      expect(await service.getProtectedSections(), {AppSection.aiChat});
    });
  });

  group('attempt cooldown (shared across all sections, same underlying PIN)', () {
    test('correct PIN on first try succeeds', () async {
      await service.setPin('1234');
      final result = await service.attemptUnlock('1234');
      expect(result.isSuccess, isTrue);
    });

    test('wrong PIN reports decreasing attempts remaining', () async {
      await service.setPin('1234');
      final first = await service.attemptUnlock('0000');
      expect(first.isSuccess, isFalse);
      expect(first.isLockedOut, isFalse);
      expect(first.attemptsRemaining, AppLockService.maxAttempts - 1);

      final second = await service.attemptUnlock('1111');
      expect(second.attemptsRemaining, AppLockService.maxAttempts - 2);
    });

    test('locks out after maxAttempts consecutive wrong guesses', () async {
      await service.setPin('1234');
      for (var i = 0; i < AppLockService.maxAttempts - 1; i++) {
        final result = await service.attemptUnlock('0000');
        expect(result.isLockedOut, isFalse);
      }
      final locking = await service.attemptUnlock('0000');
      expect(locking.isLockedOut, isTrue);
      expect(locking.lockoutRemaining, isNotNull);

      // Even the CORRECT PIN is rejected while a lockout is active.
      final duringLockout = await service.attemptUnlock('1234');
      expect(duringLockout.isLockedOut, isTrue);
    });

    test('a correct guess resets the failed-attempt counter', () async {
      await service.setPin('1234');
      await service.attemptUnlock('0000');
      await service.attemptUnlock('0000');
      final success = await service.attemptUnlock('1234');
      expect(success.isSuccess, isTrue);

      final afterReset = await service.attemptUnlock('0000');
      expect(afterReset.attemptsRemaining, AppLockService.maxAttempts - 1);
    });
  });
}
