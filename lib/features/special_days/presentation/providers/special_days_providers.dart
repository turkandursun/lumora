import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/special_day.dart';

final specialDaysRepositoryProvider =
    Provider<SpecialDaysRepository>((ref) => SpecialDaysRepository());

/// Holds the user's special days and keeps their annual notifications armed.
class SpecialDaysNotifier extends StateNotifier<List<SpecialDay>> {
  SpecialDaysNotifier(this._repo) : super(const []) {
    load();
  }

  final SpecialDaysRepository _repo;

  Future<void> load() async {
    state = await _repo.load();
  }

  Future<void> addOrReplace(SpecialDay day, {required bool isTr}) async {
    state = await _repo.addOrReplace(day);
    await SpecialDayNotifications.schedule(day, isTr: isTr);
  }

  Future<void> remove(String id) async {
    state = await _repo.remove(id);
    await SpecialDayNotifications.cancel(id);
  }

  Future<void> setBirthday({
    required int month,
    required int day,
    int? year,
    required String title,
    required bool isTr,
  }) async {
    state = await _repo.setBirthday(
        month: month, day: day, year: year, title: title);
    final birthday = state.where((d) => d.isBirthday);
    if (birthday.isNotEmpty) {
      await SpecialDayNotifications.schedule(birthday.first, isTr: isTr);
    }
  }

  /// Re-schedules every special day's yearly notification (call on app/screen
  /// open so the once-fired reminders stay armed for the next occurrence).
  /// Reloads first so it works even before the initial load has settled.
  Future<void> rearm({required bool isTr}) async {
    await load();
    await SpecialDayNotifications.rearmAll(state, isTr: isTr);
  }
}

final specialDaysProvider =
    StateNotifierProvider<SpecialDaysNotifier, List<SpecialDay>>(
        (ref) => SpecialDaysNotifier(ref.watch(specialDaysRepositoryProvider)));

/// Month+day keys (month*100+day) of every special day, for O(1) calendar
/// membership tests. Special days recur yearly, so only month/day matter.
final specialDayKeysProvider = Provider<Set<int>>((ref) {
  final days = ref.watch(specialDaysProvider);
  return days.map((d) => d.monthDayKey).toSet();
});
