import 'package:shared_preferences/shared_preferences.dart';

const _periodDaysKey = 'period_days_v1';

/// Stores the days the user has marked as menstruation days, on-device only
/// (SharedPreferences), as a list of `yyyy-MM-dd` strings. Deliberately kept
/// out of the cloud database — this is sensitive personal data and there's no
/// need to sync it anywhere for the calendar to work.
class PeriodRepository {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Set<DateTime>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_periodDaysKey) ?? const [];
    return raw.map(DateTime.parse).map(dateOnly).toSet();
  }

  Future<void> save(Set<DateTime> days) async {
    final prefs = await SharedPreferences.getInstance();
    final list = days.map((d) => dateOnly(d).toIso8601String()).toList();
    await prefs.setStringList(_periodDaysKey, list);
  }
}
