import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/daily_questions_table.dart';
import 'tables/dreams_table.dart';
import 'tables/goals_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/reminders_table.dart';

part 'app_database.g.dart';

/// The app's local offline-first database: [Reminders], [Goals], [Dreams],
/// [JournalEntries] (Home's writing area), and [DailyQuestionAnswers].
///
/// The connection is platform-conditional under the hood: `drift_flutter`
/// picks a native sqlite3 connection on Android/iOS/desktop and a
/// WASM-based one (see `web/sqlite3.wasm` + `web/drift_worker.dart.js`) when
/// running on Flutter web, so the rest of the app never has to care which
/// one is active.
@DriftDatabase(tables: [Reminders, Goals, Dreams, JournalEntries, DailyQuestionAnswers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
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
        },
      );

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
