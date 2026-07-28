import 'package:shared_preferences/shared_preferences.dart';

const _symptomKey = 'period_symptoms_v1';

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Stores per-day period symptoms (ids like `cramps`, `headache`) on-device,
/// as `yyyy-MM-dd:id1,id2` strings.
class SymptomRepository {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Map<DateTime, Set<String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_symptomKey) ?? const [];
    final map = <DateTime, Set<String>>{};
    for (final entry in raw) {
      final sep = entry.indexOf(':');
      if (sep < 0) continue;
      final date = DateTime.tryParse(entry.substring(0, sep));
      if (date == null) continue;
      final ids = entry
          .substring(sep + 1)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();
      if (ids.isNotEmpty) map[dateOnly(date)] = ids;
    }
    return map;
  }

  Future<void> save(Map<DateTime, Set<String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final list = data.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${_fmt(e.key)}:${e.value.join(',')}')
        .toList();
    await prefs.setStringList(_symptomKey, list);
  }
}
