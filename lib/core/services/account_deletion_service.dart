import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException();
}

class AccountDeletionLocalSessionException implements Exception {
  const AccountDeletionLocalSessionException();
}

typedef AccountDeletionFunctionInvoker = Future<Object?> Function(
  String accessToken,
);

typedef LocalSessionSignOut = Future<void> Function();
typedef PersistedSessionRemover = Future<void> Function();
typedef LocalSessionClearedProbe = bool Function();

@visibleForTesting
bool isExpectedDeletedAccountAuthError(Object error) {
  if (error is! AuthException || error.statusCode != '403') return false;
  final code = error.code?.toLowerCase();
  final message = error.message.toLowerCase();
  return code == 'user_not_found' ||
      message.contains('user_not_found') ||
      message.contains('user from sub claim in jwt does not exist');
}

/// Clears the deleted account from Supabase's in-memory and persisted session.
///
/// GoTrue's public local sign-out API clears local state before its best-effort
/// `/logout` request. Some SDK/server combinations can still surface the
/// expected `user_not_found` response after the Edge Function deleted the Auth
/// user. Only that exact post-delete condition is tolerated; all unrelated auth
/// failures remain visible to the caller.
class DeletedAccountLocalSessionCleaner {
  DeletedAccountLocalSessionCleaner({
    required LocalSessionSignOut signOutLocal,
    required PersistedSessionRemover removePersistedSession,
    required LocalSessionClearedProbe isLocalSessionCleared,
  })  : _signOutLocal = signOutLocal,
        _removePersistedSession = removePersistedSession,
        _isLocalSessionCleared = isLocalSessionCleared;

  final LocalSessionSignOut _signOutLocal;
  final PersistedSessionRemover _removePersistedSession;
  final LocalSessionClearedProbe _isLocalSessionCleared;

  Future<void> clear() async {
    try {
      await _signOutLocal();
    } catch (error) {
      if (!isExpectedDeletedAccountAuthError(error) ||
          !_isLocalSessionCleared()) {
        rethrow;
      }
    }

    // SupabaseAuth also removes this on the signedOut event. Calling the same
    // public storage API explicitly makes the restart guarantee deterministic
    // even if the event listener is still completing asynchronously.
    await _removePersistedSession();
    if (!_isLocalSessionCleared()) {
      throw const AccountDeletionLocalSessionException();
    }
  }
}

/// Prevents account-bound cloud work from being started while permanent
/// deletion is in progress.
class AccountDeletionGuard {
  bool _isInProgress = false;

  bool get isInProgress => _isInProgress;

  void begin() => _isInProgress = true;
  void end() => _isInProgress = false;
}

/// Authenticated transport for the `delete-account` Edge Function.
///
/// The client never sends a user id. The returned id is captured from the
/// authenticated client before the server removes the Auth user and is used
/// only to scope local cleanup after a successful server response.
class AccountDeletionService {
  AccountDeletionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _currentUserIdProvider = null,
        _accessTokenProvider = null,
        _functionInvoker = null;

  @visibleForTesting
  AccountDeletionService.testing({
    required String? Function() currentUserIdProvider,
    required Future<String?> Function() accessTokenProvider,
    required AccountDeletionFunctionInvoker functionInvoker,
  })  : _client = null,
        _currentUserIdProvider = currentUserIdProvider,
        _accessTokenProvider = accessTokenProvider,
        _functionInvoker = functionInvoker;

  static const _sessionReadyTimeout = Duration(seconds: 5);

  final SupabaseClient? _client;
  final String? Function()? _currentUserIdProvider;
  final Future<String?> Function()? _accessTokenProvider;
  final AccountDeletionFunctionInvoker? _functionInvoker;

  Future<String> deleteRemoteAccount() async {
    final userId =
        _currentUserIdProvider?.call() ?? _client?.auth.currentUser?.id;
    if (userId == null) throw const AccountDeletionException();

    final String? accessToken;
    if (_accessTokenProvider != null) {
      accessToken = await _accessTokenProvider();
    } else {
      await _ensureSessionReady();
      accessToken = _client?.auth.currentSession?.accessToken;
    }
    if (accessToken == null) throw const AccountDeletionException();

    try {
      final Object? data;
      if (_functionInvoker != null) {
        data = await _functionInvoker(accessToken);
      } else {
        final client = _client;
        if (client == null) throw const AccountDeletionException();
        final response = await client.functions.invoke(
          'delete-account',
          headers: {'Authorization': 'Bearer $accessToken'},
          body: const <String, dynamic>{},
        );
        data = response.data;
      }
      if (data is! Map || data['deleted'] != true) {
        throw const AccountDeletionException();
      }
      return userId;
    } on AccountDeletionException {
      rethrow;
    } catch (_) {
      throw const AccountDeletionException();
    }
  }

  Future<bool> _ensureSessionReady() async {
    final client = _client;
    if (client == null) return false;
    if (client.auth.currentSession != null) return true;
    try {
      final state = await client.auth.onAuthStateChange
          .firstWhere((state) => state.session != null)
          .timeout(_sessionReadyTimeout);
      return state.session != null;
    } catch (_) {
      return false;
    }
  }
}

/// Makes the irreversible server operation and the post-success device cleanup
/// one single-flight action. Server failure never touches local state.
class AccountDeletionCoordinator {
  AccountDeletionCoordinator({
    required Future<String> Function() deleteRemoteAccount,
    required Future<void> Function(String userId) clearLocalAccount,
    required Future<void> Function() clearLocalSession,
    AccountDeletionGuard? guard,
  })  : _deleteRemoteAccount = deleteRemoteAccount,
        _clearLocalAccount = clearLocalAccount,
        _clearLocalSession = clearLocalSession,
        _guard = guard ?? AccountDeletionGuard();

  final Future<String> Function() _deleteRemoteAccount;
  final Future<void> Function(String userId) _clearLocalAccount;
  final Future<void> Function() _clearLocalSession;
  final AccountDeletionGuard _guard;
  Future<void>? _inFlight;

  Future<void> deleteAccount() {
    final existing = _inFlight;
    if (existing != null) return existing;
    _guard.begin();
    late final Future<void> operation;
    operation = _run().whenComplete(() {
      _guard.end();
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<void> _run() async {
    final userId = await _deleteRemoteAccount();
    Object? cleanupError;
    StackTrace? cleanupStackTrace;
    try {
      await _clearLocalAccount(userId);
    } catch (error, stackTrace) {
      cleanupError = error;
      cleanupStackTrace = stackTrace;
    }
    // The remote Auth identity no longer exists. Clear the cached session even
    // if an unusual local I/O error occurred, then surface that error so the UI
    // can route to login without claiming the account still exists.
    await _clearLocalSession();
    if (cleanupError != null) {
      Error.throwWithStackTrace(cleanupError, cleanupStackTrace!);
    }
  }
}
