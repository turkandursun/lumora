import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/gratitude_repository.dart';

final gratitudeRepositoryProvider = Provider<GratitudeRepository>((ref) {
  return GratitudeRepository(database: ref.watch(appDatabaseProvider));
});

class GratitudeNotifier extends StateNotifier<List<GratitudeEntry>> {
  GratitudeNotifier(this._repo) : super(const []) {
    _load();
  }

  final GratitudeRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> fetchAndSync() async {
    await _repo.fetchAndSyncFromSupabase();
    state = await _repo.load();
  }

  /// Saves today's gratitude items (and optional [mood]), replacing any
  /// existing entry for today.
  Future<void> saveToday(List<String> items, {String? mood}) async {
    await _repo.saveToday(items, mood: mood);
    await _load();
  }
}

/// Consecutive-day gratitude streak, counting back from today (or yesterday
/// if today isn't written yet).
int gratitudeStreak(List<GratitudeEntry> entries) {
  final days = entries.map((e) => GratitudeRepository.dateOnly(e.date)).toSet();
  var day = GratitudeRepository.dateOnly(DateTime.now());
  if (!days.contains(day)) {
    day = day.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

final gratitudeProvider =
    StateNotifierProvider<GratitudeNotifier, List<GratitudeEntry>>((ref) {
  return GratitudeNotifier(ref.watch(gratitudeRepositoryProvider));
});
