import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/sync/user_content_sync.dart';

void main() {
  test('24 to 25 preserves content and classifies legacy sync state', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
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
          raw.execute('''
            CREATE TABLE dreams (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              date INTEGER NOT NULL,
              content TEXT NOT NULL,
              symbol_tags TEXT NOT NULL DEFAULT '',
              feeling_tag TEXT NULL,
              familiar_person TEXT NULL,
              first_thought TEXT NULL,
              life_connection TEXT NULL,
              ai_interpretation TEXT NULL,
              user_id TEXT NULL,
              supabase_id TEXT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE activities (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              activity_ids_json TEXT NOT NULL,
              text TEXT NOT NULL,
              photo_path TEXT NULL,
              photo_url TEXT NULL,
              user_id TEXT NULL,
              supabase_id TEXT NULL
            )
          ''');
          raw.execute('''
            CREATE TABLE letters (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              open_at INTEGER NOT NULL,
              title TEXT NOT NULL,
              body TEXT NOT NULL,
              user_id TEXT NULL,
              supabase_id TEXT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO journal_entries
              (created_at, content, user_id, supabase_id)
            VALUES (1, 'cloud', 'user-a', 'journal-cloud')
          ''');
          raw.execute('''
            INSERT INTO dreams (date, content, user_id, supabase_id)
            VALUES (2, 'local only', 'user-a', NULL)
          ''');
          raw.execute('''
            INSERT INTO activities
              (created_at, activity_ids_json, text, user_id, supabase_id)
            VALUES (3, '[]', 'guest', NULL, NULL)
          ''');
          raw.execute('''
            INSERT INTO letters
              (created_at, open_at, title, body, user_id, supabase_id)
            VALUES (4, 5, 'title', 'body', 'user-a', 'letter-cloud')
          ''');
          raw.execute('PRAGMA user_version = 24');
        },
      ),
    );
    addTearDown(database.close);

    final journal = await database.select(database.journalEntries).getSingle();
    final dream = await database.select(database.dreams).getSingle();
    final activity = await database.select(database.activities).getSingle();
    final letter = await database.select(database.letters).getSingle();

    expect(journal.content, 'cloud');
    expect(journal.syncState, contentSyncSynced);
    expect(dream.content, 'local only');
    expect(dream.syncState, contentSyncPendingUpsert);
    expect(activity.activityText, 'guest');
    expect(activity.syncState, contentSyncSynced);
    expect(letter.body, 'body');
    expect(letter.syncState, contentSyncSynced);
    expect(journal.changedAt.millisecondsSinceEpoch, greaterThan(0));
  });
}
