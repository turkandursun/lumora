import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/user_content_sync.dart';

const _legacyKey = 'letters_v1';
const _lettersTable = 'letters';

class Letter {
  const Letter({
    required this.id,
    required this.createdAt,
    required this.openAt,
    required this.title,
    required this.body,
    this.userId,
    this.supabaseId,
  });

  final int id;
  final DateTime createdAt;
  final DateTime openAt;
  final String title;
  final String body;
  final String? userId;
  final String? supabaseId;

  bool get isUnlocked => !DateTime.now().isBefore(openAt);

  factory Letter.fromRow(LetterRow row) => Letter(
        id: row.id,
        createdAt: row.createdAt,
        openAt: row.openAt,
        title: row.title,
        body: row.body,
        userId: row.userId,
        supabaseId: row.supabaseId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'openAt': openAt.toIso8601String(),
        'title': title,
        'body': body,
        if (userId != null) 'userId': userId,
        if (supabaseId != null) 'supabaseId': supabaseId,
      };

  factory Letter.fromJson(Map<String, dynamic> json) => Letter(
        id: json['id'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        openAt: DateTime.tryParse(json['openAt']?.toString() ?? '') ??
            DateTime.now(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        userId: json['userId'] as String?,
        supabaseId: json['supabaseId'] as String?,
      );
}

class LetterRepository {
  LetterRepository({
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

  Future<void> migrateLegacySharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_legacyKey);
      if (raw == null || raw.isEmpty) return;
      final userId = _remote.currentUserId;
      if (userId != null) {
        for (final item in raw) {
          try {
            final legacy = Letter.fromJson(
              Map<String, dynamic>.from(jsonDecode(item) as Map),
            );
            if (legacy.userId != userId) continue;
            await _db.into(_db.letters).insert(
                  LettersCompanion.insert(
                    createdAt: legacy.createdAt,
                    openAt: legacy.openAt,
                    title: legacy.title,
                    body: legacy.body,
                    userId: Value(userId),
                    supabaseId: Value(legacy.supabaseId ?? _uuidGenerator()),
                    syncState: Value(
                      legacy.supabaseId == null
                          ? contentSyncPendingUpsert
                          : contentSyncSynced,
                    ),
                    changedAt: Value(DateTime.now()),
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
          } catch (_) {
            // Invalid or ownerless global legacy rows are not reassigned.
          }
        }
      }
      await prefs.remove(_legacyKey);
    } catch (_) {
      // Legacy preference cleanup must not affect current persistence.
    }
  }

  Future<List<Letter>> load() async {
    await migrateLegacySharedPreferencesData();
    final userId = _remote.currentUserId;
    if (userId == null) return const [];
    final rows = await (_db.select(_db.letters)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncPendingDelete).not())
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
    return rows.map(Letter.fromRow).toList(growable: false);
  }

  Future<void> save({
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    final userId = _requireCurrentUser();
    final now = DateTime.now();
    await _db.into(_db.letters).insert(
          LettersCompanion.insert(
            createdAt: now,
            openAt: openAt,
            title: title.trim(),
            body: body.trim(),
            userId: Value(userId),
            supabaseId: Value(_uuidGenerator()),
            syncState: const Value(contentSyncPendingUpsert),
            changedAt: Value(now),
          ),
        );
    unawaited(syncForCurrentUser());
  }

  Future<void> update({
    required int localId,
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.letters)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null || isContentTombstone(row.syncState)) return;
    await (_db.update(_db.letters)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      LettersCompanion(
        openAt: Value(openAt),
        title: Value(title.trim()),
        body: Value(body.trim()),
        supabaseId: Value(row.supabaseId ?? _uuidGenerator()),
        syncState: const Value(contentSyncPendingUpsert),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> delete(int localId, {String? supabaseId}) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.letters)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final cloudId = row.supabaseId ?? supabaseId;
    if (cloudId == null) {
      await (_db.delete(_db.letters)
            ..where((table) =>
                table.id.equals(localId) & table.userId.equals(userId)))
          .go();
      return;
    }
    await (_db.update(_db.letters)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      LettersCompanion(
        supabaseId: Value(cloudId),
        syncState: const Value(contentSyncPendingDelete),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> deleteAll() => _db.delete(_db.letters).go();

  Future<void> fetchAndSyncFromSupabase() => syncForCurrentUser();

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
        _lettersTable,
        userId: userId,
        orderBy: 'created_at',
      );
      if (_remote.currentUserId != userId) return;
      await _pull(userId, cloud);
    } catch (error) {
      debugPrint('[LetterSync] pull deferred error=${error.runtimeType}');
    }
  }

  Future<void> _pushPending(String userId) async {
    final rows = await (_db.select(_db.letters)
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
              _lettersTable,
              userId: userId,
              rowId: row.supabaseId!,
            );
          }
          if (_remote.currentUserId != userId) return;
          await (_db.delete(_db.letters)
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
          await (_db.update(_db.letters)
                ..where((table) =>
                    table.id.equals(row.id) & table.userId.equals(userId)))
              .write(LettersCompanion(supabaseId: Value(cloudId)));
          row = row.copyWith(supabaseId: Value(cloudId));
        }
        await _remote.upsertRow(_lettersTable, {
          'id': row.supabaseId,
          'user_id': userId,
          'title': row.title,
          'body': row.body,
          'open_at': row.openAt.toUtc().toIso8601String(),
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        if (_remote.currentUserId != userId) return;
        await (_db.update(_db.letters)
              ..where((table) =>
                  table.id.equals(row.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(contentSyncPendingUpsert) &
                  table.changedAt.equals(pushedAt)))
            .write(
          const LettersCompanion(syncState: Value(contentSyncSynced)),
        );
      } catch (error) {
        debugPrint('[LetterSync] push deferred error=${error.runtimeType}');
      }
    }
  }

  Future<void> _pull(
    String userId,
    List<Map<String, dynamic>> cloudRows,
  ) async {
    final cloudMap = <String, Map<String, dynamic>>{
      for (final row in cloudRows)
        if (row['id']?.toString().isNotEmpty ?? false)
          row['id'].toString(): row,
    };
    final locals = await (_db.select(_db.letters)
          ..where((table) => table.userId.equals(userId)))
        .get();
    final localByCloud = <String, LetterRow>{
      for (final row in locals)
        if (row.supabaseId != null) row.supabaseId!: row,
    };
    for (final entry in cloudMap.entries) {
      if (_remote.currentUserId != userId) return;
      final local = localByCloud[entry.key];
      if (local != null && local.syncState != contentSyncSynced) continue;
      final row = entry.value;
      final createdAt = _parseDate(row['created_at']) ?? DateTime.now();
      final openAt = _parseDate(row['open_at']) ?? createdAt;
      if (local == null) {
        await _db.into(_db.letters).insert(
              LettersCompanion.insert(
                createdAt: createdAt,
                openAt: openAt,
                title: row['title']?.toString() ?? '',
                body: row['body']?.toString() ?? '',
                userId: Value(userId),
                supabaseId: Value(entry.key),
                syncState: const Value(contentSyncSynced),
                changedAt: Value(createdAt),
              ),
            );
      } else {
        await (_db.update(_db.letters)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .write(
          LettersCompanion(
            createdAt: Value(createdAt),
            openAt: Value(openAt),
            title: Value(row['title']?.toString() ?? ''),
            body: Value(row['body']?.toString() ?? ''),
            syncState: const Value(contentSyncSynced),
            changedAt: Value(createdAt),
          ),
        );
      }
    }
    for (final local in locals) {
      if (local.syncState != contentSyncSynced || local.supabaseId == null) {
        continue;
      }
      if (!cloudMap.containsKey(local.supabaseId)) {
        await (_db.delete(_db.letters)
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
