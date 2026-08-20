import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/user_content_sync.dart';

const _legacyKey = 'activities_v1';
const _storageBucket = 'activity-photos';
const _activitiesTable = 'activities';

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

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as int?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        activityIds: json['activityIds'] is List
            ? (json['activityIds'] as List)
                .map((value) => value.toString())
                .toList()
            : const [],
        text: json['text'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
        photoUrl: json['photoUrl'] as String?,
        userId: json['userId'] as String?,
        supabaseId: json['supabaseId'] as String?,
        sharedId: json['sharedId'] as String?,
      );

  factory Activity.fromRow(ActivityRow row) {
    List<String> ids = const [];
    try {
      final decoded = jsonDecode(row.activityIdsJson);
      if (decoded is List) {
        ids = decoded.map((value) => value.toString()).toList();
      }
    } catch (_) {
      // A malformed legacy tag list must not hide the activity itself.
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

class ActivityRepository {
  ActivityRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting UserContentRemoteDataSource? remoteDataSource,
    @visibleForTesting String Function()? uuidGenerator,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client,
        _uuidGenerator = uuidGenerator ?? newUserContentUuid {
    _remote = remoteDataSource ?? SupabaseUserContentRemoteDataSource(_client);
  }

  final AppDatabase _db;
  final SupabaseClient _client;
  final String Function() _uuidGenerator;
  late final UserContentRemoteDataSource _remote;
  final Map<String, Future<void>> _syncInFlight = {};
  final Set<String> _syncRequestedAgain = {};

  Future<List<Activity>> load() async {
    await migrateLegacySharedPreferencesData();
    final userId = _remote.currentUserId;
    if (userId == null) return const [];
    final rows = await (_db.select(_db.activities)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncPendingDelete).not())
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
    return rows.map(Activity.fromRow).toList(growable: false);
  }

  Future<void> add(Activity activity) async {
    final userId = _requireCurrentUser();
    final now = DateTime.now();
    final cloudId = _uuidGenerator();
    final localId = await _db.into(_db.activities).insert(
          ActivitiesCompanion.insert(
            createdAt: activity.createdAt,
            activityIdsJson: jsonEncode(activity.activityIds),
            activityText: activity.text,
            photoPath: Value(activity.photoPath),
            photoUrl: Value(activity.photoUrl),
            userId: Value(userId),
            supabaseId: Value(cloudId),
            syncState: const Value(contentSyncPendingUpsert),
            changedAt: Value(now),
          ),
        );
    if (activity.photoBytes != null || activity.photoPath != null) {
      try {
        final url = await _uploadPhoto(
          userId: userId,
          cloudId: cloudId,
          bytes: activity.photoBytes,
          localPath: activity.photoPath,
        );
        if (_remote.currentUserId == userId && url != null) {
          await (_db.update(_db.activities)
                ..where((table) =>
                    table.id.equals(localId) & table.userId.equals(userId)))
              .write(ActivitiesCompanion(photoUrl: Value(url)));
        }
      } catch (error) {
        debugPrint(
          '[ActivitySync] photo upload deferred error=${error.runtimeType}',
        );
      }
    }
    unawaited(syncForCurrentUser());
  }

  Future<void> update(Activity activity) async {
    final userId = _requireCurrentUser();
    final localId = activity.id;
    if (localId == null) return;
    final row = await (_db.select(_db.activities)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null || isContentTombstone(row.syncState)) return;
    await (_db.update(_db.activities)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      ActivitiesCompanion(
        activityIdsJson: Value(jsonEncode(activity.activityIds)),
        activityText: Value(activity.text),
        photoPath: Value(activity.photoPath),
        photoUrl: Value(activity.photoUrl),
        supabaseId: Value(row.supabaseId ?? _uuidGenerator()),
        syncState: const Value(contentSyncPendingUpsert),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> delete(
    int localId, {
    String? supabaseId,
    String? photoUrl,
    String? photoPath,
  }) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.activities)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null) return;
    final cloudId = row.supabaseId ?? supabaseId;
    if (cloudId == null) {
      await _deleteLocalActivityFiles(row.photoPath ?? photoPath);
      await (_db.delete(_db.activities)
            ..where((table) =>
                table.id.equals(localId) & table.userId.equals(userId)))
          .go();
      return;
    }
    await (_db.update(_db.activities)
          ..where((table) =>
              table.id.equals(localId) & table.userId.equals(userId)))
        .write(
      ActivitiesCompanion(
        supabaseId: Value(cloudId),
        photoUrl: Value(row.photoUrl ?? photoUrl),
        photoPath: Value(row.photoPath ?? photoPath),
        syncState: const Value(contentSyncPendingDelete),
        changedAt: Value(nextContentChangedAt(row.changedAt)),
      ),
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> deleteAll() => _db.delete(_db.activities).go();

  Future<void> migrateLegacySharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_legacyKey);
      if (raw == null || raw.isEmpty) return;
      final userId = _remote.currentUserId;
      if (userId != null) {
        for (final item in raw) {
          try {
            final legacy = Activity.fromJson(
              Map<String, dynamic>.from(jsonDecode(item) as Map),
            );
            // Global v1 rows without an owner are never attributed to the
            // account that happens to sign in next.
            if (legacy.userId != userId) continue;
            final cloudId = legacy.supabaseId ?? _uuidGenerator();
            await _db.into(_db.activities).insert(
                  ActivitiesCompanion.insert(
                    createdAt: legacy.createdAt,
                    activityIdsJson: jsonEncode(legacy.activityIds),
                    activityText: legacy.text,
                    photoPath: Value(legacy.photoPath),
                    photoUrl: Value(legacy.photoUrl),
                    userId: Value(userId),
                    supabaseId: Value(cloudId),
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
            // Invalid legacy records are discarded with the unsafe global key.
          }
        }
      }
      await prefs.remove(_legacyKey);
    } catch (_) {
      // A preferences failure does not affect the durable Drift outbox.
    }
  }

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
        _activitiesTable,
        userId: userId,
        orderBy: 'created_at',
      );
      if (_remote.currentUserId != userId) return;
      await _pull(userId, cloud);
    } catch (error) {
      debugPrint('[ActivitySync] pull deferred error=${error.runtimeType}');
    }
  }

  Future<void> _pushPending(String userId) async {
    final rows = await (_db.select(_db.activities)
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
              _activitiesTable,
              userId: userId,
              rowId: row.supabaseId!,
            );
          }
          if (_remote.currentUserId != userId) return;
          await _removeRemotePhoto(row.photoUrl);
          await _deleteLocalActivityFiles(row.photoPath);
          await (_db.delete(_db.activities)
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
          await (_db.update(_db.activities)
                ..where((table) =>
                    table.id.equals(row.id) & table.userId.equals(userId)))
              .write(ActivitiesCompanion(supabaseId: Value(cloudId)));
          row = row.copyWith(supabaseId: Value(cloudId));
        }
        var photoUrl = row.photoUrl;
        if ((photoUrl == null || photoUrl.isEmpty) && row.photoPath != null) {
          photoUrl = await _uploadPhoto(
            userId: userId,
            cloudId: row.supabaseId!,
            localPath: row.photoPath,
          );
          if (photoUrl == null) throw StateError('Photo unavailable');
          await (_db.update(_db.activities)
                ..where((table) =>
                    table.id.equals(row.id) & table.userId.equals(userId)))
              .write(ActivitiesCompanion(photoUrl: Value(photoUrl)));
        }
        await _remote.upsertRow(_activitiesTable, {
          'id': row.supabaseId,
          'user_id': userId,
          'activity_ids': _decodeIds(row.activityIdsJson),
          'text': row.activityText,
          'photo_url': photoUrl,
          'created_at': row.createdAt.toUtc().toIso8601String(),
        });
        if (_remote.currentUserId != userId) return;
        await (_db.update(_db.activities)
              ..where((table) =>
                  table.id.equals(row.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(contentSyncPendingUpsert) &
                  table.changedAt.equals(pushedAt)))
            .write(
          const ActivitiesCompanion(syncState: Value(contentSyncSynced)),
        );
      } catch (error) {
        debugPrint('[ActivitySync] push deferred error=${error.runtimeType}');
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
    final locals = await (_db.select(_db.activities)
          ..where((table) => table.userId.equals(userId)))
        .get();
    final localByCloud = <String, ActivityRow>{
      for (final row in locals)
        if (row.supabaseId != null) row.supabaseId!: row,
    };
    for (final entry in cloudMap.entries) {
      if (_remote.currentUserId != userId) return;
      final local = localByCloud[entry.key];
      if (local != null && local.syncState != contentSyncSynced) continue;
      final row = entry.value;
      final createdAt = _parseDate(row['created_at']) ?? DateTime.now();
      final ids = row['activity_ids'] is List
          ? (row['activity_ids'] as List)
              .map((value) => value.toString())
              .toList()
          : const <String>[];
      if (local == null) {
        await _db.into(_db.activities).insert(
              ActivitiesCompanion.insert(
                createdAt: createdAt,
                activityIdsJson: jsonEncode(ids),
                activityText: row['text']?.toString() ?? '',
                photoUrl: Value(row['photo_url'] as String?),
                userId: Value(userId),
                supabaseId: Value(entry.key),
                syncState: const Value(contentSyncSynced),
                changedAt: Value(createdAt),
              ),
            );
      } else {
        await (_db.update(_db.activities)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .write(
          ActivitiesCompanion(
            createdAt: Value(createdAt),
            activityIdsJson: Value(jsonEncode(ids)),
            activityText: Value(row['text']?.toString() ?? ''),
            photoUrl: Value(row['photo_url'] as String?),
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
        await (_db.delete(_db.activities)
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
    await _client.storage.from(_storageBucket).uploadBinary(
          storagePath,
          uploadBytes,
          fileOptions: FileOptions(
            contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}',
            upsert: true,
          ),
        );
    return _client.storage
        .from(_storageBucket)
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
  }

  Future<void> _removeRemotePhoto(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final segments = Uri.parse(url).pathSegments;
      final bucket = segments.indexOf(_storageBucket);
      if (bucket >= 0 && bucket + 1 < segments.length) {
        await _client.storage
            .from(_storageBucket)
            .remove([segments.sublist(bucket + 1).join('/')]);
      }
    } catch (_) {
      // Row deletion remains authoritative; account deletion also sweeps media.
    }
  }

  Future<void> _deleteLocalActivityFiles(String? path) async {
    if (path == null || kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Local cache cleanup is best effort.
    }
  }

  String _requireCurrentUser() {
    final userId = _remote.currentUserId;
    if (userId == null) throw StateError('An authenticated user is required.');
    return userId;
  }
}

List<String> _decodeIds(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((value) => value.toString()).toList();
    }
  } catch (_) {}
  return const [];
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
