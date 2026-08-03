import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(database: ref.watch(appDatabaseProvider));
});

class ActivitiesNotifier extends StateNotifier<List<Activity>> {
  ActivitiesNotifier(this._repo) : super(const []) {
    _load();
  }

  final ActivityRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
    await _repo.fetchAndSyncFromSupabase();
    state = await _repo.load();
  }

  Future<void> refreshSync() async {
    await _repo.fetchAndSyncFromSupabase();
    state = await _repo.load();
  }

  Future<void> add(Activity activity) async {
    await _repo.add(activity);
    state = await _repo.load();
  }

  Future<void> remove(int localId, {String? supabaseId, String? photoUrl, String? photoPath}) async {
    await _repo.delete(localId, supabaseId: supabaseId, photoUrl: photoUrl, photoPath: photoPath);
    state = await _repo.load();
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, List<Activity>>((ref) {
  return ActivitiesNotifier(ref.watch(activityRepositoryProvider));
});
