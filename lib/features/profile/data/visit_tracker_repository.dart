import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for tracking total distinct days the user opened/visited the app.
class VisitTrackerRepository {
  VisitTrackerRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Records today's visit using fast local SharedPreferences first.
  /// Returns `true` instantly if today is a new calendar day visit, or `false` if already visited today.
  /// Cloud update to Supabase happens asynchronously in the background.
  Future<bool> recordVisitIfNewDay() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('[VisitTracker] Guest or unauthenticated user, skipping visit record');
      return false;
    }

    final userKey = 'visit_last_date_v1_${user.id}';
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final prefs = await SharedPreferences.getInstance();
      final localLastVisit = prefs.getString(userKey);

      final isNewDay = localLastVisit != todayStr;

      if (isNewDay) {
        // Immediately update local key so subsequent app opens today return false instantly
        await prefs.setString(userKey, todayStr);

        // Fire-and-forget cloud sync in the background
        unawaited(_syncVisitToCloud(todayStr));
      }

      return isNewDay;
    } catch (e) {
      debugPrint('[VisitTracker] Error reading local visit tracker: $e');
      return false;
    }
  }

  /// Background task to sync visit count and last visit date to Supabase.
  Future<void> _syncVisitToCloud(String todayStr) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('profiles')
          .select('visit_days_count, last_visit_date')
          .eq('id', user.id)
          .maybeSingle();

      final currentCount = (response?['visit_days_count'] as int?) ?? 0;
      final cloudLastVisit = response?['last_visit_date'] as String?;

      if (cloudLastVisit != todayStr) {
        final newCount = currentCount + 1;
        await _client.from('profiles').update({
          'visit_days_count': newCount,
          'last_visit_date': todayStr,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        debugPrint(
            '[VisitTracker] Background synced visit for $todayStr. New count: $newCount');
      }
    } catch (e) {
      debugPrint('[VisitTracker] Error syncing visit to cloud: $e');
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
