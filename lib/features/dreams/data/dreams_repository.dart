import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/user_content_sync.dart';
import 'dream_symbol_keywords.dart';

const _dreamsTable = 'dreams';

List<String> symbolTagsFor(DreamRow dream) =>
    dream.symbolTags.isEmpty ? const [] : dream.symbolTags.split(',');

class DreamsRepository {
  DreamsRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting UserContentRemoteDataSource? remoteDataSource,
    @visibleForTesting String Function()? uuidGenerator,
  })  : _db = database,
        _remote = remoteDataSource ??
            SupabaseUserContentRemoteDataSource(
              supabaseClient ?? Supabase.instance.client,
            ),
        _uuidGenerator = uuidGenerator ?? newUserContentUuid;

  final AppDatabase _db;
  final UserContentRemoteDataSource _remote;
  final String Function() _uuidGenerator;
  final Map<String, Future<void>> _syncInFlight = {};
  final Set<String> _syncRequestedAgain = {};

  Stream<List<DreamRow>> watchAll() {
    final userId = _remote.currentUserId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.dreams)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncPendingDelete).not())
          ..orderBy([(table) => OrderingTerm.desc(table.date)]))
        .watch();
  }

  Future<int> addDream(String text) async {
    final userId = _requireCurrentUser();
    final now = DateTime.now();
    final trimmed = text.trim();
    final id = await _db.into(_db.dreams).insert(
          DreamsCompanion.insert(
            date: now,
            content: trimmed,
            symbolTags: Value(detectDreamSymbols(trimmed).join(',')),
            userId: Value(userId),
            supabaseId: Value(_uuidGenerator()),
            syncState: const Value(contentSyncPendingUpsert),
            changedAt: Value(now),
          ),
        );
    unawaited(syncForCurrentUser());
    return id;
  }

  Future<void> saveReflection({
    required int id,
    String? feelingTag,
    String? familiarPerson,
    String? firstThought,
    String? lifeConnection,
  }) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.dreams)
          ..where((table) => table.id.equals(id) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null || isContentTombstone(row.syncState)) return;
    await (_db.update(_db.dreams)
          ..where((table) => table.id.equals(id) & table.userId.equals(userId)))
        .write(
      DreamsCompanion(
        feelingTag: Value(feelingTag),
        familiarPerson: Value(familiarPerson),
        firstThought: Value(firstThought),
        lifeConnection: Value(lifeConnection),
        supabaseId: Value(row.supabaseId ?? _uuidGenerator()),
        syncState: const Value(contentSyncPendingUpsert),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  /// AI interpretation remains intentionally device-local.
  Future<void> saveAiInterpretation({
    required int id,
    required String interpretation,
  }) async {
    final userId = _requireCurrentUser();
    await (_db.update(_db.dreams)
          ..where((table) => table.id.equals(id) & table.userId.equals(userId)))
        .write(DreamsCompanion(aiInterpretation: Value(interpretation)));
  }

  Future<void> deleteDream(int localId, {String? supabaseId}) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.dreams)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final cloudId = row.supabaseId ?? supabaseId;
    if (cloudId == null) {
      await (_db.delete(_db.dreams)
            ..where((table) =>
                table.id.equals(localId) & table.userId.equals(userId)))
          .go();
      return;
    }
    await (_db.update(_db.dreams)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      DreamsCompanion(
        supabaseId: Value(cloudId),
        syncState: const Value(contentSyncPendingDelete),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> deleteAll() => _db.delete(_db.dreams).go();

  Future<void> fetchAndSyncDreamsFromSupabase() => syncForCurrentUser();

  Future<void> syncForCurrentUser() {
    final userId = _remote.currentUserId;
    if (userId == null) return Future.value();
    final existing = _syncInFlight[userId];
    if (existing != null) {
      _syncRequestedAgain.add(userId);
      return existing;
    }
    late final Future<void> tracked;
    tracked = _drainSyncRequests(userId).whenComplete(() {
      if (identical(_syncInFlight[userId], tracked)) {
        _syncInFlight.remove(userId);
      }
    });
    _syncInFlight[userId] = tracked;
    return tracked;
  }

  Future<void> _drainSyncRequests(String userId) async {
    do {
      _syncRequestedAgain.remove(userId);
      await _syncUser(userId);
    } while (
        _remote.currentUserId == userId && _syncRequestedAgain.remove(userId));
  }

  Future<void> _syncUser(String userId) async {
    await _pushPending(userId);
    if (_remote.currentUserId != userId) return;
    try {
      final cloud = await _remote.fetchRows(
        _dreamsTable,
        userId: userId,
        orderBy: 'date',
      );
      if (_remote.currentUserId != userId) return;
      await _pull(userId, cloud);
    } catch (error) {
      debugPrint('[DreamsSync] pull deferred error=${error.runtimeType}');
    }
  }

  Future<void> _pushPending(String userId) async {
    final rows = await (_db.select(_db.dreams)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncSynced).not()))
        .get();
    for (var row in rows) {
      if (_remote.currentUserId != userId) return;
      final pushedAt = row.changedAt;
      try {
        if (isContentTombstone(row.syncState)) {
          if (row.supabaseId != null) {
            await _remote.deleteRow(
              _dreamsTable,
              userId: userId,
              rowId: row.supabaseId!,
            );
          }
          if (_remote.currentUserId != userId) return;
          await (_db.delete(_db.dreams)
                ..where((table) =>
                    table.id.equals(row.id) &
                    table.userId.equals(userId) &
                    table.syncState.equals(contentSyncPendingDelete) &
                    table.changedAt.equals(pushedAt)))
              .go();
          continue;
        }
        if (row.supabaseId == null) {
          final cloudId = _uuidGenerator();
          await (_db.update(_db.dreams)
                ..where((table) =>
                    table.id.equals(row.id) & table.userId.equals(userId)))
              .write(DreamsCompanion(supabaseId: Value(cloudId)));
          row = row.copyWith(supabaseId: Value(cloudId));
        }
        await _remote.upsertRow(_dreamsTable, _payload(row, userId));
        if (_remote.currentUserId != userId) return;
        await (_db.update(_db.dreams)
              ..where((table) =>
                  table.id.equals(row.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(contentSyncPendingUpsert) &
                  table.changedAt.equals(pushedAt)))
            .write(
          const DreamsCompanion(syncState: Value(contentSyncSynced)),
        );
      } catch (error) {
        debugPrint('[DreamsSync] push deferred error=${error.runtimeType}');
      }
    }
  }

  Map<String, dynamic> _payload(DreamRow row, String userId) => {
        'id': row.supabaseId,
        'user_id': userId,
        'content': row.content,
        'date': row.date.toUtc().toIso8601String(),
        'feeling_tag': row.feelingTag,
        'familiar_person': row.familiarPerson,
        'first_thought': row.firstThought,
        'life_connection': row.lifeConnection,
      };

  Future<void> _pull(
    String userId,
    List<Map<String, dynamic>> cloudRows,
  ) async {
    final cloudMap = <String, Map<String, dynamic>>{
      for (final row in cloudRows)
        if (row['id']?.toString().isNotEmpty ?? false)
          row['id'].toString(): row,
    };
    final locals = await (_db.select(_db.dreams)
          ..where((table) => table.userId.equals(userId)))
        .get();
    final localByCloud = <String, DreamRow>{
      for (final row in locals)
        if (row.supabaseId != null) row.supabaseId!: row,
    };
    for (final entry in cloudMap.entries) {
      if (_remote.currentUserId != userId) return;
      final local = localByCloud[entry.key];
      if (local != null && local.syncState != contentSyncSynced) continue;
      final row = entry.value;
      final content = row['content']?.toString() ?? '';
      if (content.isEmpty) continue;
      final date = _parseDate(row['date']) ?? DateTime.now();
      final companion = DreamsCompanion(
        date: Value(date),
        content: Value(content),
        symbolTags: Value(detectDreamSymbols(content).join(',')),
        feelingTag: Value(row['feeling_tag'] as String?),
        familiarPerson: Value(row['familiar_person'] as String?),
        firstThought: Value(row['first_thought'] as String?),
        lifeConnection: Value(row['life_connection'] as String?),
        syncState: const Value(contentSyncSynced),
        changedAt: Value(date),
      );
      if (local == null) {
        await _db.into(_db.dreams).insert(
              DreamsCompanion.insert(
                date: date,
                content: content,
                symbolTags: Value(detectDreamSymbols(content).join(',')),
                feelingTag: Value(row['feeling_tag'] as String?),
                familiarPerson: Value(row['familiar_person'] as String?),
                firstThought: Value(row['first_thought'] as String?),
                lifeConnection: Value(row['life_connection'] as String?),
                userId: Value(userId),
                supabaseId: Value(entry.key),
                syncState: const Value(contentSyncSynced),
                changedAt: Value(date),
              ),
            );
      } else {
        // aiInterpretation is intentionally absent, preserving the local cache.
        await (_db.update(_db.dreams)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .write(companion);
      }
    }
    for (final local in locals) {
      if (local.syncState != contentSyncSynced || local.supabaseId == null) {
        continue;
      }
      if (!cloudMap.containsKey(local.supabaseId)) {
        await (_db.delete(_db.dreams)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .go();
      }
    }
  }

  String _requireCurrentUser() {
    final userId = _remote.currentUserId;
    if (userId == null) throw StateError('An authenticated user is required.');
    return userId;
  }
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
