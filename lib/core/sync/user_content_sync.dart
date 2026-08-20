import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

const contentSyncSynced = 'synced';
const contentSyncPendingUpsert = 'pending_upsert';
const contentSyncPendingDelete = 'pending_delete';

bool isContentTombstone(String syncState) =>
    syncState == contentSyncPendingDelete;

/// Drift stores DateTime values with second precision in this database.
/// Guarantee a distinct revision token even for multiple edits in one second.
DateTime nextContentChangedAt(DateTime previous) {
  final now = DateTime.now();
  final previousSecond = DateTime.fromMillisecondsSinceEpoch(
    (previous.millisecondsSinceEpoch ~/ 1000) * 1000,
  );
  final nowSecond = DateTime.fromMillisecondsSinceEpoch(
    (now.millisecondsSinceEpoch ~/ 1000) * 1000,
  );
  return nowSecond.isAfter(previousSecond)
      ? nowSecond
      : previousSecond.add(const Duration(seconds: 1));
}

String newUserContentUuid() {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

/// Narrow server seam shared by ASTRA's user-content outboxes.
///
/// Repositories capture [currentUserId] before every sync. The request body
/// always carries the same verified account id and RLS remains the server-side
/// authority; callers never provide an arbitrary owner id from UI state.
abstract interface class UserContentRemoteDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>> upsertRow(
    String table,
    Map<String, dynamic> payload,
  );

  Future<void> deleteRow(
    String table, {
    required String userId,
    required String rowId,
  });

  Future<List<Map<String, dynamic>>> fetchRows(
    String table, {
    required String userId,
    required String orderBy,
  });
}

class SupabaseUserContentRemoteDataSource
    implements UserContentRemoteDataSource {
  SupabaseUserContentRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>> upsertRow(
    String table,
    Map<String, dynamic> payload,
  ) async {
    final row = await _client
        .from(table)
        .upsert(payload, onConflict: 'id')
        .select('id')
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> deleteRow(
    String table, {
    required String userId,
    required String rowId,
  }) async {
    await _client.from(table).delete().eq('id', rowId).eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRows(
    String table, {
    required String userId,
    required String orderBy,
  }) async {
    final rows = await _client
        .from(table)
        .select()
        .eq('user_id', userId)
        .order(orderBy, ascending: false);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}
