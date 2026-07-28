import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/features/journal/data/journal_entries_repository.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('journal_entries_test');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('save() actually writes a row to the database', () async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final repo = JournalEntriesRepository(database: db);

    final before = await db.select(db.journalEntries).get();
    expect(before, isEmpty);

    await repo.save('Today was a good day.');

    final after = await db.select(db.journalEntries).get();
    expect(after, hasLength(1));
    expect(after.single.content, 'Today was a good day.');

    await db.close();
  });

  test('save() persists an attached voice note path alongside the text', () async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final repo = JournalEntriesRepository(database: db);

    await repo.save('Recorded a thought on the walk.', audioPath: '/tmp/voice_notes/entry_1.m4a');

    final rows = await db.select(db.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.audioPath, '/tmp/voice_notes/entry_1.m4a');

    await db.close();
  });

  test('save() without a voice note leaves audioPath null', () async {
    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    final repo = JournalEntriesRepository(database: db);

    await repo.save('Text-only entry.');

    final rows = await db.select(db.journalEntries).get();
    expect(rows.single.audioPath, isNull);

    await db.close();
  });

  test('entry survives closing and reopening the database (simulated app restart)', () async {
    final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
    final repo1 = JournalEntriesRepository(database: db1);
    await repo1.save('Persisted across restart.');
    await db1.close();

    // A brand new AppDatabase instance pointed at the same on-disk file —
    // exactly what happens on a real app cold start.
    final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));
    final rows = await db2.select(db2.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.single.content, 'Persisted across restart.');
    await db2.close();
  });
}
