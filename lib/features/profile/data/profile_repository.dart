import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for handling user profile operations.
class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Updates the user's full_name in both Supabase Auth metadata and the `public.profiles` table.
  Future<void> updateFullName(String fullName) async {
    await _client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client
          .from('profiles')
          .update({
            'full_name': fullName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    }
  }
}
