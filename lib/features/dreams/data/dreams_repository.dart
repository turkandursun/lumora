import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import 'dream_symbol_keywords.dart';

/// The canonical symbol keys detected in [dream]'s text at save time.
List<String> symbolTagsFor(DreamRow dream) =>
    dream.symbolTags.isEmpty ? const [] : dream.symbolTags.split(',');

/// Owns dream entry persistence via [AppDatabase] and syncing to Supabase's
/// `dreams` table in the cloud. Symbol detection happens once, at save time,
/// using the local keyword dictionary in `dream_symbol_keywords.dart`.
class DreamsRepository {
  DreamsRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  /// Every saved dream for the currently logged in user, most recent first.
  Stream<List<DreamRow>> watchAll() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(const []);
    return (_db.select(_db.dreams)
          ..where((t) => t.userId.equals(user.id))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Inserts a new dream entry locally and in Supabase `dreams` table if logged in.
  /// Returns its local row id so the caller can follow up with [saveReflection].
  Future<int> addDream(String text) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();
    final trimmed = text.trim();
    final tags = detectDreamSymbols(trimmed);
    final symbolTagsStr = tags.join(',');

    String? cloudId;
    if (user != null) {
      try {
        final insertedRow = await _client.from('dreams').insert({
          'user_id': user.id,
          'content': trimmed,
          'date': now.toIso8601String(),
        }).select('id').single();
        cloudId = insertedRow['id'] as String?;
        debugPrint('[DreamsSync] Successfully inserted dream to Supabase, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[DreamsSync] Error inserting dream into Supabase: $e');
      }
    }

    final id = await _db.into(_db.dreams).insert(
          DreamsCompanion.insert(
            date: now,
            content: trimmed,
            symbolTags: Value(symbolTagsStr),
            userId: Value(user?.id),
            supabaseId: Value(cloudId),
          ),
        );
    return id;
  }

  /// Records whatever the user answered in the post-save reflection flow.
  /// Updates local Drift DB and cloud `dreams` table (if logged in and supabaseId exists).
  Future<void> saveReflection({
    required int id,
    String? feelingTag,
    String? familiarPerson,
    String? firstThought,
    String? lifeConnection,
  }) async {
    final user = _client.auth.currentUser;

    await (_db.update(_db.dreams)..where((t) => t.id.equals(id))).write(
      DreamsCompanion(
        feelingTag: Value(feelingTag),
        familiarPerson: Value(familiarPerson),
        firstThought: Value(firstThought),
        lifeConnection: Value(lifeConnection),
      ),
    );

    if (user != null) {
      try {
        final localRow = await (_db.select(_db.dreams)..where((t) => t.id.equals(id))).getSingleOrNull();
        final supabaseId = localRow?.supabaseId;
        if (supabaseId != null) {
          await _client.from('dreams').update({
            'feeling_tag': feelingTag,
            'familiar_person': familiarPerson,
            'first_thought': firstThought,
            'life_connection': lifeConnection,
          }).eq('id', supabaseId).eq('user_id', user.id);
          debugPrint('[DreamsSync] Successfully updated dream reflection in Supabase, cloudId=$supabaseId');
        }
      } catch (e) {
        debugPrint('[DreamsSync] Error updating dream reflection in Supabase: $e');
      }
    }
  }

  /// Caches an AI-generated interpretation against a dream in local Drift ONLY.
  /// Does NOT send anything to Supabase cloud.
  Future<void> saveAiInterpretation({required int id, required String interpretation}) async {
    await (_db.update(_db.dreams)..where((t) => t.id.equals(id))).write(
      DreamsCompanion(aiInterpretation: Value(interpretation)),
    );
  }

  /// Deletes a dream entry both from local Drift SQLite and from Supabase cloud (if synced).
  Future<void> deleteDream(int localId, {String? supabaseId}) async {
    final user = _client.auth.currentUser;
    debugPrint('[DreamsDelete] deleting localId=$localId, supabaseId=$supabaseId');

    if (user != null) {
      await (_db.delete(_db.dreams)
            ..where((t) => t.id.equals(localId) & (t.userId.equals(user.id) | t.userId.isNull())))
          .go();
    } else {
      await (_db.delete(_db.dreams)..where((t) => t.id.equals(localId))).go();
    }

    try {
      if (user != null && supabaseId != null) {
        await _client.from('dreams').delete().eq('id', supabaseId).eq('user_id', user.id);
        debugPrint('[DreamsSync] Successfully deleted dream from Supabase, cloudId=$supabaseId');
      }
    } catch (e) {
      debugPrint('[DreamsSync] Error deleting from Supabase: $e');
    }
  }

  /// Deletes all local dream entries from Drift SQLite (e.g. upon user logout).
  Future<void> deleteAll() async {
    await _db.delete(_db.dreams).go();
  }

  /// Fetches the user's dream entries from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> fetchAndSyncDreamsFromSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('dreams')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: false);

      final cloudRows = response as List;
      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id'] as String?;
        if (id != null) {
          cloudMap[id] = row as Map<String, dynamic>;
        }
      }

      final localEntries = await (_db.select(_db.dreams)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, DreamRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.dreams)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[DreamsSync] Deleted local dream with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally
      for (final cloudId in cloudMap.keys) {
        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final row = cloudMap[cloudId]!;
          final content = row['content'] as String?;
          final dateStr = row['date'] as String?;
          final feelingTag = row['feeling_tag'] as String?;
          final familiarPerson = row['familiar_person'] as String?;
          final firstThought = row['first_thought'] as String?;
          final lifeConnection = row['life_connection'] as String?;

          if (content == null || content.isEmpty) continue;

          final symbolTags = detectDreamSymbols(content).join(',');

          final date = dateStr != null
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();

          await _db.into(_db.dreams).insert(
                DreamsCompanion.insert(
                  date: date,
                  content: content,
                  symbolTags: Value(symbolTags),
                  feelingTag: Value(feelingTag),
                  familiarPerson: Value(familiarPerson),
                  firstThought: Value(firstThought),
                  lifeConnection: Value(lifeConnection),
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );
          debugPrint('[DreamsSync] Inserted cloud dream locally, cloudId=$cloudId');
        }
      }
    } catch (e) {
      debugPrint('[DreamsSync] Error fetching dreams from Supabase: $e');
    }
  }
}
