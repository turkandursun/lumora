import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/user_content_sync.dart';
import 'special_day.dart';

const _specialDaysTable = 'special_days';
const _legacySpecialDaysKey = 'special_days_v1';

class SpecialDaysRepository {
  SpecialDaysRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
    @visibleForTesting UserContentRemoteDataSource? remoteDataSource,
    @visibleForTesting String Function()? uuidGenerator,
    @visibleForTesting Future<SharedPreferences> Function()? preferencesLoader,
  })  : _db = database,
        _remote = remoteDataSource ??
            SupabaseUserContentRemoteDataSource(
              supabaseClient ?? Supabase.instance.client,
            ),
        _uuidGenerator = uuidGenerator ?? newUserContentUuid,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  final AppDatabase _db;
  final UserContentRemoteDataSource _remote;
  final String Function() _uuidGenerator;
  final Future<SharedPreferences> Function() _preferencesLoader;
  final Map<String, Future<void>> _syncInFlight = {};
  final Set<String> _syncRequestedAgain = {};

  String? get currentUserId => _remote.currentUserId;

  /// Ownerless v1 rows are discarded. Only an explicitly matching userId in
  /// a payload can be migrated, so a previous account's dates are never
  /// assigned to the next account that signs in on the device.
  Future<void> discardOrMigrateLegacyPreferences() async {
    try {
      final prefs = await _preferencesLoader();
      final raw = prefs.getStringList(_legacySpecialDaysKey);
      final userId = _remote.currentUserId;
      if (raw != null && userId != null) {
        for (final item in raw) {
          try {
            final json = Map<String, dynamic>.from(jsonDecode(item) as Map);
            if (json['userId']?.toString() != userId) continue;
            final title = _normalizeTitle(json['title']?.toString() ?? '');
            final month = (json['month'] as num?)?.toInt();
            final day = (json['day'] as num?)?.toInt();
            final year = (json['year'] as num?)?.toInt() ?? 2000;
            if (title == null || month == null || day == null) continue;
            final eventDate = DateTime(year, month, day);
            if (eventDate.month != month || eventDate.day != day) continue;
            await _insertLocal(
              userId: userId,
              uuid: json['id']?.toString().isNotEmpty == true
                  ? json['id'].toString()
                  : _uuidGenerator(),
              title: title,
              dayType: _normalizeKind(json['kind']?.toString()),
              eventDate: eventDate,
              repeatsAnnually: true,
              syncState: contentSyncPendingUpsert,
              mode: InsertMode.insertOrIgnore,
            );
          } catch (_) {
            // Corrupt or ownerless legacy rows are never reassigned.
          }
        }
      }
      await prefs.remove(_legacySpecialDaysKey);
    } catch (_) {
      // Legacy cleanup must not block current local persistence.
    }
  }

  Future<List<SpecialDay>> load() async {
    await discardOrMigrateLegacyPreferences();
    final userId = _remote.currentUserId;
    if (userId == null) return const [];
    final rows = await (_db.select(_db.specialDays)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncPendingDelete).not())
          ..orderBy([(table) => OrderingTerm.asc(table.eventDate)]))
        .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<SpecialDay> create({
    required String title,
    required String dayType,
    required DateTime eventDate,
    required bool repeatsAnnually,
  }) async {
    final userId = _requireCurrentUser();
    final kind = _normalizeKind(dayType);
    if (kind == SpecialDay.kindBirthday) {
      throw StateError('Use setBirthday to create or update a birthday.');
    }
    final uuid = _uuidGenerator();
    await _insertLocal(
      userId: userId,
      uuid: uuid,
      title: _requireTitle(title),
      dayType: kind,
      eventDate: _dateOnly(eventDate),
      repeatsAnnually: repeatsAnnually,
      syncState: contentSyncPendingUpsert,
    );
    unawaited(syncForCurrentUser());
    return (await load()).firstWhere((day) => day.id == uuid);
  }

  Future<SpecialDay> setBirthday({
    required DateTime eventDate,
    required String title,
  }) async {
    final userId = _requireCurrentUser();
    final rows = await (_db.select(_db.specialDays)
          ..where((table) =>
              table.userId.equals(userId) &
              table.dayType.equals(SpecialDay.kindBirthday)))
        .get();
    final active = rows.where((row) => !isContentTombstone(row.syncState));
    final existing = active.isNotEmpty
        ? active.first
        : (rows.isNotEmpty ? rows.first : null);
    if (existing == null) {
      final uuid = _uuidGenerator();
      await _insertLocal(
        userId: userId,
        uuid: uuid,
        title: _requireTitle(title),
        dayType: SpecialDay.kindBirthday,
        eventDate: _dateOnly(eventDate),
        repeatsAnnually: true,
        syncState: contentSyncPendingUpsert,
      );
      unawaited(syncForCurrentUser());
      return (await load()).firstWhere((day) => day.id == uuid);
    }
    await _writePendingUpdate(
      existing,
      title: _requireTitle(title),
      dayType: SpecialDay.kindBirthday,
      eventDate: _dateOnly(eventDate),
      repeatsAnnually: true,
    );
    unawaited(syncForCurrentUser());
    return (await load()).firstWhere(
      (day) => day.id == existing.specialDayUuid,
    );
  }

  Future<void> update(SpecialDay day) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.specialDays)
          ..where((table) =>
              table.userId.equals(userId) &
              table.specialDayUuid.equals(day.id)))
        .getSingleOrNull();
    if (row == null || isContentTombstone(row.syncState)) return;
    await _writePendingUpdate(
      row,
      title: _requireTitle(day.title),
      dayType: _normalizeKind(day.kind),
      eventDate: _dateOnly(day.eventDate),
      repeatsAnnually: day.repeatsAnnually,
    );
    unawaited(syncForCurrentUser());
  }

  Future<void> delete(String uuid) async {
    final userId = _requireCurrentUser();
    final row = await (_db.select(_db.specialDays)
          ..where((table) =>
              table.userId.equals(userId) & table.specialDayUuid.equals(uuid)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.specialDays)
          ..where(
              (table) => table.id.equals(row.id) & table.userId.equals(userId)))
        .write(SpecialDaysCompanion(
      syncState: const Value(contentSyncPendingDelete),
      changedAt: Value(nextContentChangedAt(row.changedAt)),
    ));
    unawaited(syncForCurrentUser());
  }

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
      await _pushPending(userId);
      if (_remote.currentUserId != userId) return;
      try {
        final cloud = await _remote.fetchRows(
          _specialDaysTable,
          userId: userId,
          orderBy: 'event_date',
        );
        if (_remote.currentUserId != userId) return;
        await _pull(userId, cloud);
      } catch (error) {
        debugPrint(
          '[SpecialDaySync] pull deferred error=${error.runtimeType}',
        );
      }
    } while (
        _remote.currentUserId == userId && _syncRequestedAgain.remove(userId));
  }

  Future<void> _pushPending(String userId) async {
    final rows = await (_db.select(_db.specialDays)
          ..where((table) =>
              table.userId.equals(userId) &
              table.syncState.equals(contentSyncSynced).not()))
        .get();
    rows.sort((a, b) {
      final aDelete = isContentTombstone(a.syncState);
      final bDelete = isContentTombstone(b.syncState);
      return aDelete == bDelete ? 0 : (aDelete ? -1 : 1);
    });
    for (final row in rows) {
      if (_remote.currentUserId != userId) return;
      final pushedAt = row.changedAt;
      try {
        if (isContentTombstone(row.syncState)) {
          await _remote.deleteRow(
            _specialDaysTable,
            userId: userId,
            rowId: row.specialDayUuid,
          );
          if (_remote.currentUserId != userId) return;
          await (_db.delete(_db.specialDays)
                ..where((table) =>
                    table.id.equals(row.id) &
                    table.userId.equals(userId) &
                    table.syncState.equals(contentSyncPendingDelete) &
                    table.changedAt.equals(pushedAt)))
              .go();
          continue;
        }

        final response = await _remote.upsertRow(_specialDaysTable, {
          'id': row.specialDayUuid,
          'user_id': userId,
          'title': row.title,
          'day_type': row.dayType,
          'event_date': formatSpecialDayDate(row.eventDate),
          'repeats_annually': row.repeatsAnnually,
        });
        if (_remote.currentUserId != userId) return;
        final syncedAt = DateTime.now().toUtc();
        await (_db.update(_db.specialDays)
              ..where((table) =>
                  table.id.equals(row.id) &
                  table.userId.equals(userId) &
                  table.syncState.equals(contentSyncPendingUpsert) &
                  table.changedAt.equals(pushedAt)))
            .write(SpecialDaysCompanion(
          syncState: const Value(contentSyncSynced),
          cloudUpdatedAt: Value(
            _parseTimestamp(response['updated_at']) ?? syncedAt,
          ),
          lastSyncedAt: Value(syncedAt),
        ));
      } catch (error) {
        debugPrint(
          '[SpecialDaySync] push deferred error=${error.runtimeType}',
        );
      }
    }
  }

  Future<void> _pull(
    String userId,
    List<Map<String, dynamic>> cloudRows,
  ) async {
    final cloudMap = <String, Map<String, dynamic>>{
      for (final row in cloudRows)
        if (row['id']?.toString().isNotEmpty == true) row['id'].toString(): row,
    };
    final locals = await (_db.select(_db.specialDays)
          ..where((table) => table.userId.equals(userId)))
        .get();
    final localByUuid = <String, SpecialDayRow>{
      for (final row in locals) row.specialDayUuid: row,
    };

    for (final entry in cloudMap.entries) {
      if (_remote.currentUserId != userId) return;
      final local = localByUuid[entry.key];
      if (local != null && local.syncState != contentSyncSynced) continue;
      final cloud = entry.value;
      final date = parseSpecialDayDate(cloud['event_date']);
      final title = _normalizeTitle(cloud['title']?.toString() ?? '');
      if (date == null || title == null) continue;
      final updatedAt = _parseTimestamp(cloud['updated_at']) ?? DateTime.now();
      final values = SpecialDaysCompanion(
        title: Value(title),
        dayType: Value(_normalizeKind(cloud['day_type']?.toString())),
        eventDate: Value(date),
        repeatsAnnually: Value(cloud['repeats_annually'] != false),
        syncState: const Value(contentSyncSynced),
        changedAt: Value(updatedAt),
        cloudUpdatedAt: Value(updatedAt),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      );
      if (local == null) {
        await _insertLocal(
          userId: userId,
          uuid: entry.key,
          title: title,
          dayType: _normalizeKind(cloud['day_type']?.toString()),
          eventDate: date,
          repeatsAnnually: cloud['repeats_annually'] != false,
          syncState: contentSyncSynced,
          changedAt: updatedAt,
          cloudUpdatedAt: updatedAt,
          lastSyncedAt: DateTime.now().toUtc(),
          mode: InsertMode.insertOrIgnore,
        );
      } else {
        await (_db.update(_db.specialDays)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .write(values);
      }
    }

    for (final local in locals) {
      if (local.syncState != contentSyncSynced) continue;
      if (!cloudMap.containsKey(local.specialDayUuid)) {
        await (_db.delete(_db.specialDays)
              ..where((table) =>
                  table.id.equals(local.id) & table.userId.equals(userId)))
            .go();
      }
    }
  }

  Future<void> _insertLocal({
    required String userId,
    required String uuid,
    required String title,
    required String dayType,
    required DateTime eventDate,
    required bool repeatsAnnually,
    required String syncState,
    DateTime? changedAt,
    DateTime? cloudUpdatedAt,
    DateTime? lastSyncedAt,
    InsertMode mode = InsertMode.insert,
  }) async {
    await _db.into(_db.specialDays).insert(
          SpecialDaysCompanion.insert(
            specialDayUuid: uuid,
            userId: userId,
            title: title,
            dayType: dayType,
            eventDate: eventDate,
            repeatsAnnually: Value(repeatsAnnually),
            syncState: Value(syncState),
            changedAt: Value(changedAt ?? DateTime.now()),
            cloudUpdatedAt: Value(cloudUpdatedAt),
            lastSyncedAt: Value(lastSyncedAt),
          ),
          mode: mode,
        );
  }

  Future<void> _writePendingUpdate(
    SpecialDayRow row, {
    required String title,
    required String dayType,
    required DateTime eventDate,
    required bool repeatsAnnually,
  }) async {
    await (_db.update(_db.specialDays)
          ..where((table) => table.id.equals(row.id)))
        .write(SpecialDaysCompanion(
      title: Value(title),
      dayType: Value(dayType),
      eventDate: Value(eventDate),
      repeatsAnnually: Value(repeatsAnnually),
      syncState: const Value(contentSyncPendingUpsert),
      changedAt: Value(nextContentChangedAt(row.changedAt)),
    ));
  }

  String _requireCurrentUser() {
    final userId = _remote.currentUserId;
    if (userId == null) throw StateError('An authenticated user is required.');
    return userId;
  }
}

SpecialDay _fromRow(SpecialDayRow row) => SpecialDay(
      id: row.specialDayUuid,
      title: row.title,
      month: row.eventDate.month,
      day: row.eventDate.day,
      year: row.eventDate.year,
      kind: row.dayType,
      repeatsAnnually: row.repeatsAnnually,
    );

String formatSpecialDayDate(DateTime value) {
  final local = DateTime(value.year, value.month, value.day);
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime? parseSpecialDayDate(Object? value) {
  final raw = value?.toString();
  if (raw == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    return null;
  }
  final parts = raw.split('-').map(int.parse).toList(growable: false);
  final date = DateTime(parts[0], parts[1], parts[2]);
  return formatSpecialDayDate(date) == raw ? date : null;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String? _normalizeTitle(String value) {
  final title = value.trim();
  if (title.isEmpty || title.length > 80) return null;
  return title;
}

String _requireTitle(String value) {
  final title = _normalizeTitle(value);
  if (title == null) {
    throw ArgumentError.value(value, 'title', 'Must contain 1-80 characters.');
  }
  return title;
}

String _normalizeKind(String? value) =>
    SpecialDay.supportedKinds.contains(value) ? value! : SpecialDay.kindCustom;

DateTime? _parseTimestamp(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
