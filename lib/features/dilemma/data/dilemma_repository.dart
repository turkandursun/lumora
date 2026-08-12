import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live crowd counts for a dilemma — aggregated across all app users.
class DilemmaStats {
  const DilemmaStats(this.left, this.right);
  final int left;
  final int right;
  int get total => left + right;
}

/// Records the user's dilemma votes and reads real, app-users-only stats from
/// Supabase (see `supabase/sql/dilemma_votes.sql`).
class DilemmaRepository {
  DilemmaRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Upserts the user's choice for [dilemmaId] ('left' or 'right').
  Future<void> castVote(int dilemmaId, bool left) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('dilemma_votes').upsert(
      {
        'user_id': uid,
        'dilemma_id': dilemmaId,
        'choice': left ? 'left' : 'right',
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,dilemma_id',
    );
  }

  /// Real counts for [dilemmaId] across everyone who has voted.
  Future<DilemmaStats> fetchStats(int dilemmaId) async {
    final res = await _client
        .rpc('get_dilemma_stats', params: {'p_dilemma_id': dilemmaId});
    if (res is List && res.isNotEmpty) {
      final row = res.first as Map<String, dynamic>;
      return DilemmaStats(
        (row['left_count'] as num?)?.toInt() ?? 0,
        (row['right_count'] as num?)?.toInt() ?? 0,
      );
    }
    return const DilemmaStats(0, 0);
  }
}

final dilemmaRepositoryProvider = Provider<DilemmaRepository>((ref) {
  return DilemmaRepository();
});
