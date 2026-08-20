import 'package:shared_preferences/shared_preferences.dart';

String periodDaysStorageKey(String userId) => 'period_days_v2_$userId';

/// Stores the days the user has marked as menstruation days, on-device only
/// (SharedPreferences), as a list of `yyyy-MM-dd` strings. Deliberately kept
/// out of the cloud database — this is sensitive personal data and there's no
/// need to sync it anywhere for the calendar to work.
class PeriodRepository {
  PeriodRepository({
    required String? userId,
    Future<SharedPreferences> Function()? preferencesLoader,
  })  : _userId = userId,
        _preferencesLoader =
            preferencesLoader ?? SharedPreferences.getInstance;

  final String? _userId;
  final Future<SharedPreferences> Function() _preferencesLoader;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Set<DateTime>> load() async {
    final userId = _userId;
    if (userId == null) return const {};
    final prefs = await _preferencesLoader();
    final raw = prefs.getStringList(periodDaysStorageKey(userId)) ?? const [];
    return raw.map(DateTime.parse).map(dateOnly).toSet();
  }

  Future<void> save(Set<DateTime> days) async {
    final userId = _userId;
    if (userId == null) return;
    final prefs = await _preferencesLoader();
    final list = days.map((d) => dateOnly(d).toIso8601String()).toList();
    await prefs.setStringList(periodDaysStorageKey(userId), list);
  }
}
