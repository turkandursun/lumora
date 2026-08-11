import 'package:drift/drift.dart';

/// Local offline cache of the quote catalogue managed in Supabase `quotes`.
@DataClassName('QuoteRow')
class Quotes extends Table {
  TextColumn get id => text()();
  TextColumn get textTr => text()();
  TextColumn get textEn => text()();
  TextColumn get author => text().nullable()();
  IntColumn get rotationOrder => integer().nullable()();
  BoolColumn get isActive => boolean()();
  TextColumn get source => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
