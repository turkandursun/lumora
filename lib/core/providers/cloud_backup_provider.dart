import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cloud_backup_service.dart';
import 'database_provider.dart';

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService(database: ref.watch(appDatabaseProvider));
});
