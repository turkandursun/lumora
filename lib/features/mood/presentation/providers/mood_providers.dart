import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mood_log_repository.dart';

final moodLogRepositoryProvider = Provider<MoodLogRepository>((ref) {
  return MoodLogRepository();
});

/// Day -> [AppMood] index. Recording a mood for a day upserts it here and
/// persists immediately.
class MoodLogNotifier extends StateNotifier<Map<DateTime, int>> {
  MoodLogNotifier(this._repo) : super(const {}) {
    _load();
  }

  final MoodLogRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> setForDay(DateTime day, int moodIndex) async {
    final key = MoodLogRepository.dateOnly(day);
    final next = {...state};
    next[key] = moodIndex;
    state = next;
    await _repo.save(next);
  }

  /// Removes any logged mood for [day].
  Future<void> clearForDay(DateTime day) async {
    final key = MoodLogRepository.dateOnly(day);
    if (!state.containsKey(key)) return;
    final next = {...state}..remove(key);
    state = next;
    await _repo.save(next);
  }
}

final moodLogProvider =
    StateNotifierProvider<MoodLogNotifier, Map<DateTime, int>>((ref) {
  return MoodLogNotifier(ref.watch(moodLogRepositoryProvider));
});
