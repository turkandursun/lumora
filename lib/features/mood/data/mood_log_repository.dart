import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _moodLogKey = 'mood_log_v1';

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Stores one mood per day (the [AppMood] index) on-device via [SharedPreferences],
/// while also syncing logs to Supabase's `mood_logs` table (user_id, mood, logged_at).
class MoodLogRepository {
  MoodLogRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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

  /// Syncs a single mood log entry to Supabase `mood_logs` (user_id, mood, logged_at).
  Future<void> syncMoodToSupabase(DateTime day, int moodIndex) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final dateStr = _fmt(day);
      await _client.from('mood_logs').upsert({
        'user_id': user.id,
        'mood': moodIndex,
        'logged_at': dateStr,
      });
      debugPrint('[MoodSync] Successfully synced mood to Supabase for $dateStr');
    } catch (e) {
      debugPrint('[MoodSync] Error syncing mood to Supabase: $e');
    }
  }

  /// Fetches mood logs from Supabase and merges them into local SharedPreferences.
  Future<void> fetchAndSyncFromSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('mood_logs')
          .select()
          .eq('user_id', user.id);

      if (response.isNotEmpty) {
        final current = await load();
        var updated = false;

        for (final row in response) {
          final moodVal = row['mood'];
          final loggedAtStr = row['logged_at'] as String?;
          if (moodVal == null || loggedAtStr == null) continue;

          final dt = DateTime.tryParse(loggedAtStr);
          final val = moodVal is int ? moodVal : int.tryParse(moodVal.toString());
          if (dt != null && val != null) {
            final key = dateOnly(dt);
            if (!current.containsKey(key)) {
              current[key] = val;
              updated = true;
            }
          }
        }

        if (updated) {
          await save(current);
        }
      }
    } catch (e) {
      debugPrint('[MoodSync] Error fetching mood_logs from Supabase: $e');
    }
  }
}
