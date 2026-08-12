import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_deletion_service.dart';

final accountDeletionGuardProvider = Provider<AccountDeletionGuard>((ref) {
  return AccountDeletionGuard();
});
