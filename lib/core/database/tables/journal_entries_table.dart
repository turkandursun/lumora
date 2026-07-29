import 'package:drift/drift.dart';

/// A single saved journal entry from Home's writing area.
@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get content => text()();

  /// Absolute path to an attached voice-note recording, if the entry has
  /// one. Null for text-only entries (the common case).
  TextColumn get audioPath => text().nullable()();

  /// ID of the Supabase user who owns this entry.
  TextColumn get userId => text().nullable()();

  /// Remote primary key ID in Supabase's `journal_entries` table.
  TextColumn get supabaseId => text().nullable()();
}
