import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/dreams_repository.dart';

final dreamsRepositoryProvider = Provider<DreamsRepository>((ref) {
  return DreamsRepository(database: ref.watch(appDatabaseProvider));
});

/// Reactive list of every saved dream, most recent first.
final dreamsStreamProvider = StreamProvider<List<DreamRow>>((ref) {
  return ref.watch(dreamsRepositoryProvider).watchAll();
});
