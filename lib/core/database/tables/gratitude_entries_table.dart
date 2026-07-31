import 'package:drift/drift.dart';

/// A single saved gratitude entry: the date it was recorded, the list of
/// items the user is grateful for (stored as JSON string), and an optional mood emoji.
@DataClassName('GratitudeEntryRow')
class GratitudeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get itemsJson => text()();
  TextColumn get mood => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
}
