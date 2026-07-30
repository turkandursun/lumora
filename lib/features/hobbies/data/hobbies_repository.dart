import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// On-device store for the user's chosen hobbies — a set of ids (preset ids
/// like `reading`, or the free-text a user typed for a custom hobby).
class HobbiesRepository {
  HobbiesRepository({SupabaseClient? supabaseClient})
      : _client = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId =>
      _client.auth.currentUser?.id ??
      _client.auth.currentSession?.user.id ??
      'guest';

  String get _hobbiesKey => 'hobbies_${_userId}_v1';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hobbiesKey) ?? const []).toSet();
  }

  Future<void> save(Set<String> hobbies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hobbiesKey, hobbies.toList());

    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        await _client.from('user_hobbies').upsert({
          'user_id': user.id,
          'hobby_ids': hobbies.toList(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('[HobbiesSync] Successfully saved hobbies to Supabase');
      } catch (e) {
        debugPrint('[HobbiesSync] Error saving hobbies to Supabase: $e');
      }
    }
  }

  Future<Set<String>> syncHobbiesWithSupabase() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final row = await _client
            .from('user_hobbies')
            .select('hobby_ids')
            .eq('user_id', user.id)
            .maybeSingle();

        if (row != null && row['hobby_ids'] != null) {
          final cloudHobbies = List<String>.from(row['hobby_ids'] as List);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_hobbiesKey, cloudHobbies);
          debugPrint('[HobbiesSync] Synced hobbies from Supabase: $cloudHobbies');
          return cloudHobbies.toSet();
        }
      } catch (e) {
        debugPrint('[HobbiesSync] Error syncing hobbies from Supabase: $e');
      }
    }
    return load();
  }
}

