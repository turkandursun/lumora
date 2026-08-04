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

  Future<bool> recordAndLoad() async {
    try {
      final isNewDay = await _repository.recordVisitIfNewDay();
      _repository.fetchVisitDaysCount().then((count) {
        state = AsyncValue.data(count);
      }).catchError((e, st) {
        state = AsyncValue.error(e, st as StackTrace);
      });
      return isNewDay;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final visitDaysCountProvider =
    StateNotifierProvider<VisitTrackerNotifier, AsyncValue<int>>((ref) {
  return VisitTrackerNotifier(ref.watch(visitTrackerRepositoryProvider));
});
