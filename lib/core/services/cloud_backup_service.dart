import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

/// Backs up (and restores) all of the user's on-device data — the Drift
/// database tables plus the whitelisted SharedPreferences keys — as a single
/// JSON snapshot stored per-user in the Supabase `user_backups` table.
///
/// This is what makes data survive a wiped emulator, a reinstall, or moving
/// to a new phone: on a fresh device the snapshot is pulled back down and
/// written into the same local stores the app already reads from.
class CloudBackupService {
  CloudBackupService({required AppDatabase database, SupabaseClient? client})
      : _db = database,
        _client = client ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  static const _table = 'user_backups';

  /// Set once a device has either restored from or backed up to the cloud, so
  /// we don't clobber active local edits with an auto-restore on every launch.
  static const _syncedMarkerKey = 'cloud_synced_marker_v1';

  /// The last account that was active on this device, so we can tell an
  /// account switch (which must wipe + reload local data) from a normal
  /// re-login of the same account.
  static const _lastUserKey = 'cloud_last_user_id';

  /// The SharedPreferences keys that hold real user data worth syncing.
  /// Deliberately excludes device-only/security keys (app-lock PIN, ambient
  /// sound toggle) which should stay on the device.
  static const _prefsKeys = <String>[
    'activities_v1',
    'rewards_seen_badges_v1',
    'rewards_seen_level_v1',
    'favorite_quote_ids',
    'hobbies_v1',
    'hobbies_onboarded_v1',
    'letters_v1',
    'mood_log_v1',
    'period_days_v1',
    'period_symptoms_v1',
    'goals_streak_count',
    'goals_streak_last_active_date',
    'journal_streak_count',
    'journal_streak_last_entry_date',
    'onboarding_completed',
    'goals_seeded',
    'reminders_seeded',
  ];

  String? get _userId => _client.auth.currentUser?.id;

  // ---- Export -------------------------------------------------------------

  Future<Map<String, dynamic>> _exportSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsMap = <String, dynamic>{};
    for (final key in _prefsKeys) {
      final value = prefs.get(key);
      if (value == null) continue;
      if (value is List) {
        prefsMap[key] = {'t': 'sl', 'v': value};
      } else if (value is bool) {
        prefsMap[key] = {'t': 'b', 'v': value};
      } else if (value is int) {
        prefsMap[key] = {'t': 'i', 'v': value};
      } else if (value is double) {
        prefsMap[key] = {'t': 'd', 'v': value};
      } else {
        prefsMap[key] = {'t': 's', 'v': value.toString()};
      }
    }

    final dbMap = <String, dynamic>{};
    for (final table in await _tableNames()) {
      final rows = await _db.customSelect('SELECT * FROM "$table"').get();
      dbMap[table] = rows.map((r) => r.data).toList();
    }

    return {'version': 1, 'prefs': prefsMap, 'db': dbMap};
  }

  Future<List<String>> _tableNames() async {
    final rows = await _db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'drift_%'",
        )
        .get();
    return rows.map((r) => r.data['name'] as String).toList();
  }

  // ---- Backup / restore ---------------------------------------------------

  /// Uploads a fresh snapshot of all local data to the cloud.
  Future<void> backup() async {
    final uid = _userId;
    if (uid == null) return;
    final snapshot = await _exportSnapshot();
    await _client.from(_table).upsert({
      'user_id': uid,
      'data': snapshot,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncedMarkerKey, DateTime.now().toIso8601String());
  }

  /// Whether the current user has a cloud backup available.
  Future<bool> hasCloudBackup() async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      final row = await _client
          .from(_table)
          .select('user_id')
          .eq('user_id', uid)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  /// Pulls the cloud snapshot and writes it into the local stores, replacing
  /// current local data. Returns true if a snapshot was found and applied.
  Future<bool> restore() async {
    final uid = _userId;
    if (uid == null) return false;
    final row = await _client
        .from(_table)
        .select('data')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return false;
    final data = row['data'];
    if (data is! Map) return false;

    // Restore SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final prefsMap = data['prefs'];
    if (prefsMap is Map) {
      for (final entry in prefsMap.entries) {
        final meta = entry.value;
        if (meta is! Map) continue;
        final key = entry.key.toString();
        final t = meta['t'];
        final v = meta['v'];
        switch (t) {
          case 'sl':
            if (v is List) {
              await prefs.setStringList(
                  key, v.map((e) => e.toString()).toList());
            }
            break;
          case 'b':
            if (v is bool) await prefs.setBool(key, v);
            break;
          case 'i':
            if (v is num) await prefs.setInt(key, v.toInt());
            break;
          case 'd':
            if (v is num) await prefs.setDouble(key, v.toDouble());
            break;
          default:
            if (v != null) await prefs.setString(key, v.toString());
        }
      }
    }

    // Restore Drift tables: clear each, then re-insert its rows.
    final dbMap = data['db'];
    if (dbMap is Map) {
      final existing = (await _tableNames()).toSet();
      for (final entry in dbMap.entries) {
        final table = entry.key.toString();
        if (!existing.contains(table)) continue;
        final rows = entry.value;
        if (rows is! List) continue;
        await _db.customStatement('DELETE FROM "$table"');
        for (final raw in rows) {
          if (raw is! Map) continue;
          final cols = <String>[];
          final vars = <Variable<Object>>[];
          raw.forEach((col, value) {
            if (value == null) return; // let omitted columns be NULL/default
            cols.add('"$col"');
            vars.add(Variable<Object>(value as Object));
          });
          if (cols.isEmpty) continue;
          final placeholders = List.filled(cols.length, '?').join(', ');
          await _db.customInsert(
            'INSERT INTO "$table" (${cols.join(', ')}) VALUES ($placeholders)',
            variables: vars,
          );
        }
      }
    }

    await prefs.setString(_syncedMarkerKey, DateTime.now().toIso8601String());
    return true;
  }

  /// On a fresh device (no local sync marker yet), pull down the cloud backup
  /// if one exists. If none exists, seed the cloud with the current local
  /// data so it's protected from here on. Safe to call on every startup.
  Future<void> syncOnStartup() async {
    final uid = _userId;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_syncedMarkerKey) != null) return; // already synced
    try {
      final restored = await restore();
      if (!restored) {
        // Nothing in the cloud yet — back up whatever is on this device.
        await backup();
      }
    } catch (_) {
      // Never let a sync problem block app startup.
    }
  }

  /// Wipes every local store (Drift tables + the whitelisted prefs) so no
  /// data leaks between accounts sharing the same device.
  Future<void> _clearLocalData() async {
    for (final table in await _tableNames()) {
      await _db.customStatement('DELETE FROM "$table"');
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in _prefsKeys) {
      await prefs.remove(key);
    }
  }

  /// Call right after a successful sign-in. If a *different* account than the
  /// last one signed in on this device, the device's local data is wiped and
  /// this account's cloud backup is pulled down — so each account only ever
  /// sees its own data on a shared device. A normal re-login of the same
  /// account keeps the local data untouched.
  Future<void> onSignIn() async {
    final uid = _userId;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_lastUserKey);

    // Same account re-logging in — never touch local data.
    if (last == uid) return;

    // First sign-in we've ever tracked on this device: assume the local data
    // belongs to this account (or is empty). Don't wipe anything — just
    // remember who's here, so a *future* switch can be detected safely.
    if (last == null) {
      await prefs.setString(_lastUserKey, uid);
      return;
    }

    // A genuine switch from a different account: wipe local data and pull
    // this account's own cloud backup so the two accounts stay isolated.
    try {
      await _clearLocalData();
      await restore();
    } catch (_) {
      // A sync hiccup must not block sign-in.
    }
    await prefs.setString(_lastUserKey, uid);
    await prefs.setString(_syncedMarkerKey, DateTime.now().toIso8601String());
  }
}
