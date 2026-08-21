import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/special_day.dart';
import '../../data/special_days_repository.dart';

final specialDaysRepositoryProvider = Provider<SpecialDaysRepository>((ref) {
  return SpecialDaysRepository(database: ref.watch(appDatabaseProvider));
});

class SpecialDaysNotifier extends StateNotifier<List<SpecialDay>> {
  SpecialDaysNotifier(this._repo) : super(const []) {
    unawaited(load());
  }

  final SpecialDaysRepository _repo;
  bool _active = true;

  @override
  void dispose() {
    _active = false;
    super.dispose();
  }

  void _publish(List<SpecialDay> days) {
    if (_active) state = days;
  }

  Future<void> load() async {
    final userId = _repo.currentUserId;
    final days = await _repo.load();
    if (_repo.currentUserId != userId) return;
    _publish(days);
    unawaited(_syncThenReload());
  }

  Future<void> _syncThenReload() async {
    final userId = _repo.currentUserId;
    await _repo.syncForCurrentUser();
    if (_repo.currentUserId != userId) return;
    final days = await _repo.load();
    if (_repo.currentUserId != userId) return;
    _publish(days);
  }

  Future<void> add({
    required String title,
    required DateTime eventDate,
    required String dayType,
    required bool repeatsAnnually,
    required bool isTr,
  }) async {
    final day = dayType == SpecialDay.kindBirthday
        ? await _repo.setBirthday(eventDate: eventDate, title: title)
        : await _repo.create(
            title: title,
            dayType: dayType,
            eventDate: eventDate,
            repeatsAnnually: repeatsAnnually,
          );
    _publish(await _repo.load());
    await SpecialDayNotifications.schedule(day, isTr: isTr);
  }

  Future<void> update(SpecialDay day, {required bool isTr}) async {
    await _repo.update(day);
    _publish(await _repo.load());
    await SpecialDayNotifications.schedule(day, isTr: isTr);
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    _publish(await _repo.load());
    await SpecialDayNotifications.cancel(id);
  }

  Future<void> setBirthday({
    required int month,
    required int day,
    int? year,
    required String title,
    required bool isTr,
  }) async {
    final birthday = await _repo.setBirthday(
      eventDate: DateTime(year ?? 2000, month, day),
      title: title,
    );
    _publish(await _repo.load());
    await SpecialDayNotifications.schedule(birthday, isTr: isTr);
  }

  Future<void> rearm({required bool isTr}) async {
    _publish(await _repo.load());
    await SpecialDayNotifications.rearmAll(state, isTr: isTr);
  }
}

final specialDaysProvider =
    StateNotifierProvider<SpecialDaysNotifier, List<SpecialDay>>(
  (ref) => SpecialDaysNotifier(ref.watch(specialDaysRepositoryProvider)),
);
