import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

/// Owns persistence for journal entries written in Home's writing area.
/// Keeps local Drift SQLite as the primary source of truth while backing up
/// and syncing entries to Supabase's `journal_entries` table in the cloud.
class JournalEntriesRepository {
  JournalEntriesRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  Future<void> save(
    String content, {
    String? audioPath,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();
    debugPrint('[JournalSave] about to insert content="$content"');

    String? cloudId;
    if (user != null) {
      try {
        final createdIso = now.toIso8601String();
        final data = <String, dynamic>{
          'user_id': user.id,
          'content': content,
          'created_at': createdIso,
          'updated_at': createdIso,
        };
        if (audioPath != null) {
          data['audio_path'] = audioPath;
        }

        final insertedRow =
            await _client.from('journal_entries').insert(data).select('id').single();
        cloudId = insertedRow['id'] as String?;
        debugPrint('[JournalSync] Successfully inserted entry to Supabase, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[JournalSync] Error inserting into Supabase: $e');
      }
    }

    final id = await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            createdAt: now,
            content: content,
            audioPath: Value(audioPath),
            userId: Value(user?.id),
            supabaseId: Value(cloudId),
          ),
        );
    debugPrint('[JournalSave] insert complete, new row id=$id');
  }

  Future<void> update(int localId, String content, {String? supabaseId}) async {
    await (_db.update(_db.journalEntries)..where((t) => t.id.equals(localId))).write(
      JournalEntriesCompanion(
        content: Value(content),
      ),
    );

    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final nowIso = DateTime.now().toIso8601String();
        if (supabaseId != null) {
          await _client.from('journal_entries').update({
            'content': content,
            'updated_at': nowIso,
          }).eq('id', supabaseId).eq('user_id', user.id);
        } else {
          await _client.from('journal_entries').update({
            'content': content,
            'updated_at': nowIso,
          }).eq('user_id', user.id).eq('content', content);
        }
      }
    } catch (e) {
      debugPrint('[JournalSync] Error updating Supabase: $e');
    }
  }

  Future<void> delete(int localId, {String? supabaseId}) async {
    await (_db.delete(_db.journalEntries)..where((t) => t.id.equals(localId))).go();

    try {
      final user = _client.auth.currentUser;
      if (user != null && supabaseId != null) {
        await _client.from('journal_entries').delete().eq('id', supabaseId).eq('user_id', user.id);
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
  Future<void> fetchAndSyncFromSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('journal_entries')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final cloudRows = response as List;
      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id'] as String?;
        if (id != null) {
          cloudMap[id] = row as Map<String, dynamic>;
        }
      }

      final localEntries = await (_db.select(_db.journalEntries)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, JournalEntryRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.journalEntries)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[JournalSync] Deleted local entry with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally
      for (final cloudId in cloudMap.keys) {
        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final row = cloudMap[cloudId]!;
          final content = row['content'] as String?;
          final createdAtStr = row['created_at'] as String?;
          final audioPath = row['audio_path'] as String?;
          if (content == null || content.isEmpty) continue;

          final createdAt = createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now();

          await _db.into(_db.journalEntries).insert(
                JournalEntriesCompanion.insert(
                  createdAt: createdAt,
                  content: content,
                  audioPath: Value(audioPath),
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );
          debugPrint('[JournalSync] Inserted cloud entry locally, cloudId=$cloudId');
        }
      }
    } catch (e) {
      debugPrint('[JournalSync] Error fetching from Supabase: $e');
    }
  }

  /// Only returns journal entries belonging to the currently logged in user.
  Stream<List<JournalEntryRow>> watchRecent({int limit = 20}) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value(const []);
    return (_db.select(_db.journalEntries)
          ..where((t) => t.userId.equals(currentUserId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Every saved entry for the current user, newest first — used by calendar and stats.
  Stream<List<JournalEntryRow>> watchAll() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return Stream.value(const []);
    return (_db.select(_db.journalEntries)
          ..where((t) => t.userId.equals(currentUserId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
