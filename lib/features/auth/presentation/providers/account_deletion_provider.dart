import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_auth_storage.dart';
import '../../../../core/providers/account_deletion_guard_provider.dart';
import '../../../../core/services/account_deletion_service.dart';
import '../../../../core/services/local_user_data_cleanup_service.dart';
import '../../../reminders/presentation/providers/reminders_providers.dart';
import 'auth_provider.dart';

final localUserDataCleanupServiceProvider =
    Provider<LocalUserDataCleanupService>((ref) {
  return LocalUserDataCleanupService(
    database: ref.watch(appDatabaseProvider),
    notifications: ref.watch(notificationServiceProvider),
  );
});

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(client: ref.watch(supabaseClientProvider));
});

final accountDeletionCoordinatorProvider =
    Provider<AccountDeletionCoordinator>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final remote = ref.watch(accountDeletionServiceProvider);
  final local = ref.watch(localUserDataCleanupServiceProvider);
  final guard = ref.watch(accountDeletionGuardProvider);
  final sessionCleaner = DeletedAccountLocalSessionCleaner(
    signOutLocal: () => client.auth.signOut(scope: SignOutScope.local),
    removePersistedSession: supabaseAuthLocalStorage.removePersistedSession,
    isLocalSessionCleared: () =>
        client.auth.currentSession == null && client.auth.currentUser == null,
  );
  return AccountDeletionCoordinator(
    deleteRemoteAccount: remote.deleteRemoteAccount,
    clearLocalAccount: local.clearDeletedAccount,
    clearLocalSession: sessionCleaner.clear,
    guard: guard,
  );
});
