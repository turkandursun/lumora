import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// On-device store for the user's chosen hobbies — a set of ids (preset ids
/// like `reading`, or the free-text a user typed for a custom hobby).
abstract interface class HobbiesPersistence {
  Future<Set<String>> load();

  Future<void> save(Set<String> hobbies);

  Future<Set<String>> syncHobbiesWithSupabase();
}

class HobbiesRepository implements HobbiesPersistence {
  HobbiesRepository({SupabaseClient? supabaseClient})
      : this._(supabaseClient ?? Supabase.instance.client);

  HobbiesRepository._(SupabaseClient client)
      : _client = client,
        _userId = client.auth.currentUser?.id ??
            client.auth.currentSession?.user.id ??
            'guest';

  final SupabaseClient _client;
  final String _userId;

  String get _hobbiesKey => 'hobbies_${_userId}_v1';

  @override
  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hobbiesKey) ?? const []).toSet();
  }

  @override
  Future<void> save(Set<String> hobbies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hobbiesKey, hobbies.toList());

    final user = _client.auth.currentUser;
    if (user != null && user.id == _userId) {
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

  @override
  Future<Set<String>> syncHobbiesWithSupabase() async {
    final user = _client.auth.currentUser;
    if (user != null && user.id == _userId) {
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
          debugPrint(
              '[HobbiesSync] Synced hobbies from Supabase: $cloudHobbies');
          return cloudHobbies.toSet();
        }
      } catch (e) {
        debugPrint('[HobbiesSync] Error syncing hobbies from Supabase: $e');
      }
    }
    return load();
  }
}
