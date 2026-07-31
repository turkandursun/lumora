import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

/// One day's gratitude entry: a date and up to a few things the user was
/// grateful for.
class GratitudeEntry {
  const GratitudeEntry({
    this.id,
    required this.date,
    required this.items,
    this.mood,
    this.userId,
    this.supabaseId,
  });

  final int? id;
  final DateTime date;
  final List<String> items;

  /// Optional emoji/mood the user tagged this day's gratitude with.
  final String? mood;
  final String? userId;
  final String? supabaseId;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'items': items,
        if (mood != null) 'mood': mood,
        if (userId != null) 'userId': userId,
        if (supabaseId != null) 'supabaseId': supabaseId,
      };

  factory GratitudeEntry.fromJson(Map<String, dynamic> json) => GratitudeEntry(
        id: json['id'] as int?,
        date: DateTime.parse(json['date'] as String),
        items: (json['items'] as List).map((e) => e.toString()).toList(),
        mood: json['mood'] as String?,
        userId: json['userId'] as String?,
        supabaseId: json['supabaseId'] as String?,
      );

  factory GratitudeEntry.fromRow(GratitudeEntryRow row) {
    List<String> parsedItems = const [];
    try {
      final decoded = jsonDecode(row.itemsJson);
      if (decoded is List) {
        parsedItems = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return GratitudeEntry(
      id: row.id,
      date: row.date,
      items: parsedItems,
      mood: row.mood,
      userId: row.userId,
      supabaseId: row.supabaseId,
    );
  }
}

const _legacyKey = 'gratitude_v1';

/// Owns on-device persistence for gratitude entries via [AppDatabase] and
/// syncing to Supabase's `gratitude_entries` table in the cloud.
class GratitudeRepository {
  GratitudeRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Reads user's gratitude entries from local Drift DB (filtered by currentUser.id),
  /// sorted newest date first.
  Future<List<GratitudeEntry>> load() async {
    await migrateLegacySharedPreferencesData();

    final user = _client.auth.currentUser;
    if (user == null) {
      final rows = await (_db.select(_db.gratitudeEntries)
            ..where((t) => t.userId.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
      return rows.map(GratitudeEntry.fromRow).toList();
    }

    final rows = await (_db.select(_db.gratitudeEntries)
          ..where((t) => t.userId.equals(user.id))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(GratitudeEntry.fromRow).toList();
  }

  /// Saves today's gratitude items (and optional [mood]), replacing any
  /// existing entry for today locally and in Supabase `gratitude_entries`.
  Future<void> saveToday(List<String> items, {String? mood}) async {
    final user = _client.auth.currentUser;
    final today = dateOnly(DateTime.now());
    final cleaned = items.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final itemsJsonStr = jsonEncode(cleaned);
    final entryDateStr = today.toIso8601String().split('T').first;

    String? cloudId;
    if (user != null) {
      try {
        final upsertData = <String, dynamic>{
          'user_id': user.id,
          'entry_date': entryDateStr,
          'items': cleaned,
          if (mood != null) 'mood': mood,
        };

        final response = await _client
            .from('gratitude_entries')
            .upsert(upsertData, onConflict: 'user_id, entry_date')
            .select('id')
            .single();

        cloudId = response['id'] as String?;
        debugPrint('[GratitudeSync] Upserted to Supabase successfully, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[GratitudeSync] Error upserting to Supabase: $e');
      }
    }

    GratitudeEntryRow? existing;
    if (user != null) {
      existing = await (_db.select(_db.gratitudeEntries)
            ..where((t) => t.userId.equals(user.id) & t.date.equals(today)))
          .getSingleOrNull();
    } else {
      existing = await (_db.select(_db.gratitudeEntries)
            ..where((t) => t.userId.isNull() & t.date.equals(today)))
          .getSingleOrNull();
    }

    final existingRow = existing;
    if (cleaned.isEmpty) {
      if (existingRow != null) {
        await (_db.delete(_db.gratitudeEntries)..where((t) => t.id.equals(existingRow.id))).go();
      }
      return;
    }

    if (existingRow != null) {
      await (_db.update(_db.gratitudeEntries)..where((t) => t.id.equals(existingRow.id))).write(
        GratitudeEntriesCompanion(
          itemsJson: Value(itemsJsonStr),
          mood: Value(mood),
          supabaseId: Value(cloudId ?? existingRow.supabaseId),
        ),
      );
    } else {
      await _db.into(_db.gratitudeEntries).insert(
            GratitudeEntriesCompanion.insert(
              date: today,
              itemsJson: itemsJsonStr,
              mood: Value(mood),
              userId: Value(user?.id),
              supabaseId: Value(cloudId),
            ),
          );
    }
  }

  /// Deletes all local gratitude entries from Drift SQLite (e.g. upon user logout).
  Future<void> deleteAll() async {
    await _db.delete(_db.gratitudeEntries).go();
  }

  /// One-time migration: reads legacy SharedPreferences 'gratitude_v1' data,
  /// inserts into new Drift table, then deletes 'gratitude_v1' key.
  Future<void> migrateLegacySharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_legacyKey);
      if (raw == null || raw.isEmpty) return;

      final user = _client.auth.currentUser;
      debugPrint('[GratitudeMigration] Migrating ${raw.length} legacy entries from SharedPreferences...');

      for (final item in raw) {
        try {
          final json = jsonDecode(item) as Map<String, dynamic>;
          final legacyEntry = GratitudeEntry.fromJson(json);
          final date = dateOnly(legacyEntry.date);
          final itemsJsonStr = jsonEncode(legacyEntry.items);

          GratitudeEntryRow? existing;
          if (user != null) {
            existing = await (_db.select(_db.gratitudeEntries)
                  ..where((t) => t.userId.equals(user.id) & t.date.equals(date)))
                .getSingleOrNull();
          } else {
            existing = await (_db.select(_db.gratitudeEntries)
                  ..where((t) => t.userId.isNull() & t.date.equals(date)))
                .getSingleOrNull();
          }

          if (existing == null) {
            await _db.into(_db.gratitudeEntries).insert(
                  GratitudeEntriesCompanion.insert(
                    date: date,
                    itemsJson: itemsJsonStr,
                    mood: Value(legacyEntry.mood),
                    userId: Value(user?.id),
                  ),
                );
          }
        } catch (e) {
          debugPrint('[GratitudeMigration] Error parsing item: $e');
        }
      }

      await prefs.remove(_legacyKey);
      debugPrint('[GratitudeMigration] Legacy SharedPreferences migration completed and key removed.');
    } catch (e) {
      debugPrint('[GratitudeMigration] Error in legacy migration: $e');
    }
  }

  /// Fetches the user's gratitude entries from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> fetchAndSyncFromSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('gratitude_entries')
          .select()
          .eq('user_id', user.id)
          .order('entry_date', ascending: false);

      final cloudRows = response as List;
      final cloudMap = <String, Map<String, dynamic>>{};
      for (final row in cloudRows) {
        final id = row['id'] as String?;
        if (id != null) {
          cloudMap[id] = row as Map<String, dynamic>;
        }
      }

      final localEntries = await (_db.select(_db.gratitudeEntries)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, GratitudeEntryRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.gratitudeEntries)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[GratitudeSync] Deleted local gratitude entry with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Insert cloud entries that are missing locally
      for (final cloudId in cloudMap.keys) {
        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final row = cloudMap[cloudId]!;
          final entryDateStr = row['entry_date'] as String?;
          final rawItems = row['items'];
          final mood = row['mood'] as String?;

          List<String> items = const [];
          if (rawItems is List) {
            items = rawItems.map((e) => e.toString()).toList();
          }

          final date = entryDateStr != null
              ? DateTime.tryParse(entryDateStr) ?? DateTime.now()
              : DateTime.now();
          final normalizedDate = dateOnly(date);

          await _db.into(_db.gratitudeEntries).insert(
                GratitudeEntriesCompanion.insert(
                  date: normalizedDate,
                  itemsJson: jsonEncode(items),
                  mood: Value(mood),
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );
          debugPrint('[GratitudeSync] Inserted cloud gratitude entry locally, cloudId=$cloudId');
        }
      }
    } catch (e) {
      debugPrint('[GratitudeSync] Error fetching from Supabase: $e');
    }
  }
}
