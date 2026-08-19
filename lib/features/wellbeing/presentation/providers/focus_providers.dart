import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/focus_completion_notifier.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/focus_active_session_store.dart';
import '../../data/focus_repository.dart';
import '../../domain/active_focus_session.dart';
import '../controllers/focus_timer_controller.dart';

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepository(database: ref.watch(appDatabaseProvider));
});

final focusLocalStateStoreProvider = Provider<FocusLocalStateStore>((ref) {
  return SharedPreferencesFocusLocalStateStore();
});

final focusCompletionNotifierProvider = Provider<FocusCompletionNotifier>(
  (ref) => NotificationService.instance,
);

final activeFocusSessionProvider =
    StateNotifierProvider<FocusTimerController, ActiveFocusSession?>((ref) {
  final controller = FocusTimerController(
    sessions: ref.watch(focusRepositoryProvider),
    localState: ref.watch(focusLocalStateStoreProvider),
    notifications: ref.watch(focusCompletionNotifierProvider),
  );
  unawaited(controller.initialize());
  return controller;
});

class FocusStatsNotifier extends StateNotifier<FocusStats> {
  FocusStatsNotifier(this._repository, this._localState)
      : super(FocusStats.empty) {
    unawaited(_initialize());
  }

  final FocusRepository _repository;
  final FocusLocalStateStore _localState;
  StreamSubscription<FocusMetrics>? _subscription;
  int _generation = 0;

  Future<void> _initialize() async {
    final userId = _repository.currentUserId;
    final generation = ++_generation;
    if (userId == null) {
      state = FocusStats.empty;
      return;
    }
    try {
      await _localState.clearLegacyGlobalPreferences();
    } catch (_) {
      // Legacy cleanup is best effort.
    }
    var goal = 5;
    try {
      goal = await _localState.loadDailyGoal(userId);
    } catch (_) {
      // The supported default remains available when preferences fail.
    }
    if (!_isCurrent(userId, generation)) return;
    state = state.withGoal(goal);
    await _subscription?.cancel();
    _subscription = _repository.watchMetricsForCurrentUser().listen(
      (metrics) {
        if (_isCurrent(userId, generation)) state = state.withMetrics(metrics);
      },
      onError: (_) {},
    );
    _repository.initialize();
  }

  Future<void> refresh() async {
    final userId = _repository.currentUserId;
    if (userId == null) {
      state = FocusStats.empty;
      return;
    }
    try {
      final metrics = await _repository.loadMetricsForCurrentUser();
      if (_repository.currentUserId == userId) {
        state = state.withMetrics(metrics);
      }
    } catch (_) {
      // A local read failure must not crash app resume.
    }
  }

  Future<void> setGoal(int goal) async {
    final userId = _repository.currentUserId;
    if (userId == null) return;
    final safeGoal = goal.clamp(1, 12);
    state = state.withGoal(safeGoal);
    try {
      await _localState.saveDailyGoal(userId, safeGoal);
    } catch (_) {
      // Keep the optimistic UI state; the user can retry the preference later.
    }
  }

  bool _isCurrent(String userId, int generation) =>
      mounted &&
      generation == _generation &&
      _repository.currentUserId == userId;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}

final focusStatsProvider =
    StateNotifierProvider<FocusStatsNotifier, FocusStats>(
  (ref) => FocusStatsNotifier(
    ref.watch(focusRepositoryProvider),
    ref.watch(focusLocalStateStoreProvider),
  ),
);
