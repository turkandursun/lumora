import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/activity_repository.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

class ActivitiesNotifier extends StateNotifier<List<Activity>> {
  ActivitiesNotifier(this._repo) : super(const []) {
    _load();
  }

  final ActivityRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> add(Activity activity) async {
    final next = [activity, ...state]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = next;
    await _repo.save(next);
  }

  Future<void> remove(int id) async {
    final target = state.where((a) => a.id == id).toList();
    final next = state.where((a) => a.id != id).toList();
    state = next;
    await _repo.save(next);
    // Best-effort cleanup of the attached photo file.
    for (final a in target) {
      final path = a.photoPath;
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }
  }
}

final activitiesProvider =
    StateNotifierProvider<ActivitiesNotifier, List<Activity>>((ref) {
  return ActivitiesNotifier(ref.watch(activityRepositoryProvider));
});
