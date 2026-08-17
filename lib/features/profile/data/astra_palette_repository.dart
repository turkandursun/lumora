import 'package:supabase_flutter/supabase_flutter.dart';

/// `profiles.palette_id` alanına yalnız aktif Supabase hesabı adına erişir.
///
/// Beklenen kullanıcı kimliği UI'dan gelmez; palette provider tarafından
/// `auth.currentUser` üzerinden yakalanır. Her ağ işleminden önce ve sonra
/// yapılan kontrol, hesap değişimi sırasında eski kullanıcının sonucunun yeni
/// hesaba uygulanmasını engeller.
abstract interface class AstraPaletteRepository {
  String? get currentUserId;

  Future<String?> fetchPaletteId(String expectedUserId);

  Future<void> updatePaletteId(
    String expectedUserId,
    String paletteId,
  );
}

class SupabaseAstraPaletteRepository implements AstraPaletteRepository {
  SupabaseAstraPaletteRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  void _ensureCurrentUser(String expectedUserId) {
    if (currentUserId != expectedUserId) {
      throw const AstraPaletteAccountChangedException();
    }
  }

  @override
  Future<String?> fetchPaletteId(String expectedUserId) async {
    _ensureCurrentUser(expectedUserId);
    final profile = await _client
        .from('profiles')
        .select('palette_id')
        .eq('id', expectedUserId)
        .maybeSingle();
    _ensureCurrentUser(expectedUserId);
    return profile?['palette_id'] as String?;
  }

  @override
  Future<void> updatePaletteId(
    String expectedUserId,
    String paletteId,
  ) async {
    _ensureCurrentUser(expectedUserId);
    await _client.from('profiles').update({
      'palette_id': paletteId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expectedUserId);
    _ensureCurrentUser(expectedUserId);
  }
}

class AstraPaletteAccountChangedException implements Exception {
  const AstraPaletteAccountChangedException();
}
