import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gratitude_repository.dart';

final gratitudeRepositoryProvider = Provider<GratitudeRepository>((ref) {
  return GratitudeRepository();
});

class GratitudeNotifier extends StateNotifier<List<GratitudeEntry>> {
  GratitudeNotifier(this._repo) : super(const []) {
    _load();
  }

  final GratitudeRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Saves today's gratitude items (and optional [mood]), replacing any
  /// existing entry for today.
  Future<void> saveToday(List<String> items, {String? mood}) async {
    final today = GratitudeRepository.dateOnly(DateTime.now());
    final cleaned = items.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final rest = state.where((e) => !_sameDay(e.date, today)).toList();
    final next = [
      if (cleaned.isNotEmpty)
        GratitudeEntry(date: today, items: cleaned, mood: mood),
      ...rest,
    ]..sort((a, b) => b.date.compareTo(a.date));
    state = next;
    await _repo.save(next);
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
