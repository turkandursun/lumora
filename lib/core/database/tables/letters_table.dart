import 'package:drift/drift.dart';

@DataClassName('LetterRow')
class Letters extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get openAt => dateTime()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('synced'))();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
}
