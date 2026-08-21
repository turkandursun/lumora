import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/activities_table.dart';
import 'tables/daily_questions_table.dart';
import 'tables/dreams_table.dart';
import 'tables/focus_sessions_table.dart';
import 'tables/goals_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/letters_table.dart';
import 'tables/quote_favorites_table.dart';
import 'tables/quotes_table.dart';
import 'tables/reminders_table.dart';
import 'tables/special_days_table.dart';

part 'app_database.g.dart';

/// The app's local offline-first database: [Reminders], [Goals], [Dreams],
/// [JournalEntries] (Home's writing area), [DailyQuestionAnswers], [Activities],
/// [Letters], the offline [Quotes] catalogue, and user-scoped
/// [QuoteFavorites] and account-scoped [SpecialDays].
///
/// The connection is platform-conditional under the hood: `drift_flutter`
/// picks a native sqlite3 connection on Android/iOS/desktop and a
/// WASM-based one (see `web/sqlite3.wasm` + `web/drift_worker.dart.js`) when
/// running on Flutter web, so the rest of the app never has to care which
/// one is active.
@DriftDatabase(tables: [
  Reminders,
  FocusSessions,
  Goals,
  Dreams,
  JournalEntries, // includes photoUrl column
  DailyQuestionAnswers,
  Activities,
  Letters,
  Quotes,
  QuoteFavorites,
  SpecialDays,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 27;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createUserContentCloudIdentityIndexes();
          await _createSpecialDaysIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Each step below checks the actual on-disk schema before applying,
          // rather than trusting `from`/`user_version` alone. That pragma is
          // only advanced after `onUpgrade` returns without error, so a
          // migration that previously threw partway through (as this one
          // did — see the `dreams.feeling_tag` incident) leaves already-
          // applied DDL in place but `from` still pointing at the old
          // version. Without these guards, every subsequent launch re-runs
          // the same already-applied `ALTER TABLE`/`CREATE TABLE` and
          // crashes with "duplicate column"/"table already exists" forever,
          // which is exactly what left this app unable to open its database
          // at all.
          if (from < 2 && !await _hasTable('goals')) {
            await m.createTable(goals);
          }
          if (from < 3 && !await _hasTable('dreams')) {
            await m.createTable(dreams);
          }
          if (from < 4) {
            if (!await _hasColumn('dreams', 'feeling_tag')) {
              await m.addColumn(dreams, dreams.feelingTag);
            }
            if (!await _hasColumn('dreams', 'familiar_person')) {
              await m.addColumn(dreams, dreams.familiarPerson);
            }
            if (!await _hasColumn('dreams', 'first_thought')) {
              await m.addColumn(dreams, dreams.firstThought);
            }
            if (!await _hasColumn('dreams', 'life_connection')) {
              await m.addColumn(dreams, dreams.lifeConnection);
            }
          }
          if (from < 5 && !await _hasTable('journal_entries')) {
            await m.createTable(journalEntries);
          }
          if (from < 6 && !await _hasColumn('dreams', 'ai_interpretation')) {
            await m.addColumn(dreams, dreams.aiInterpretation);
          }
          if (from < 7 && !await _hasTable('daily_question_answers')) {
            await m.createTable(dailyQuestionAnswers);
          }
          if (from < 8 && !await _hasColumn('journal_entries', 'audio_path')) {
            await m.addColumn(journalEntries, journalEntries.audioPath);
          }
          if (from < 9) {
            if (!await _hasColumn('journal_entries', 'user_id')) {
              await m.addColumn(journalEntries, journalEntries.userId);
            }
            if (!await _hasColumn('journal_entries', 'supabase_id')) {
              await m.addColumn(journalEntries, journalEntries.supabaseId);
            }
          }
          if (from < 10) {
            if (!await _hasColumn('goals', 'user_id')) {
              await m.addColumn(goals, goals.userId);
            }
            if (!await _hasColumn('goals', 'supabase_id')) {
              await m.addColumn(goals, goals.supabaseId);
            }
          }
          if (from < 11 && !await _hasColumn('journal_entries', 'title')) {
            await m.addColumn(journalEntries, journalEntries.title);
          }
          if (from < 12) {
            if (!await _hasColumn('dreams', 'user_id')) {
              await m.addColumn(dreams, dreams.userId);
            }
            if (!await _hasColumn('dreams', 'supabase_id')) {
              await m.addColumn(dreams, dreams.supabaseId);
            }
          }
          if (from < 14 && !await _hasTable('activities')) {
            await m.createTable(activities);
          }
          if (from < 15) {
            if (!await _hasColumn('reminders', 'user_id')) {
              await m.addColumn(reminders, reminders.userId);
            }
            if (!await _hasColumn('reminders', 'supabase_id')) {
              await m.addColumn(reminders, reminders.supabaseId);
            }
          }
          if (from < 16 && !await _hasTable('letters')) {
            await m.createTable(letters);
          }
          if (from < 17 && !await _hasColumn('journal_entries', 'photo_url')) {
            await m.addColumn(journalEntries, journalEntries.photoUrl);
          }
          if (from < 18 && !await _hasTable('quotes')) {
            await m.createTable(quotes);
          }
          if (from < 19 && !await _hasTable('quote_favorites')) {
            await m.createTable(quoteFavorites);
          }
          if (from < 20 && await _hasTable('reminders')) {
            if (!await _hasColumn('reminders', 'default_key')) {
              await m.addColumn(reminders, reminders.defaultKey);
            }
            await customStatement('''
              UPDATE reminders
              SET default_key = CASE icon_key
                WHEN 'sun' THEN 'morning_journal'
                WHEN 'breathing' THEN 'breathing_break'
                WHEN 'reflection' THEN 'weekly_reflection'
              END
              WHERE default_key IS NULL
                AND icon_key IN ('sun', 'breathing', 'reflection')
            ''');
          }
          if (from < 21 && await _hasTable('goals')) {
            if (!await _hasColumn('goals', 'template_key')) {
              await m.addColumn(goals, goals.templateKey);
            }
            if (!await _hasColumn('goals', 'status')) {
              await m.addColumn(goals, goals.status);
            }
            if (!await _hasColumn('goals', 'sync_state')) {
              await m.addColumn(goals, goals.syncState);
            }
            if (!await _hasColumn('goals', 'changed_at')) {
              // SQLite cannot add a NOT NULL column with a dynamic time
              // expression as its default. A constant makes ALTER TABLE safe;
              // the backfill below immediately replaces it with UTC "now".
              await customStatement('''
                ALTER TABLE goals
                ADD COLUMN changed_at INTEGER NOT NULL DEFAULT 0
              ''');
            }
            if (!await _hasColumn('goals', 'cloud_updated_at')) {
              await m.addColumn(goals, goals.cloudUpdatedAt);
            }
            if (!await _hasColumn('goals', 'last_synced_at')) {
              await m.addColumn(goals, goals.lastSyncedAt);
            }

            // Only stable starter icon keys are safe to identify locally.
            // Custom/preset rows are deliberately left for the later cloud
            // sync to resolve from Supabase's authoritative template_key.
            await customStatement('''
              UPDATE goals
              SET template_key = icon_key
              WHERE template_key IS NULL
                AND icon_key IN (
                  'water',
                  'journal',
                  'meditation',
                  'breathing',
                  'reading'
                )
            ''');

            // Existing rows remain active. Cloud-backed rows are already in
            // sync, user-owned local-only rows need a future push, and guest
            // rows stay unowned and non-pending so they cannot be uploaded to
            // whichever account happens to sign in next.
            await customStatement('''
              UPDATE goals
              SET status = 'active',
                  sync_state = CASE
                    WHEN supabase_id IS NOT NULL THEN 'synced'
                    WHEN user_id IS NOT NULL THEN 'pending'
                    ELSE 'synced'
                  END,
                  changed_at = CAST(strftime('%s', 'now') AS INTEGER),
                  cloud_updated_at = NULL,
                  last_synced_at = NULL
            ''');
          }
          if (from < 22 && await _hasTable('goals')) {
            // The partial unique index is intentionally installed by
            // GoalsRepository after its cloud-aware legacy reconciliation.
            // Creating it here would fail on the duplicate starter artifacts
            // this version is responsible for merging without data loss.
          }
          if (from < 23 && await _hasTable('journal_entries')) {
            // Cloud-backed duplicates are local cache artifacts. Keep the
            // newest local row for each exact user + Supabase UUID identity;
            // null IDs are deliberately untouched because similar text/date
            // values are not proof that two local journals are the same.
            await customStatement('''
              DELETE FROM journal_entries
              WHERE user_id IS NOT NULL
                AND supabase_id IS NOT NULL
                AND id NOT IN (
                  SELECT MAX(id)
                  FROM journal_entries
                  WHERE user_id IS NOT NULL
                    AND supabase_id IS NOT NULL
                  GROUP BY user_id, supabase_id
                )
            ''');
            await _createJournalEntriesCloudIdentityIndex();
          }
          if (from < 24 && !await _hasTable('focus_sessions')) {
            await m.createTable(focusSessions);
          }
          if (from < 25) {
            for (final table in const <String>[
              'journal_entries',
              'dreams',
              'activities',
              'letters',
            ]) {
              if (!await _hasTable(table)) continue;
              if (!await _hasColumn(table, 'sync_state')) {
                await customStatement('''
                  ALTER TABLE $table
                  ADD COLUMN sync_state TEXT NOT NULL DEFAULT 'synced'
                ''');
              }
              if (!await _hasColumn(table, 'changed_at')) {
                // SQLite cannot add a NOT NULL column with a dynamic default.
                await customStatement('''
                  ALTER TABLE $table
                  ADD COLUMN changed_at INTEGER NOT NULL DEFAULT 0
                ''');
              }
              await customStatement('''
                UPDATE $table
                SET sync_state = CASE
                      WHEN supabase_id IS NOT NULL THEN 'synced'
                      WHEN user_id IS NOT NULL THEN 'pending_upsert'
                      ELSE 'synced'
                    END,
                    changed_at = CASE
                      WHEN changed_at = 0
                        THEN CAST(strftime('%s', 'now') AS INTEGER)
                      ELSE changed_at
                    END
              ''');
            }
            await _reconcileUserContentCloudIdentityDuplicates();
            await _createUserContentCloudIdentityIndexes();
          }
          if (from < 26) {
            // The Dilemma & Community features were removed; drop the
            // daily-question columns that only mirrored a Supabase community
            // share so no trace of the feature remains in the schema.
            if (await _hasColumn(
                'daily_question_answers', 'is_shared_to_community')) {
              await customStatement('ALTER TABLE daily_question_answers '
                  'DROP COLUMN is_shared_to_community');
            }
            if (await _hasColumn(
                'daily_question_answers', 'community_share_id')) {
              await customStatement('ALTER TABLE daily_question_answers '
                  'DROP COLUMN community_share_id');
            }
          }
          if (from < 27 && !await _hasTable('special_days')) {
            await m.createTable(specialDays);
          }
          if (from < 27) {
            await _createSpecialDaysIndexes();
          }
        },
      );

  Future<void> _createSpecialDaysIndexes() async {
    if (!await _hasTable('special_days')) return;
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS special_days_user_uuid_unique
      ON special_days(user_id, special_day_uuid)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS special_days_one_active_birthday
      ON special_days(user_id)
      WHERE day_type = 'birthday'
        AND sync_state != 'pending_delete'
    ''');
  }

  Future<void> _createJournalEntriesCloudIdentityIndex() async {
    if (!await _hasTable('journal_entries')) return;
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS
        journal_entries_user_cloud_unique
      ON journal_entries(user_id, supabase_id)
      WHERE user_id IS NOT NULL
        AND supabase_id IS NOT NULL
    ''');
  }

  Future<void> _createUserContentCloudIdentityIndexes() async {
    await _createJournalEntriesCloudIdentityIndex();
    for (final table in const <String>['dreams', 'activities', 'letters']) {
      if (!await _hasTable(table)) continue;
      await customStatement('''
        CREATE UNIQUE INDEX IF NOT EXISTS
          ${table}_user_cloud_unique
        ON $table(user_id, supabase_id)
        WHERE user_id IS NOT NULL
          AND supabase_id IS NOT NULL
      ''');
    }
  }

  Future<void> _reconcileUserContentCloudIdentityDuplicates() async {
    for (final table in const <String>['dreams', 'activities', 'letters']) {
      if (!await _hasTable(table)) continue;
      await customStatement('''
        DELETE FROM $table
        WHERE user_id IS NOT NULL
          AND supabase_id IS NOT NULL
          AND id NOT IN (
            SELECT MAX(id)
            FROM $table
            WHERE user_id IS NOT NULL
              AND supabase_id IS NOT NULL
            GROUP BY user_id, supabase_id
          )
      ''');
    }
  }

  Future<bool> _hasTable(String name) async {
    final result = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(name)],
    ).getSingleOrNull();
    return result != null;
  }

  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((row) => row.data['name'] == column);
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'mindful_journal',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
