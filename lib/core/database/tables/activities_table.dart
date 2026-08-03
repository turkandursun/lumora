import 'package:drift/drift.dart';

/// One logged activity entry: when it was recorded, selected activity IDs JSON,
/// combined display text, local photo path, remote Supabase photo URL,
/// userId and supabaseId.
@DataClassName('ActivityRow')
class Activities extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get activityIdsJson => text()();
  TextColumn get activityText => text().named('text')();
  TextColumn get photoPath => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get userId => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
}
