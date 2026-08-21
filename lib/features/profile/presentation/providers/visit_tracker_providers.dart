import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/visit_tracker_repository.dart';

final visitTrackerRepositoryProvider = Provider<VisitTrackerRepository>((ref) {
  return VisitTrackerRepository();
});

/// Process-lifetime gate for the celebratory Home banner.
///
/// The gate is deliberately in memory: a cold launch creates a new instance,
/// while repeated Home mounts in the same process cannot spam the same user.
/// Keeping user ids separately also makes an in-process account switch safe.
class StreakBannerLaunchGate {
  final Set<String> _claimedUserIds = <String>{};

  bool claim(String userId) => _claimedUserIds.add(userId);
}

final streakBannerLaunchGateProvider = Provider<StreakBannerLaunchGate>(
  (ref) => StreakBannerLaunchGate(),
);

final weeklyVisitDatesProvider = StreamProvider<Set<String>>((ref) async* {
  final repository = ref.watch(visitTrackerRepositoryProvider);
  // Render the durable local exact history immediately, including today's
  // visit. Network/profile-summary latency must not block the launch banner.
  yield await repository.fetchVisitDatesForCurrentWeek();
  await repository.syncVisitHistoryForCurrentUser();
  // Exact history remains primary. The profile summary only fills missing
  // legacy weekdays in the returned display set and is never persisted.
  yield await repository.fetchWeeklyVisitDatesWithLegacyFallback();
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
        unawaited(_syncThenReload());
      }
      return isNewDay;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> _syncThenReload() async {
    await _repository.syncVisitHistoryForCurrentUser();
    await load();
  }
}

final visitDaysCountProvider =
    StateNotifierProvider<VisitTrackerNotifier, AsyncValue<int>>((ref) {
  return VisitTrackerNotifier(ref.watch(visitTrackerRepositoryProvider));
});
