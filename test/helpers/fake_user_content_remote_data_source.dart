import 'dart:async';

import 'package:mindful_journal/core/sync/user_content_sync.dart';

class FakeUserContentRemoteDataSource implements UserContentRemoteDataSource {
  @override
  String? currentUserId = 'user-a';

  bool online = true;
  final Map<String, Map<String, Map<String, dynamic>>> cloud = {};
  int upsertCalls = 0;
  int deleteCalls = 0;
  int fetchCalls = 0;
  Completer<void>? upsertGate;
  Completer<void> upsertObserved = Completer<void>();

  Map<String, Map<String, dynamic>> table(String name) =>
      cloud.putIfAbsent(name, () => {});

  @override
  Future<Map<String, dynamic>> upsertRow(
    String tableName,
    Map<String, dynamic> payload,
  ) async {
    upsertCalls++;
    if (!upsertObserved.isCompleted) upsertObserved.complete();
    if (!online) throw StateError('offline');
    await upsertGate?.future;
    final id = payload['id']!.toString();
    table(tableName)[id] = Map<String, dynamic>.from(payload);
    return {'id': id};
  }

  @override
  Future<void> deleteRow(
    String tableName, {
    required String userId,
    required String rowId,
  }) async {
    deleteCalls++;
    if (!online) throw StateError('offline');
    final row = table(tableName)[rowId];
    if (row?['user_id'] == userId) table(tableName).remove(rowId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRows(
    String tableName, {
    required String userId,
    required String orderBy,
  }) async {
    fetchCalls++;
    if (!online) throw StateError('offline');
    return table(tableName)
        .values
        .where((row) => row['user_id'] == userId)
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }
}
