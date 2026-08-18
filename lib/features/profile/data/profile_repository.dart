import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/astra_design_tokens.dart';

const String defaultProfileThemePreference = 'light';

/// Repository for handling user profile operations.
class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Creates or normalizes the profile row for a genuinely fresh account.
  ///
  /// This method must only be called from the user-scoped fresh-registration
  /// flow. Existing-login paths never call it, so an established user's
  /// palette or brightness choice cannot be reset.
  Future<void> initializeFreshProfileDefaults(String expectedUserId) async {
    final user = _client.auth.currentUser;
    if (user == null || user.id != expectedUserId) {
      throw const ProfileAccountChangedException();
    }

    final metadata = user.userMetadata;
    final rawFullName = metadata?['full_name'] ?? metadata?['name'];
    final fullName = rawFullName is String && rawFullName.trim().isNotEmpty
        ? rawFullName.trim()
        : null;

    await _client.from('profiles').upsert(
          buildFreshProfilePayload(
            userId: user.id,
            email: user.email,
            fullName: fullName,
            updatedAt: DateTime.now().toUtc(),
          ),
          onConflict: 'id',
        );

    if (_client.auth.currentUser?.id != expectedUserId) {
      throw const ProfileAccountChangedException();
    }
  }

  @visibleForTesting
  static Map<String, Object?> buildFreshProfilePayload({
    required String userId,
    required String? email,
    required String? fullName,
    required DateTime updatedAt,
  }) {
    return <String, Object?>{
      'id': userId,
      'email': email,
      if (fullName != null && fullName.trim().isNotEmpty)
        'full_name': fullName.trim(),
      'palette_id': AstraThemeId.softLilacMist.wireValue,
      'theme_preference': defaultProfileThemePreference,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Updates the user's full_name in both Supabase Auth metadata and the `public.profiles` table.
  Future<void> updateFullName(String fullName) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client.from('profiles').update({
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
  }
}

class ProfileAccountChangedException implements Exception {
  const ProfileAccountChangedException();
}
