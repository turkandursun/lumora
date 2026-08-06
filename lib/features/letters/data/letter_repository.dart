import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

/// A letter the user writes to their future self, sealed until [openAt].
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

  /// Readable once the open date has arrived.
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
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        openAt: DateTime.tryParse(json['openAt'] as String? ?? '') ?? DateTime.now(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        userId: json['userId'] as String?,
        supabaseId: json['supabaseId'] as String?,
      );
}

const _legacyKey = 'letters_v1';

/// On-device store for future-self letters via [AppDatabase] and sync to Supabase's `letters` table.
class LetterRepository {
  LetterRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  /// Migrates legacy letters saved in SharedPreferences 'letters_v1' to local Drift DB + Supabase.
  Future<void> migrateLegacySharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_legacyKey);
      if (rawList == null || rawList.isEmpty) return;

      final user = _client.auth.currentUser;
      debugPrint('[LetterMigration] Found ${rawList.length} legacy letters in SharedPreferences. Migrating to Drift...');

      for (final item in rawList) {
        try {
          final json = jsonDecode(item) as Map<String, dynamic>;
          final title = json['title'] as String? ?? '';
          final body = json['body'] as String? ?? '';
          final createdAtStr = json['createdAt'] as String?;
          final openAtStr = json['openAt'] as String?;

          final createdAt = createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now();
          final openAt = openAtStr != null
              ? DateTime.tryParse(openAtStr) ?? DateTime.now()
              : DateTime.now();

          String? cloudId;
          if (user != null) {
            try {
              final insertedRow = await _client.from('letters').insert({
                'user_id': user.id,
                'title': title,
                'body': body,
                'open_at': openAt.toIso8601String(),
                'created_at': createdAt.toIso8601String(),
              }).select('id').single();
              cloudId = insertedRow['id']?.toString();
            } catch (e) {
              debugPrint('[LetterMigration] Error uploading legacy letter to Supabase: $e');
            }
          }

          await _db.into(_db.letters).insert(
                LettersCompanion.insert(
                  createdAt: createdAt,
                  openAt: openAt,
                  title: title,
                  body: body,
                  userId: Value(user?.id),
                  supabaseId: Value(cloudId),
                ),
              );
        } catch (e) {
          debugPrint('[LetterMigration] Error parsing legacy item: $e');
        }
      }

      await prefs.remove(_legacyKey);
      debugPrint('[LetterMigration] Legacy SharedPreferences key "$_legacyKey" successfully cleared.');
    } catch (e) {
      debugPrint('[LetterMigration] Error during legacy migration: $e');
    }
  }

  /// Loads letters for the current user from Drift DB (sorted newest first).
  Future<List<Letter>> load() async {
    await migrateLegacySharedPreferencesData();

    final user = _client.auth.currentUser;
    if (user == null) {
      final rows = await (_db.select(_db.letters)
            ..where((t) => t.userId.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return rows.map(Letter.fromRow).toList();
    }

    final rows = await (_db.select(_db.letters)
          ..where((t) => t.userId.equals(user.id))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(Letter.fromRow).toList();
  }

  /// Inserts a new letter into local Drift DB and Supabase `letters` table.
  Future<void> save({
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    await migrateLegacySharedPreferencesData();

    final user = _client.auth.currentUser;
    final now = DateTime.now();

    String? cloudId;
    if (user != null) {
      try {
        final insertedRow = await _client.from('letters').insert({
          'user_id': user.id,
          'title': title.trim(),
          'body': body.trim(),
          'open_at': openAt.toIso8601String(),
          'created_at': now.toIso8601String(),
        }).select('id').single();
        cloudId = insertedRow['id']?.toString();
        debugPrint('[LetterSync] Successfully inserted letter into Supabase, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[LetterSync] Error inserting into Supabase: $e');
      }
    }

    await _db.into(_db.letters).insert(
          LettersCompanion.insert(
            createdAt: now,
            openAt: openAt,
            title: title.trim(),
            body: body.trim(),
            userId: Value(user?.id),
            supabaseId: Value(cloudId),
          ),
        );
  }

  /// Deletes a letter locally and from Supabase.
  Future<void> delete(int localId, {String? supabaseId}) async {
    final user = _client.auth.currentUser;
    debugPrint('[LetterDelete] Deleting localId=$localId, supabaseId=$supabaseId');

    if (user != null) {
      await (_db.delete(_db.letters)
            ..where((t) => t.id.equals(localId) & (t.userId.equals(user.id) | t.userId.isNull())))
          .go();
    } else {
      await (_db.delete(_db.letters)..where((t) => t.id.equals(localId))).go();
    }

    try {
      if (user != null && supabaseId != null) {
        await _client
            .from('letters')
            .delete()
            .eq('id', supabaseId)
            .eq('user_id', user.id);
        debugPrint('[LetterSync] Successfully deleted letter from Supabase');
      }
    } catch (e) {
      debugPrint('[LetterSync] Error deleting letter from Supabase: $e');
    }
  }

  /// Deletes all local letters (used on signout).
  Future<void> deleteAll() async {
    await _db.delete(_db.letters).go();
  }

  /// Fetches the user's letters from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> fetchAndSyncFromSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('letters')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final cloudRows = response as List;
      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id']?.toString();
        if (id != null) {
          cloudMap[id] = row as Map<String, dynamic>;
        }
      }

      final localEntries = await (_db.select(_db.letters)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, LetterRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.letters)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[LetterSync] Deleted local letter with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally
      for (final cloudId in cloudMap.keys) {
        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final row = cloudMap[cloudId]!;
          final title = row['title'] as String? ?? '';
          final body = row['body'] as String? ?? '';
          final createdAtStr = row['created_at'] as String?;
          final openAtStr = row['open_at'] as String?;

          final createdAt = createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now();

          final openAt = openAtStr != null
              ? DateTime.tryParse(openAtStr) ?? DateTime.now()
              : DateTime.now();

          await _db.into(_db.letters).insert(
                LettersCompanion.insert(
                  createdAt: createdAt,
                  openAt: openAt,
                  title: title,
                  body: body,
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );
          debugPrint('[LetterSync] Inserted cloud letter locally, cloudId=$cloudId');
        }
      }
    } catch (e) {
      debugPrint('[LetterSync] Error fetching letters from Supabase: $e');
    }
  }
}
