import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/goals_repository.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(database: ref.watch(appDatabaseProvider));
});

/// Reactive list of every goal, in insertion order.
final goalsStreamProvider = StreamProvider<List<GoalRow>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchAll();
});

/// Mirrors the streak persisted by [GoalsRepository] so the UI can react to
/// it. There's no natural stream for two [SharedPreferences] scalars, so
/// this is refreshed explicitly (on screen load and after every increment)
/// rather than reactively.
class GoalStreakNotifier extends StateNotifier<GoalStreak> {
  GoalStreakNotifier(this._repository) : super(const GoalStreak());

  final GoalsRepository _repository;

  Future<void> refresh() async {
    state = await _repository.loadStreak();
  }
}

final goalStreakProvider = StateNotifierProvider<GoalStreakNotifier, GoalStreak>((ref) {
  return GoalStreakNotifier(ref.watch(goalsRepositoryProvider));
});
