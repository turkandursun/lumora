import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../data/period_repository.dart';
import '../../data/symptom_repository.dart';

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  return PeriodRepository();
});

/// The set of days marked as menstruation days, loaded from local storage.
/// Toggling a day updates state immediately and persists in the background.
class PeriodDaysNotifier extends StateNotifier<Set<DateTime>> {
  PeriodDaysNotifier(this._repo) : super(const {}) {
    _load();
  }

  final PeriodRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  bool isPeriod(DateTime day) => state.contains(PeriodRepository.dateOnly(day));

  Future<void> toggle(DateTime day) async {
    final key = PeriodRepository.dateOnly(day);
    final next = {...state};
    if (!next.add(key)) next.remove(key);
    state = next;
    await _repo.save(next);
  }
}

final periodDaysProvider =
    StateNotifierProvider<PeriodDaysNotifier, Set<DateTime>>((ref) {
  return PeriodDaysNotifier(ref.watch(periodRepositoryProvider));
});

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  return SymptomRepository();
});

/// Day -> set of symptom ids logged for that day.
class SymptomsNotifier extends StateNotifier<Map<DateTime, Set<String>>> {
  SymptomsNotifier(this._repo) : super(const {}) {
    _load();
  }

  final SymptomRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Set<String> forDay(DateTime day) =>
      state[SymptomRepository.dateOnly(day)] ?? const {};

  Future<void> toggle(DateTime day, String symptomId) async {
    final key = SymptomRepository.dateOnly(day);
    final next = {...state};
    final ids = {...(next[key] ?? const <String>{})};
    if (!ids.add(symptomId)) ids.remove(symptomId);
    if (ids.isEmpty) {
      next.remove(key);
    } else {
      next[key] = ids;
    }
    state = next;
    await _repo.save(next);
  }
}

final symptomsProvider =
    StateNotifierProvider<SymptomsNotifier, Map<DateTime, Set<String>>>((ref) {
  return SymptomsNotifier(ref.watch(symptomRepositoryProvider));
});

/// The set of days that have at least one saved journal entry — used to mark
/// activity on the calendar.
final journalEntryDaysProvider = StreamProvider<Set<DateTime>>((ref) {
  final repo = ref.watch(journalEntriesRepositoryProvider);
  return repo.watchAll().map(
        (rows) => rows
            .map((r) => DateTime(
                  r.createdAt.year,
                  r.createdAt.month,
                  r.createdAt.day,
                ))
            .toSet(),
      );
});
