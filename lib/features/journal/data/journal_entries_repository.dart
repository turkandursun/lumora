import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

const _journalBucket = 'journal-photos';

abstract interface class JournalEntriesRemoteDataSource {
  String? get currentUserId;

  Future<Map<String, dynamic>> insertEntry(Map<String, dynamic> payload);

  Future<List<Map<String, dynamic>>> fetchEntries(String userId);
}

class SupabaseJournalEntriesRemoteDataSource
    implements JournalEntriesRemoteDataSource {
  SupabaseJournalEntriesRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>> insertEntry(
    Map<String, dynamic> payload,
  ) async {
    final row = await _client
        .from('journal_entries')
        .insert(payload)
        .select('id')
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEntries(String userId) async {
    final rows = await _client
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}

/// Owns persistence for journal entries written in Home's writing area.
/// Keeps local Drift SQLite as the primary source of truth while backing up
/// and syncing entries to Supabase's `journal_entries` table in the cloud.
class JournalEntriesRepository {
  JournalEntriesRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting JournalEntriesRemoteDataSource? remoteDataSource,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client {
    _remoteDataSource = remoteDataSource ??
        SupabaseJournalEntriesRemoteDataSource(_client);
    _clearLegacyPhotoPrefs();
  }

  final AppDatabase _db;
  final SupabaseClient _client;
  late final JournalEntriesRemoteDataSource _remoteDataSource;
  Future<void>? _syncInFlight;

  /// Clears old invalid SharedPreferences blob URL entries if any exist.
  Future<void> _clearLegacyPhotoPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('journal_entry_photos');
    } catch (_) {}
  }

  Future<void> save(
    String content, {
    String? title,
    String? audioPath,
    String? photoPath,
    Uint8List? photoBytes,
  }) async {
    final userId = _remoteDataSource.currentUserId;
    final now = DateTime.now();
    debugPrint(
      '[JournalSave] about to insert contentLength=${content.runes.length}',
    );

    String? photoUrl;
    if (userId != null && (photoBytes != null || photoPath != null)) {
      try {
        Uint8List? bytes = photoBytes;
        String fileExt = 'jpg';

        if (bytes == null && photoPath != null && !kIsWeb) {
          final file = File(photoPath);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
            final ext = p.extension(photoPath).replaceAll('.', '');
            if (ext.isNotEmpty) fileExt = ext;
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          final storagePath =
              '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

          await _client.storage.from(_journalBucket).uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(
                  contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
                  upsert: true,
                ),
              );

          final signedUrlResponse = await _client.storage
              .from(_journalBucket)
              .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
          photoUrl = signedUrlResponse;
          debugPrint('[JournalSync] Uploaded journal photo to Supabase Storage.');
        }
      } catch (e) {
        debugPrint('[JournalSync] Error uploading journal photo to Storage: $e');
      }
    }

    String? cloudId;
    if (userId != null) {
      try {
        final createdIso = now.toIso8601String();
        final data = <String, dynamic>{
          'user_id': userId,
          'content': content,
          'created_at': createdIso,
          'updated_at': createdIso,
        };
        if (title != null && title.isNotEmpty) {
          data['title'] = title;
        }
        if (audioPath != null) {
          data['audio_path'] = audioPath;
        }
        if (photoUrl != null) {
          data['photo_url'] = photoUrl;
        }

        final insertedRow = await _remoteDataSource.insertEntry(data);
        cloudId = insertedRow['id'] as String?;
        debugPrint('[JournalSync] Successfully inserted entry to Supabase, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[JournalSync] Error inserting into Supabase: $e');
      }
    }

    final id = userId != null && cloudId != null
        ? await _upsertCloudEntryLocally(
            userId: userId,
            cloudId: cloudId,
            createdAt: now,
            content: content,
            title: title,
            audioPath: audioPath,
            photoUrl: photoUrl,
          )
        : await _db.into(_db.journalEntries).insert(
              JournalEntriesCompanion.insert(
                createdAt: now,
                content: content,
                title: Value(title),
                audioPath: Value(audioPath),
                photoUrl: Value(photoUrl),
                userId: Value(userId),
                supabaseId: Value(cloudId),
              ),
            );
    debugPrint('[JournalSave] insert complete, new row id=$id');
  }

  Future<void> update(
    int localId, {
    required String content,
    String? audioPath,
    String? photoUrl,
    String? supabaseId,
  }) async {
    final userId = _remoteDataSource.currentUserId;
    debugPrint('[JournalUpdate] updating localId=$localId, supabaseId=$supabaseId');

    if (userId != null) {
      await (_db.update(_db.journalEntries)
            ..where((t) =>
                t.id.equals(localId) &
                (t.userId.equals(userId) | t.userId.isNull())))
          .write(
        JournalEntriesCompanion(
          content: Value(content),
          audioPath: Value(audioPath),
          photoUrl: Value(photoUrl),
        ),
      );
    } else {
      await (_db.update(_db.journalEntries)..where((t) => t.id.equals(localId))).write(
        JournalEntriesCompanion(
          content: Value(content),
          audioPath: Value(audioPath),
          photoUrl: Value(photoUrl),
        ),
      );
    }

    try {
      if (userId != null && supabaseId != null) {
        final nowIso = DateTime.now().toIso8601String();
        final data = <String, dynamic>{
          'content': content,
          'updated_at': nowIso,
        };
        if (audioPath != null) {
          data['audio_path'] = audioPath;
        }
        if (photoUrl != null) {
          data['photo_url'] = photoUrl;
        }

        await _client
            .from('journal_entries')
            .update(data)
            .eq('id', supabaseId)
            .eq('user_id', userId);
        debugPrint('[JournalSync] Successfully updated entry in Supabase');
      }
    } catch (e) {
      debugPrint('[JournalSync] Error updating Supabase: $e');
    }
  }

  Future<void> delete(int localId, {String? supabaseId}) async {
    final userId = _remoteDataSource.currentUserId;
    debugPrint('[JournalDelete] deleting localId=$localId, supabaseId=$supabaseId');

    if (userId != null) {
      await (_db.delete(_db.journalEntries)
            ..where((t) =>
                t.id.equals(localId) &
                (t.userId.equals(userId) | t.userId.isNull())))
          .go();
    } else {
      await (_db.delete(_db.journalEntries)..where((t) => t.id.equals(localId))).go();
    }

    try {
      if (userId != null && supabaseId != null) {
        await _client
            .from('journal_entries')
            .delete()
            .eq('id', supabaseId)
            .eq('user_id', userId);
        debugPrint('[JournalSync] Successfully deleted entry from Supabase');
      }
    } catch (e) {
      debugPrint('[JournalSync] Error deleting from Supabase: $e');
    }
  }

  /// Deletes all local journal entries from Drift SQLite (e.g. upon user logout).
  Future<void> deleteAll() async {
    await _db.delete(_db.journalEntries).go();
  }

  /// Fetches the user's journal entries from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> fetchAndSyncFromSupabase() {
    final existing = _syncInFlight;
    if (existing != null) return existing;

    late final Future<void> tracked;
    tracked = _fetchAndSyncFromSupabase().whenComplete(() {
      if (identical(_syncInFlight, tracked)) _syncInFlight = null;
    });
    _syncInFlight = tracked;
    return tracked;
  }

  Future<void> _fetchAndSyncFromSupabase() async {
    try {
      final userId = _remoteDataSource.currentUserId;
      if (userId == null) return;

      await _reconcileLocalDuplicatesForUser(userId);
      final cloudRows = await _remoteDataSource.fetchEntries(userId);
      if (_remoteDataSource.currentUserId != userId) return;
      debugPrint('[JournalSync] cloud fetched count=${cloudRows.length}');

      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id'] as String?;
        if (id != null) {
          cloudMap[id] = row;
        }
      }

      final localEntries = await (_db.select(_db.journalEntries)
            ..where((t) => t.userId.equals(userId)))
          .get();

      // Delete local entries that were deleted in cloud
      final localCloudIds = localEntries
          .map((entry) => entry.supabaseId)
          .whereType<String>()
          .toSet();
      for (final localSupabaseId in localCloudIds) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.journalEntries)
                ..where((t) =>
                    t.userId.equals(userId) &
                    t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[JournalSync] Deleted local entry with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally
      for (final cloudId in cloudMap.keys) {
        if (_remoteDataSource.currentUserId != userId) return;
        final row = cloudMap[cloudId]!;
        var photoUrl = row['photo_url'] as String?;

        if (photoUrl != null && photoUrl.contains('/object/public/$_journalBucket/')) {
          final storagePath = photoUrl.split('/object/public/$_journalBucket/').last;
          try {
            final signedUrl = await _client.storage
                .from(_journalBucket)
                .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
            photoUrl = signedUrl;
            row['photo_url'] = photoUrl;
            await _client
                .from('journal_entries')
                .update({'photo_url': photoUrl})
                .eq('id', cloudId)
                .eq('user_id', userId);
          } catch (e) {
            debugPrint('[JournalSync] Error healing photoUrl for cloudId=$cloudId: $e');
          }
        }

        final content = row['content'] as String?;
        final title = row['title'] as String?;
        final createdAtStr = row['created_at'] as String?;
        final audioPath = row['audio_path'] as String?;
        if (content == null || content.isEmpty) continue;

        final createdAt = createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now();

        await _upsertCloudEntryLocally(
          userId: userId,
          cloudId: cloudId,
          createdAt: createdAt,
          content: content,
          title: title,
          audioPath: audioPath,
          photoUrl: photoUrl,
        );
      }
      final countExpression = _db.journalEntries.id.count();
      final localCount = await (_db.selectOnly(_db.journalEntries)
            ..addColumns([countExpression])
            ..where(_db.journalEntries.userId.equals(userId)))
          .map((row) => row.read(countExpression) ?? 0)
          .getSingle();
      debugPrint('[JournalSync] local row count=$localCount');
    } catch (e) {
      debugPrint('[JournalSync] Error fetching from Supabase: $e');
    }
  }

  Future<int> _upsertCloudEntryLocally({
    required String userId,
    required String cloudId,
    required DateTime createdAt,
    required String content,
    required String? title,
    required String? audioPath,
    required String? photoUrl,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.journalEntries)
            ..where((table) =>
                table.userId.equals(userId) &
                table.supabaseId.equals(cloudId))
            ..orderBy([(table) => OrderingTerm.desc(table.id)])
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.journalEntries)
              ..where((table) =>
                  table.id.equals(existing.id) &
                  table.userId.equals(userId)))
            .write(
          JournalEntriesCompanion(
            createdAt: Value(createdAt),
            content: Value(content),
            title: Value(title),
            audioPath: Value(audioPath),
            photoUrl: Value(photoUrl),
            supabaseId: Value(cloudId),
          ),
        );
        debugPrint(
          '[JournalSync] local existing cloudId=$cloudId localId=${existing.id}',
        );
        return existing.id;
      }

      final localId = await _db.into(_db.journalEntries).insert(
            JournalEntriesCompanion.insert(
              createdAt: createdAt,
              content: content,
              title: Value(title),
              audioPath: Value(audioPath),
              photoUrl: Value(photoUrl),
              userId: Value(userId),
              supabaseId: Value(cloudId),
            ),
          );
      debugPrint(
        '[JournalSync] inserted local cloudId=$cloudId localId=$localId',
      );
      return localId;
    });
  }

  @visibleForTesting
  Future<int> reconcileLocalDuplicatesForCurrentUser() async {
    final userId = _remoteDataSource.currentUserId;
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
      for (final group in byCloudId.entries) {
        if (group.value.length < 2) continue;
        group.value.sort((left, right) => right.id.compareTo(left.id));
        final keeper = group.value.first;
        for (final duplicate in group.value.skip(1)) {
          removed += await (_db.delete(_db.journalEntries)
                ..where((table) =>
                    table.id.equals(duplicate.id) &
                    table.userId.equals(userId) &
                    table.supabaseId.equals(group.key)))
              .go();
        }
        debugPrint(
          '[JournalSync] reconciled duplicate cloudId=${group.key} '
          'keeperLocalId=${keeper.id} removed=${group.value.length - 1}',
        );
      }
    });
    return removed;
  }

  /// Only returns journal entries belonging to the currently logged in user.
  Stream<List<JournalEntryRow>> watchRecent({int limit = 20}) {
    final currentUserId = _remoteDataSource.currentUserId;
    if (currentUserId == null) return Stream.value(const []);
    return (_db.select(_db.journalEntries)
          ..where((t) => t.userId.equals(currentUserId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch()
        .map((rows) {
      debugPrint('[JournalUI] visible recent entries count=${rows.length}');
      return rows;
    });
  }

  /// Every saved entry for the current user, newest first — used by calendar and stats.
  Stream<List<JournalEntryRow>> watchAll() {
    final currentUserId = _remoteDataSource.currentUserId;
    if (currentUserId == null) return Stream.value(const []);
    return (_db.select(_db.journalEntries)
          ..where((t) => t.userId.equals(currentUserId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) {
      debugPrint('[JournalUI] visible all entries count=${rows.length}');
      return rows;
    });
  }
}
