import 'package:drift/drift.dart';

/// Account-scoped special dates with a persistent local-first cloud outbox.
@DataClassName('SpecialDayRow')
class SpecialDays extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID; also the primary key in Supabase.
  TextColumn get specialDayUuid => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get dayType => text()();

  /// A local calendar date. Consumers serialize it as YYYY-MM-DD without UTC
  /// conversion so birthdays cannot shift to an adjacent day.
  DateTimeColumn get eventDate => dateTime()();
  BoolColumn get repeatsAnnually =>
      boolean().withDefault(const Constant(true))();

  /// Persistent outbox state: synced, pending_upsert, or pending_delete.
  TextColumn get syncState => text().withDefault(const Constant('synced'))();
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get cloudUpdatedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, specialDayUuid},
      ];
}
