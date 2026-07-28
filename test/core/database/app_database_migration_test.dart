import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test(
      'onUpgrade tolerates a stuck user_version whose DDL was already '
      'partially applied (regression: real installs were found stuck with '
      'user_version=1 while dreams already had the v4 columns, crashing '
      'every launch on "duplicate column name: feeling_tag" before the '
      'journal_entries table could ever be created)', () async {
    final tempDir = Directory.systemTemp.createTempSync('app_db_migration_test');
    final dbFile = File('${tempDir.path}/broken.sqlite');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Recreate the exact corrupted state pulled from a real on-disk database:
    // tables/columns already reflect the v4 schema, but user_version was
    // never advanced past 1 (as if a prior onUpgrade threw partway through
    // and left the DDL committed without the version bump).
    final raw = sqlite3.sqlite3.open(dbFile.path);
    raw.execute('''
      CREATE TABLE reminders (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, icon_key TEXT NOT NULL, frequency TEXT NOT NULL, weekday INTEGER NULL, hour INTEGER NOT NULL, minute INTEGER NOT NULL, enabled INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0, 1)));
      CREATE TABLE goals (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, icon_key TEXT NOT NULL, unit TEXT NOT NULL, custom_unit_label TEXT NULL, target INTEGER NOT NULL, progress INTEGER NOT NULL DEFAULT 0, frequency TEXT NOT NULL, period_start INTEGER NOT NULL);
      CREATE TABLE dreams (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, date INTEGER NOT NULL, content TEXT NOT NULL, symbol_tags TEXT NOT NULL DEFAULT '', feeling_tag TEXT NULL, familiar_person TEXT NULL, first_thought TEXT NULL, life_connection TEXT NULL);
      PRAGMA user_version = 1;
    ''');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));

    // Before the fix, merely using the database forces beforeOpen ->
    // onUpgrade to re-run the from<4 block and throw
    // SqliteException("duplicate column name: feeling_tag") here.
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(createdAt: DateTime.now(), content: 'test'),
        );

    final rows = await db.select(db.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.content, 'test');

    await db.close();
  });
}
