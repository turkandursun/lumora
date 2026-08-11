import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';

void main() {
  test('22 to 23 migration reconciles cloud duplicates before unique index',
      () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute('''
            CREATE TABLE journal_entries (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              content TEXT NOT NULL,
              title TEXT NULL,
              audio_path TEXT NULL,
              photo_url TEXT NULL,
              user_id TEXT NULL,
              supabase_id TEXT NULL
            )
          ''');
          rawDatabase.execute('''
            INSERT INTO journal_entries
              (created_at, content, user_id, supabase_id)
            VALUES
              (1, 'older cache', 'user-a', 'cloud-1'),
              (2, 'newer cache', 'user-a', 'cloud-1'),
              (3, 'other user', 'user-b', 'cloud-1'),
              (4, 'local one', 'user-a', NULL),
              (5, 'local two', 'user-a', NULL)
          ''');
          rawDatabase.execute('PRAGMA user_version = 22');
        },
      ),
    );
    addTearDown(database.close);

    final rows = await database.select(database.journalEntries).get();
    final userACloudRows = rows
        .where((row) => row.userId == 'user-a' && row.supabaseId == 'cloud-1')
        .toList();
    final localOnlyRows = rows
        .where((row) => row.userId == 'user-a' && row.supabaseId == null)
        .toList();

    expect(userACloudRows, hasLength(1));
    expect(userACloudRows.single.content, 'newer cache');
    expect(localOnlyRows, hasLength(2));
    expect(
      rows.where((row) => row.userId == 'user-b'),
      hasLength(1),
    );

    final index = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?",
      variables: [
        Variable.withString('journal_entries_user_cloud_unique'),
      ],
    ).getSingleOrNull();
    expect(index, isNotNull);

    await expectLater(
      database.into(database.journalEntries).insert(
            JournalEntriesCompanion.insert(
              createdAt: DateTime.utc(2026, 8, 11),
              content: 'must be rejected',
              userId: const Value('user-a'),
              supabaseId: const Value('cloud-1'),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
