import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/journal_streak_repository.dart';

final journalStreakRepositoryProvider = Provider<JournalStreakRepository>((ref) {
  return JournalStreakRepository();
});

/// Mirrors the streak persisted by [JournalStreakRepository] so the UI can
/// react to it. There's no natural stream for two [SharedPreferences]
/// scalars, so this is refreshed explicitly (on screen load and after every
/// saved entry) rather than reactively.
class JournalStreakNotifier extends StateNotifier<JournalStreak> {
  JournalStreakNotifier(this._repository) : super(const JournalStreak());

  final JournalStreakRepository _repository;

  Future<void> refresh() async {
    state = await _repository.loadStreak();
  }

  /// Records today as a day a journal entry was saved and updates [state].
  /// Returns whether the streak count just increased, so the caller can
  /// decide whether to play a celebration.
  Future<bool> recordEntrySaved() async {
    final (streak, increased) = await _repository.recordEntrySaved();
    state = streak;
    return increased;
  }
}

final journalStreakProvider =
    StateNotifierProvider<JournalStreakNotifier, JournalStreak>((ref) {
  return JournalStreakNotifier(ref.watch(journalStreakRepositoryProvider));
});
