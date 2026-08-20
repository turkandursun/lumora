import 'package:shared_preferences/shared_preferences.dart';

String periodSymptomsStorageKey(String userId) =>
    'period_symptoms_v2_$userId';

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Stores per-day period symptoms (ids like `cramps`, `headache`) on-device,
/// as `yyyy-MM-dd:id1,id2` strings.
class SymptomRepository {
  SymptomRepository({
    required String? userId,
    Future<SharedPreferences> Function()? preferencesLoader,
  })  : _userId = userId,
        _preferencesLoader =
            preferencesLoader ?? SharedPreferences.getInstance;

  final String? _userId;
  final Future<SharedPreferences> Function() _preferencesLoader;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Map<DateTime, Set<String>>> load() async {
    final userId = _userId;
    if (userId == null) return const {};
    final prefs = await _preferencesLoader();
    final raw =
        prefs.getStringList(periodSymptomsStorageKey(userId)) ?? const [];
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
    final userId = _userId;
    if (userId == null) return;
    final prefs = await _preferencesLoader();
    final list = data.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${_fmt(e.key)}:${e.value.join(',')}')
        .toList();
    await prefs.setStringList(periodSymptomsStorageKey(userId), list);
  }
}
