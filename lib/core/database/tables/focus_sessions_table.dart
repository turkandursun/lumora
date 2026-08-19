import 'package:drift/drift.dart';

/// A focus interval that reached its natural end.
///
/// Running, paused and break state deliberately lives outside this table in a
/// lightweight user-scoped preference. Only completed focus work is durable
/// history and eligible for cloud synchronization.
@DataClassName('FocusSessionRow')
class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Client-generated UUID; also the primary key in Supabase.
  TextColumn get sessionUuid => text()();

  TextColumn get userId => text()();
  TextColumn get taskLabel => text().nullable()();
  IntColumn get plannedDurationSeconds => integer()();
  IntColumn get actualDurationSeconds => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();

  /// Local-first synchronization state (`pending` or `synced`).
  TextColumn get syncState => text().withDefault(const Constant('pending'))();
  DateTimeColumn get changedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  DateTimeColumn get cloudUpdatedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, sessionUuid},
      ];
}
