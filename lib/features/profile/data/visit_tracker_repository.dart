import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for tracking total distinct days the user opened/visited the app.
class VisitTrackerRepository {
  VisitTrackerRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Records today's visit if the user hasn't opened the app yet today.
  /// Increments `visit_days_count` by 1 and updates `last_visit_date` to today.
  Future<int?> recordVisitIfNewDay() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final response = await _client
          .from('profiles')
          .select('visit_days_count, last_visit_date')
          .eq('id', user.id)
          .maybeSingle();

      final currentCount = (response?['visit_days_count'] as int?) ?? 0;
      final lastVisitDate = response?['last_visit_date'] as String?;

      if (lastVisitDate != todayStr) {
        final newCount = currentCount + 1;
        await _client.from('profiles').update({
          'visit_days_count': newCount,
          'last_visit_date': todayStr,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        debugPrint(
            '[VisitTracker] Recorded visit for $todayStr. New count: $newCount');
        return newCount;
      }
      return currentCount;
    } catch (e) {
      debugPrint('[VisitTracker] Error recording visit: $e');
      return null;
    }
  }

  /// Fetches the user's total visit days count.
  Future<int> fetchVisitDaysCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final response = await _client
          .from('profiles')
          .select('visit_days_count')
          .eq('id', user.id)
          .maybeSingle();

      return (response?['visit_days_count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('[VisitTracker] Error fetching visit days count: $e');
      return 0;
    }
  }
}
