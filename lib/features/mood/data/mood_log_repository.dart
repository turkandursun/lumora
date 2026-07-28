import 'package:shared_preferences/shared_preferences.dart';

const _moodLogKey = 'mood_log_v1';

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Stores one mood per day (the [AppMood] index) on-device, so the mood
/// chart can plot history. Kept local — moods are only tracked from the
/// moment the user first records one; there's no backfill of past days.
class MoodLogRepository {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Map<DateTime, int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_moodLogKey) ?? const [];
    final map = <DateTime, int>{};
    for (final entry in raw) {
      final sep = entry.indexOf(':');
      if (sep < 0) continue;
      final date = DateTime.tryParse(entry.substring(0, sep));
      final value = int.tryParse(entry.substring(sep + 1));
      if (date != null && value != null) map[dateOnly(date)] = value;
    }
    return map;
  }

  Future<void> save(Map<DateTime, int> log) async {
    final prefs = await SharedPreferences.getInstance();
    final list = log.entries.map((e) => '${_fmt(e.key)}:${e.value}').toList();
    await prefs.setStringList(_moodLogKey, list);
  }
}
