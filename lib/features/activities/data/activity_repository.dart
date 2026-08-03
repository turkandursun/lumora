import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

/// One logged daily activity — what the user did, selected activity IDs, optional photo (local file path, public URL, or web in-memory bytes),
/// userId, and Supabase cloud ID.
class Activity {
  const Activity({
    this.id,
    required this.createdAt,
    this.activityIds = const [],
    required this.text,
    this.photoPath,
    this.photoUrl,
    this.photoBytes,
    this.userId,
    this.supabaseId,
    this.sharedId,
  });

  final int? id;
  final DateTime createdAt;
  final List<String> activityIds;
  final String text;
  final String? photoPath;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final String? userId;
  final String? supabaseId;
  final String? sharedId;

  bool get isShared => sharedId != null;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'createdAt': createdAt.toIso8601String(),
        'activityIds': activityIds,
        'text': text,
        if (photoPath != null) 'photoPath': photoPath,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (userId != null) 'userId': userId,
        if (supabaseId != null) 'supabaseId': supabaseId,
        if (sharedId != null) 'sharedId': sharedId,
      };

  factory Activity.fromJson(Map<String, dynamic> json) {
    List<String> ids = [];
    if (json['activityIds'] is List) {
      ids = (json['activityIds'] as List).map((e) => e.toString()).toList();
    }
    return Activity(
      id: json['id'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      activityIds: ids,
      text: json['text'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      photoUrl: json['photoUrl'] as String?,
      userId: json['userId'] as String?,
      supabaseId: json['supabaseId'] as String?,
      sharedId: json['sharedId'] as String?,
    );
  }

  factory Activity.fromRow(ActivityRow row) {
    List<String> ids = const [];
    try {
      final decoded = jsonDecode(row.activityIdsJson);
      if (decoded is List) {
        ids = decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('[Activity] Error parsing activityIdsJson: $e');
    }

    return Activity(
      id: row.id,
      createdAt: row.createdAt,
      activityIds: ids,
      text: row.activityText,
      photoPath: row.photoPath,
      photoUrl: row.photoUrl,
      userId: row.userId,
      supabaseId: row.supabaseId,
    );
  }
}

const _legacyKey = 'activities_v1';
const _storageBucket = 'activity-photos';

/// On-device store for activity entries via [AppDatabase] and sync to Supabase's `activities` table.
class ActivityRepository {
  ActivityRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  /// Loads activity entries from local Drift DB (filtered by currentUser.id),
  /// sorted newest first.
  Future<List<Activity>> load() async {
    await migrateLegacySharedPreferencesData();

    final user = _client.auth.currentUser;
    if (user == null) {
      final rows = await (_db.select(_db.activities)
            ..where((t) => t.userId.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return rows.map(Activity.fromRow).toList();
    }

    final rows = await (_db.select(_db.activities)
          ..where((t) => t.userId.equals(user.id))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(Activity.fromRow).toList();
  }

  /// Adds a new activity record to local Drift DB and uploads image/record to Supabase.
  Future<void> add(Activity activity) async {
    final user = _client.auth.currentUser;
    String? photoUrl = activity.photoUrl;
    String? cloudId;

    // 1. Upload photo to Supabase Storage if photoBytes or photoPath is present
    if (user != null && (activity.photoBytes != null || activity.photoPath != null)) {
      try {
        Uint8List? bytes = activity.photoBytes;
        String fileExt = 'jpg';

        if (bytes == null && activity.photoPath != null && !kIsWeb) {
          final file = File(activity.photoPath!);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
            final ext = p.extension(activity.photoPath!).replaceAll('.', '');
            if (ext.isNotEmpty) fileExt = ext;
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          final storagePath =
              '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

          await _client.storage.from(_storageBucket).uploadBinary(
                storagePath,
                bytes,
                fileOptions: FileOptions(
                  contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
                  upsert: true,
                ),
              );

          final signedUrlResponse = await _client.storage
              .from(_storageBucket)
              .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
          photoUrl = signedUrlResponse;
          debugPrint('[ActivitySync] Uploaded photo to Supabase Storage, signedUrl=$photoUrl');
        }
      } catch (e) {
        debugPrint('[ActivitySync] Error uploading photo to Storage: $e');
      }
    }

    // 2. Insert into Supabase `activities` table
    if (user != null) {
      try {
        final insertData = <String, dynamic>{
          'user_id': user.id,
          'activity_ids': activity.activityIds,
          'text': activity.text,
          if (photoUrl != null) 'photo_url': photoUrl,
          'created_at': activity.createdAt.toIso8601String(),
        };

        final response = await _client
            .from('activities')
            .insert(insertData)
            .select('id')
            .single();

        cloudId = response['id']?.toString();
        debugPrint('[ActivitySync] Inserted row into Supabase activities, cloudId=$cloudId');
      } catch (e) {
        debugPrint('[ActivitySync] Error inserting into Supabase: $e');
      }
    }

    // 3. Insert into local Drift database
    await _db.into(_db.activities).insert(
          ActivitiesCompanion.insert(
            createdAt: activity.createdAt,
            activityIdsJson: jsonEncode(activity.activityIds),
            activityText: activity.text,
            photoPath: Value(activity.photoPath),
            photoUrl: Value(photoUrl),
            userId: Value(user?.id),
            supabaseId: Value(cloudId),
          ),
        );
  }

  /// Deletes an activity by local ID (and supabaseId / photo if present).
  Future<void> delete(int localId, {String? supabaseId, String? photoUrl, String? photoPath}) async {
    final user = _client.auth.currentUser;

    // 1. Delete from local Drift DB
    await (_db.delete(_db.activities)..where((t) => t.id.equals(localId))).go();

    // 2. Delete attached local photo file best-effort (non-web)
    if (photoPath != null && !kIsWeb) {
      try {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[ActivitySync] Error deleting local photo file: $e');
      }
    }

    // 3. Delete from Supabase `activities` table
    if (user != null && supabaseId != null) {
      try {
        await _client.from('activities').delete().eq('id', supabaseId);
        debugPrint('[ActivitySync] Deleted row from Supabase, cloudId=$supabaseId');
      } catch (e) {
        debugPrint('[ActivitySync] Error deleting row from Supabase: $e');
      }
    }

    // 4. Delete photo from Supabase Storage best-effort
    if (user != null && photoUrl != null) {
      try {
        final uri = Uri.parse(photoUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf(_storageBucket);
        if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
          final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
          await _client.storage.from(_storageBucket).remove([storagePath]);
          debugPrint('[ActivitySync] Removed photo from Storage: $storagePath');
        }
      } catch (e) {
        debugPrint('[ActivitySync] Error deleting photo from Storage: $e');
      }
    }
  }

  /// Deletes all local activity records from Drift DB (e.g. upon user logout).
  Future<void> deleteAll() async {
    await _db.delete(_db.activities).go();
  }

  /// One-time migration: reads legacy SharedPreferences 'activities_v1' data,
  /// inserts into new Drift table, then deletes 'activities_v1' key.
  Future<void> migrateLegacySharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_legacyKey);
      if (raw == null || raw.isEmpty) return;

      final user = _client.auth.currentUser;
      debugPrint('[ActivityMigration] Migrating ${raw.length} legacy entries from SharedPreferences...');

      for (final s in raw) {
        try {
          final json = jsonDecode(s) as Map<String, dynamic>;
          final legacyActivity = Activity.fromJson(json);

          await _db.into(_db.activities).insert(
                ActivitiesCompanion.insert(
                  createdAt: legacyActivity.createdAt,
                  activityIdsJson: jsonEncode(legacyActivity.activityIds),
                  activityText: legacyActivity.text,
                  photoPath: Value(legacyActivity.photoPath),
                  photoUrl: Value(legacyActivity.photoUrl),
                  userId: Value(user?.id),
                  supabaseId: Value(legacyActivity.supabaseId),
                ),
              );
        } catch (e) {
          debugPrint('[ActivityMigration] Error parsing legacy item: $e');
        }
      }

      await prefs.remove(_legacyKey);
      debugPrint('[ActivityMigration] Legacy SharedPreferences migration completed.');
    } catch (e) {
      debugPrint('[ActivityMigration] Error in legacy migration: $e');
    }
  }

  /// Fetches user's activities from Supabase and syncs missing/deleted ones to local Drift DB.
  Future<void> fetchAndSyncFromSupabase() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final response = await _client
          .from('activities')
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

      final localEntries = await (_db.select(_db.activities)
            ..where((t) => t.userId.equals(user.id)))
          .get();

      final localSupabaseIdMap = <String, ActivityRow>{};
      for (final entry in localEntries) {
        if (entry.supabaseId != null) {
          localSupabaseIdMap[entry.supabaseId!] = entry;
        }
      }

      // Delete local entries that were deleted in cloud
      for (final localSupabaseId in localSupabaseIdMap.keys) {
        if (!cloudMap.containsKey(localSupabaseId)) {
          await (_db.delete(_db.activities)
                ..where((t) => t.supabaseId.equals(localSupabaseId)))
              .go();
          debugPrint('[ActivitySync] Deleted local activity with supabaseId=$localSupabaseId (deleted from cloud)');
        }
      }

      // Auto-heal legacy public photo_url records to signed URLs
      for (final cloudId in cloudMap.keys) {
        final row = cloudMap[cloudId]!;
        var photoUrl = row['photo_url'] as String?;

        if (photoUrl != null && photoUrl.contains('/object/public/$_storageBucket/')) {
          final storagePath = photoUrl.split('/object/public/$_storageBucket/').last;
          try {
            final signedUrl = await _client.storage
                .from(_storageBucket)
                .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
            photoUrl = signedUrl;
            row['photo_url'] = photoUrl;

            await _client.from('activities').update({'photo_url': photoUrl}).eq('id', cloudId);
            debugPrint('[ActivitySync] Auto-healed broken public photoUrl for cloudId=$cloudId to signed URL.');
          } catch (e) {
            debugPrint('[ActivitySync] Error healing photoUrl for cloudId=$cloudId: $e');
          }
        }
      }

      // Insert cloud entries that are missing locally, or update photoUrl if updated
      for (final cloudId in cloudMap.keys) {
        final row = cloudMap[cloudId]!;
        final photoUrl = row['photo_url'] as String?;

        if (!localSupabaseIdMap.containsKey(cloudId)) {
          final createdAtStr = row['created_at'] as String?;
          final rawActivityIds = row['activity_ids'];
          final text = row['text'] as String? ?? '';

          List<String> activityIds = const [];
          if (rawActivityIds is List) {
            activityIds = rawActivityIds.map((e) => e.toString()).toList();
          }

          final createdAt = createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now();

          await _db.into(_db.activities).insert(
                ActivitiesCompanion.insert(
                  createdAt: createdAt,
                  activityIdsJson: jsonEncode(activityIds),
                  activityText: text,
                  photoUrl: Value(photoUrl),
                  userId: Value(user.id),
                  supabaseId: Value(cloudId),
                ),
              );
          debugPrint('[ActivitySync] Inserted cloud activity entry locally, cloudId=$cloudId');
        } else {
          final localRow = localSupabaseIdMap[cloudId]!;
          if (localRow.photoUrl != photoUrl) {
            await (_db.update(_db.activities)..where((t) => t.id.equals(localRow.id)))
                .write(ActivitiesCompanion(photoUrl: Value(photoUrl)));
          }
        }
      }
    } catch (e) {
      debugPrint('[ActivitySync] Error fetching from Supabase: $e');
    }
  }
}
