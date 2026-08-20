import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/user_content_sync.dart';

const _journalBucket = 'journal-photos';
const _journalTable = 'journal_entries';

typedef JournalEntriesRemoteDataSource = UserContentRemoteDataSource;

/// Local-first journal persistence with a durable Drift outbox.
class JournalEntriesRepository {
  JournalEntriesRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting UserContentRemoteDataSource? remoteDataSource,
    @visibleForTesting String Function()? uuidGenerator,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client,
        _uuidGenerator = uuidGenerator ?? newUserContentUuid {
    _remote = remoteDataSource ?? SupabaseUserContentRemoteDataSource(_client);
    unawaited(_clearLegacyPhotoPrefs());
  }

  final AppDatabase _db;
  final SupabaseClient _client;
  final String Function() _uuidGenerator;
  late final UserContentRemoteDataSource _remote;
  final Map<String, Future<void>> _syncInFlight = {};
  final Set<String> _syncRequestedAgain = {};

  Future<void> _clearLegacyPhotoPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('journal_entry_photos');
    } catch (_) {
      // Legacy cleanup must never affect journal persistence.
    }
  }

  Future<void> save(
    String content, {
    String? title,
    String? audioPath,
    String? photoPath,
    Uint8List? photoBytes,
  }) async {
    final userId = _requireCurrentUser();
    final now = DateTime.now();
    final cloudId = _uuidGenerator();
    final localId = await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            createdAt: now,
            content: content,
            title: Value(_blankToNull(title)),
            audioPath: Value(audioPath),
            photoUrl: Value(photoPath),
            userId: Value(userId),
            supabaseId: Value(cloudId),
            syncState: const Value(contentSyncPendingUpsert),
            changedAt: Value(now),
          ),
        );

    if (photoBytes != null || photoPath != null) {
      try {
        final url = await _uploadPhoto(
          userId: userId,
          cloudId: cloudId,
          bytes: photoBytes,
          localPath: photoPath,
        );
        if (_remote.currentUserId == userId && url != null) {
          await (_db.update(_db.journalEntries)
                ..where((table) =>
                    table.id.equals(localId) & table.userId.equals(userId)))
              .write(JournalEntriesCompanion(photoUrl: Value(url)));
        }
      } catch (error) {
        debugPrint(
          '[JournalSync] photo upload deferred error=${error.runtimeType}',
        );
      }
    }
    unawaited(syncForCurrentUser());
  }

  Future<void> update(
    int localId, {
    required String content,
    String? audioPath,
    String? photoUrl,
    String? supabaseId,
  }) async {
    final userId = _requireCurrentUser();
    final existing = await (_db.select(_db.journalEntries)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (existing == null || isContentTombstone(existing.syncState)) return;
    final now = nextContentChangedAt(existing.changedAt);
    await (_db.update(_db.journalEntries)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      JournalEntriesCompanion(
        content: Value(content),
        audioPath: Value(audioPath),
        photoUrl: Value(photoUrl),
        supabaseId:
            Value(existing.supabaseId ?? supabaseId ?? _uuidGenerator()),
        syncState: const Value(contentSyncPendingUpsert),
        changedAt: Value(now),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> delete(int localId, {String? supabaseId}) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.journalEntries)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final cloudId = row.supabaseId ?? supabaseId;
    if (cloudId == null) {
      await (_db.delete(_db.journalEntries)
            ..where((table) =>
                table.id.equals(localId) & table.userId.equals(userId)))
          .go();
      return;
    }
    await (_db.update(_db.journalEntries)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      JournalEntriesCompanion(
        supabaseId: Value(cloudId),
        syncState: const Value(contentSyncPendingDelete),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> deleteAll() => _db.delete(_db.journalEntries).go();

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
    await _reconcileLocalDuplicatesForUser(userId);
    await _pushPending(userId);
    if (_remote.currentUserId != userId) return;
    try {
      final cloudRows = await _remote.fetchRows(
        _journalTable,
        userId: userId,
        orderBy: 'created_at',
      );
      if (_remote.currentUserId != userId) return;
      await _pull(userId, cloudRows);
    } catch (error) {
      debugPrint('[JournalSync] pull deferred error=${error.runtimeType}');
    }
  }

  Future<void> _pushPending(String userId) async {
    final rows = await (_db.select(_db.journalEntries)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncSynced).not()))
        .get();
    for (var row in rows) {
      if (_remote.currentUserId != userId) return;
      final pushedAt = row.changedAt;
      try {
        if (isContentTombstone(row.syncState)) {
          final cloudId = row.supabaseId;
          if (cloudId != null) {
            await _remote.deleteRow(
              _journalTable,
              userId: userId,
              rowId: cloudId,
            );
          }
          if (_remote.currentUserId != userId) return;
          await (_db.delete(_db.journalEntries)
                ..where((table) =>
                    table.id.equals(row.id) &
                    table.userId.equals(userId) &
                    table.syncState.equals(contentSyncPendingDelete) &
                    table.changedAt.equals(pushedAt)))
              .go();
          continue;
        }

        var cloudId = row.supabaseId;
        if (cloudId == null) {
          cloudId = _uuidGenerator();
          await (_db.update(_db.journalEntries)
                ..where((table) =>
                    table.id.equals(row.id) & table.userId.equals(userId)))
              .write(JournalEntriesCompanion(supabaseId: Value(cloudId)));
          row = row.copyWith(supabaseId: Value(cloudId));
        }

        var remotePhoto = row.photoUrl;
        if (_looksLikeLocalPath(remotePhoto)) {
          remotePhoto = await _uploadPhoto(
            userId: userId,
            cloudId: cloudId,
            localPath: remotePhoto,
          );
          if (remotePhoto == null) throw StateError('Photo unavailable');
          await (_db.update(_db.journalEntries)
                ..where((table) =>
                    table.id.equals(row.id) & table.userId.equals(userId)))
              .write(JournalEntriesCompanion(photoUrl: Value(remotePhoto)));
        }

        await _remote.upsertRow(_journalTable, {
          'id': cloudId,
          'user_id': userId,
          'content': row.content,
          'title': _blankToNull(row.title),
          'audio_path': row.audioPath,
          'photo_url': remotePhoto,
          'created_at': row.createdAt.toUtc().toIso8601String(),
          'updated_at': pushedAt.toUtc().toIso8601String(),
        });
        if (_remote.currentUserId != userId) return;
        await (_db.update(_db.journalEntries)
              ..where((table) =>
                  table.id.equals(row.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(contentSyncPendingUpsert) &
                  table.changedAt.equals(pushedAt)))
            .write(
          const JournalEntriesCompanion(
            syncState: Value(contentSyncSynced),
          ),
        );
      } catch (error) {
        debugPrint('[JournalSync] push deferred error=${error.runtimeType}');
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
    final localRows = await (_db.select(_db.journalEntries)
          ..where((table) => table.userId.equals(userId)))
        .get();
    final localByCloud = <String, JournalEntryRow>{
      for (final row in localRows)
        if (row.supabaseId != null) row.supabaseId!: row,
    };

    for (final entry in cloudMap.entries) {
      if (_remote.currentUserId != userId) return;
      final local = localByCloud[entry.key];
      if (local != null && local.syncState != contentSyncSynced) continue;
      final row = entry.value;
      final content = row['content']?.toString() ?? '';
      if (content.isEmpty) continue;
      final createdAt = _parseDate(row['created_at']) ?? DateTime.now();
      if (local == null) {
        await _db.into(_db.journalEntries).insert(
              JournalEntriesCompanion.insert(
                createdAt: createdAt,
                content: content,
                title: Value(row['title'] as String?),
                audioPath: Value(row['audio_path'] as String?),
                photoUrl: Value(row['photo_url'] as String?),
                userId: Value(userId),
                supabaseId: Value(entry.key),
                syncState: const Value(contentSyncSynced),
                changedAt: Value(
                  _parseDate(row['updated_at']) ?? createdAt,
                ),
              ),
            );
      } else {
        await (_db.update(_db.journalEntries)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .write(
          JournalEntriesCompanion(
            createdAt: Value(createdAt),
            content: Value(content),
            title: Value(row['title'] as String?),
            audioPath: Value(row['audio_path'] as String?),
            photoUrl: Value(row['photo_url'] as String?),
            syncState: const Value(contentSyncSynced),
            changedAt: Value(_parseDate(row['updated_at']) ?? createdAt),
          ),
        );
      }
    }

    for (final local in localRows) {
      if (local.syncState != contentSyncSynced || local.supabaseId == null) {
        continue;
      }
      if (!cloudMap.containsKey(local.supabaseId)) {
        await (_db.delete(_db.journalEntries)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .go();
      }
    }
  }

  Future<String?> _uploadPhoto({
    required String userId,
    required String cloudId,
    Uint8List? bytes,
    String? localPath,
  }) async {
    var uploadBytes = bytes;
    var extension = 'jpg';
    if (uploadBytes == null && localPath != null && !kIsWeb) {
      final file = File(localPath);
      if (!await file.exists()) return null;
      uploadBytes = await file.readAsBytes();
      final rawExtension = p.extension(localPath).replaceFirst('.', '');
      if (rawExtension.isNotEmpty) extension = rawExtension.toLowerCase();
    }
    if (uploadBytes == null || uploadBytes.isEmpty) return null;
    final storagePath = '$userId/$cloudId.$extension';
    await _client.storage.from(_journalBucket).uploadBinary(
          storagePath,
          uploadBytes,
          fileOptions: FileOptions(
            contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}',
            upsert: true,
          ),
        );
    return _client.storage
        .from(_journalBucket)
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
  }

  @visibleForTesting
  Future<int> reconcileLocalDuplicatesForCurrentUser() async {
    final userId = _remote.currentUserId;
    if (userId == null) return 0;
    return _reconcileLocalDuplicatesForUser(userId);
  }

  Future<int> _reconcileLocalDuplicatesForUser(String userId) async {
    final rows = await (_db.select(_db.journalEntries)
          ..where((table) =>
              table.userId.equals(userId) & table.supabaseId.isNotNull()))
        .get();
    final byCloudId = <String, List<JournalEntryRow>>{};
    for (final row in rows) {
      byCloudId.putIfAbsent(row.supabaseId!, () => []).add(row);
    }
    var removed = 0;
    await _db.transaction(() async {
      for (final group in byCloudId.values) {
        if (group.length < 2) continue;
        group.sort((left, right) => right.id.compareTo(left.id));
        for (final duplicate in group.skip(1)) {
          removed += await (_db.delete(_db.journalEntries)
                ..where((table) =>
                    table.id.equals(duplicate.id) &
                    table.userId.equals(userId)))
              .go();
        }
      }
    });
    return removed;
  }

  Stream<List<JournalEntryRow>> watchRecent({int limit = 20}) {
    final userId = _remote.currentUserId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.journalEntries)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncPendingDelete).not())
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
          ..limit(limit))
        .watch();
  }

  Stream<List<JournalEntryRow>> watchAll() {
    final userId = _remote.currentUserId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.journalEntries)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncPendingDelete).not())
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .watch();
  }

  String _requireCurrentUser() {
    final userId = _remote.currentUserId;
    if (userId == null) {
      throw StateError('An authenticated user is required.');
    }
    return userId;
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool _looksLikeLocalPath(String? value) {
  if (value == null || value.isEmpty) return false;
  if (RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value) || value.startsWith('/')) {
    return true;
  }
  final uri = Uri.tryParse(value);
  return uri == null || !{'http', 'https'}.contains(uri.scheme.toLowerCase());
}
