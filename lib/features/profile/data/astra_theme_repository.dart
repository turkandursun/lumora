import 'package:supabase_flutter/supabase_flutter.dart';

/// Account-scoped persistence for the independent light/dark appearance layer.
abstract interface class AstraThemeRepository {
  String? get currentUserId;

  Future<String?> fetchThemePreference(String expectedUserId);

  Future<void> updateThemePreference(
    String expectedUserId,
    String preference,
  );
}

class SupabaseAstraThemeRepository implements AstraThemeRepository {
  SupabaseAstraThemeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  void _ensureCurrentUser(String expectedUserId) {
    if (currentUserId != expectedUserId) {
      throw const AstraThemeAccountChangedException();
    }
  }

  @override
  Future<String?> fetchThemePreference(String expectedUserId) async {
    _ensureCurrentUser(expectedUserId);
    final profile = await _client
        .from('profiles')
        .select('theme_preference')
        .eq('id', expectedUserId)
        .maybeSingle();
    _ensureCurrentUser(expectedUserId);
    return profile?['theme_preference'] as String?;
  }

  @override
  Future<void> updateThemePreference(
    String expectedUserId,
    String preference,
  ) async {
    _ensureCurrentUser(expectedUserId);
    await _client.from('profiles').update({
      'theme_preference': preference,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expectedUserId);
    _ensureCurrentUser(expectedUserId);
  }
}

class AstraThemeAccountChangedException implements Exception {
  const AstraThemeAccountChangedException();
}
