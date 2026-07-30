import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/visit_tracker_repository.dart';

final visitTrackerRepositoryProvider = Provider<VisitTrackerRepository>((ref) {
  return VisitTrackerRepository();
});

class VisitTrackerNotifier extends StateNotifier<AsyncValue<int>> {
  VisitTrackerNotifier(this._repository) : super(const AsyncValue.loading()) {
    recordAndLoad();
  }

  final VisitTrackerRepository _repository;

  Future<void> recordAndLoad() async {
    try {
      final count = await _repository.recordVisitIfNewDay();
      if (count != null) {
        state = AsyncValue.data(count);
      } else {
        final fetched = await _repository.fetchVisitDaysCount();
        state = AsyncValue.data(fetched);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final visitDaysCountProvider =
    StateNotifierProvider<VisitTrackerNotifier, AsyncValue<int>>((ref) {
  return VisitTrackerNotifier(ref.watch(visitTrackerRepositoryProvider));
});
