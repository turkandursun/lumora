import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloud_backup_service.dart';
import 'account_deletion_guard_provider.dart';
import 'database_provider.dart';

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  final deletionGuard = ref.watch(accountDeletionGuardProvider);
  return CloudBackupService(
    database: ref.watch(appDatabaseProvider),
    accountDeletionInProgress: () => deletionGuard.isInProgress,
  );
});
