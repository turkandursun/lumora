import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/account_deletion_service.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_de.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_en.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_es.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_fr.dart';
import 'package:mindful_journal/l10n/generated/app_localizations_tr.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('account deletion copy is localized for all supported languages', () {
    final localizations = [
      AppLocalizationsTr(),
      AppLocalizationsEn(),
      AppLocalizationsDe(),
      AppLocalizationsEs(),
      AppLocalizationsFr(),
    ];
    for (final l10n in localizations) {
      expect(l10n.profileMenuDeleteAccount, isNotEmpty);
      expect(l10n.accountDeletionFinalBody, isNotEmpty);
      expect(l10n.accountDeletionFirstBody, contains('ASTRA'));
      expect(l10n.accountDeletionFirstBody.toLowerCase(),
          isNot(contains('lumora')));
    }
  });

  test('authenticated invocation returns the captured account id', () async {
    String? receivedToken;
    final service = AccountDeletionService.testing(
      currentUserIdProvider: () => 'user-a',
      accessTokenProvider: () async => 'access-token',
      functionInvoker: (token) async {
        receivedToken = token;
        return {'deleted': true};
      },
    );

    expect(await service.deleteRemoteAccount(), 'user-a');
    expect(receivedToken, 'access-token');
  });

  test('missing auth or unsuccessful response fails safely', () async {
    final unauthenticated = AccountDeletionService.testing(
      currentUserIdProvider: () => null,
      accessTokenProvider: () async => null,
      functionInvoker: (_) async => {'deleted': true},
    );
    await expectLater(
      unauthenticated.deleteRemoteAccount(),
      throwsA(isA<AccountDeletionException>()),
    );

    final failed = AccountDeletionService.testing(
      currentUserIdProvider: () => 'user-a',
      accessTokenProvider: () async => 'token',
      functionInvoker: (_) async => {'error': 'failed'},
    );
    await expectLater(
      failed.deleteRemoteAccount(),
      throwsA(isA<AccountDeletionException>()),
    );
  });

  test('server failure preserves local cache and session', () async {
    var localCleanupCalls = 0;
    var sessionClearCalls = 0;
    final guard = AccountDeletionGuard();
    final coordinator = AccountDeletionCoordinator(
      deleteRemoteAccount: () => throw const AccountDeletionException(),
      clearLocalAccount: (_) async => localCleanupCalls++,
      clearLocalSession: () async => sessionClearCalls++,
      guard: guard,
    );

    await expectLater(
      coordinator.deleteAccount(),
      throwsA(isA<AccountDeletionException>()),
    );
    expect(localCleanupCalls, 0);
    expect(sessionClearCalls, 0);
    expect(guard.isInProgress, isFalse);
  });

  test('deleted-user 403 is accepted only after local session is cleared',
      () async {
    var sessionExists = true;
    var persistedSessionExists = true;
    final cleaner = DeletedAccountLocalSessionCleaner(
      signOutLocal: () async {
        sessionExists = false;
        throw const AuthApiException(
          'User from sub claim in JWT does not exist',
          statusCode: '403',
          code: 'user_not_found',
        );
      },
      removePersistedSession: () async {
        persistedSessionExists = false;
      },
      isLocalSessionCleared: () => !sessionExists,
    );

    await cleaner.clear();

    expect(sessionExists, isFalse);
    expect(persistedSessionExists, isFalse,
        reason: 'A restart must not restore the deleted account token.');
  });

  test('deleted-user 403 is not accepted while session is still present',
      () async {
    var persistedRemovalCalls = 0;
    final cleaner = DeletedAccountLocalSessionCleaner(
      signOutLocal: () => throw const AuthApiException(
        'User from sub claim in JWT does not exist',
        statusCode: '403',
        code: 'user_not_found',
      ),
      removePersistedSession: () async => persistedRemovalCalls++,
      isLocalSessionCleared: () => false,
    );

    await expectLater(cleaner.clear(), throwsA(isA<AuthApiException>()));
    expect(persistedRemovalCalls, 0);
  });

  test('unrelated auth 403 is never swallowed', () async {
    var persistedRemovalCalls = 0;
    final cleaner = DeletedAccountLocalSessionCleaner(
      signOutLocal: () => throw const AuthApiException(
        'Permission denied for another reason',
        statusCode: '403',
        code: 'permission_denied',
      ),
      removePersistedSession: () async => persistedRemovalCalls++,
      isLocalSessionCleared: () => true,
    );

    await expectLater(cleaner.clear(), throwsA(isA<AuthApiException>()));
    expect(persistedRemovalCalls, 0);
  });

  test('successful sign-out must leave the in-memory session empty', () async {
    final cleaner = DeletedAccountLocalSessionCleaner(
      signOutLocal: () async {},
      removePersistedSession: () async {},
      isLocalSessionCleared: () => false,
    );

    await expectLater(
      cleaner.clear(),
      throwsA(isA<AccountDeletionLocalSessionException>()),
    );
  });

  test('success clears local cache then local auth session', () async {
    final operations = <String>[];
    final coordinator = AccountDeletionCoordinator(
      deleteRemoteAccount: () async {
        operations.add('remote');
        return 'user-a';
      },
      clearLocalAccount: (userId) async {
        operations.add('local:$userId');
      },
      clearLocalSession: () async => operations.add('session'),
    );

    await coordinator.deleteAccount();
    expect(operations, ['remote', 'local:user-a', 'session']);
  });

  test('concurrent double tap shares one deletion operation', () async {
    final release = Completer<void>();
    var remoteCalls = 0;
    var cleanupCalls = 0;
    var sessionCalls = 0;
    final coordinator = AccountDeletionCoordinator(
      deleteRemoteAccount: () async {
        remoteCalls++;
        await release.future;
        return 'user-a';
      },
      clearLocalAccount: (_) async => cleanupCalls++,
      clearLocalSession: () async => sessionCalls++,
    );

    final first = coordinator.deleteAccount();
    final second = coordinator.deleteAccount();
    expect(remoteCalls, 1);
    release.complete();
    await Future.wait([first, second]);

    expect(remoteCalls, 1);
    expect(cleanupCalls, 1);
    expect(sessionCalls, 1);
  });

  test('deletion guard stays active for the whole single-flight operation',
      () async {
    final release = Completer<void>();
    final guard = AccountDeletionGuard();
    final coordinator = AccountDeletionCoordinator(
      deleteRemoteAccount: () async {
        await release.future;
        return 'user-a';
      },
      clearLocalAccount: (_) async {},
      clearLocalSession: () async {},
      guard: guard,
    );

    final operation = coordinator.deleteAccount();
    expect(guard.isInProgress, isTrue,
        reason: 'Backup/sync entry points use this guard to skip new work.');

    release.complete();
    await operation;
    expect(guard.isInProgress, isFalse);
  });

  test('local cleanup error still clears the deleted account session',
      () async {
    var sessionCalls = 0;
    final coordinator = AccountDeletionCoordinator(
      deleteRemoteAccount: () async => 'user-a',
      clearLocalAccount: (_) => throw StateError('disk failure'),
      clearLocalSession: () async => sessionCalls++,
    );

    await expectLater(coordinator.deleteAccount(), throwsStateError);
    expect(sessionCalls, 1);
  });
}
