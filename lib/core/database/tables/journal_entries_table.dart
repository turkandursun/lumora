import 'package:drift/drift.dart';

/// A single saved journal entry from Home's writing area.
@DataClassName('JournalEntryRow')
class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get content => text()();

  /// Optional short heading the user typed for this entry.
  TextColumn get title => text().nullable()();

  /// Absolute path to an attached voice-note recording, if the entry has
  /// one. Null for text-only entries (the common case).
  TextColumn get audioPath => text().nullable()();

  /// Remote signed URL or local path to an attached photo.
  TextColumn get photoUrl => text().nullable()();

  /// ID of the Supabase user who owns this entry.
  TextColumn get userId => text().nullable()();

  /// Remote primary key ID in Supabase's `journal_entries` table.
  TextColumn get supabaseId => text().nullable()();

  /// Persistent outbox state: synced, pending_upsert, or pending_delete.
  TextColumn get syncState => text().withDefault(const Constant('synced'))();

  /// Local mutation timestamp used to avoid acknowledging a stale push.
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
}
