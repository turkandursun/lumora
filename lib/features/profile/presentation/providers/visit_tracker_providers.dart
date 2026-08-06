import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/visit_tracker_repository.dart';

final visitTrackerRepositoryProvider = Provider<VisitTrackerRepository>((ref) {
  return VisitTrackerRepository();
});

class VisitTrackerNotifier extends StateNotifier<AsyncValue<int>> {
  VisitTrackerNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final VisitTrackerRepository _repository;

  /// Loads current visit_days_count into state without recording/writing any visit flags.
  Future<void> load() async {
    try {
      final count = await _repository.fetchVisitDaysCount();
      state = AsyncValue.data(count);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Explicitly called by WelcomeScreen on app launch / login.
  /// Records today's visit if it's a new day, updates count if recorded, and returns boolean.
  Future<bool> recordVisitIfNewDay() async {
    try {
      final isNewDay = await _repository.recordVisitIfNewDay();
      if (isNewDay) {
        unawaited(load());
      }
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
