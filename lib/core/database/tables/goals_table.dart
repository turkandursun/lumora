import 'package:drift/drift.dart';

/// Unit a goal's progress is measured in. [custom] pairs with
/// [Goals.customUnitLabel] for user-defined units the four seeded presets
/// don't cover.
enum GoalUnit { glasses, minutes, pages, books, custom }

/// How often a goal's progress is grouped into calendar periods.
enum GoalFrequency { daily, weekly, monthly }

/// A single trackable goal: what it's for (via [iconKey]), how much
/// [progress] it takes to reach [target] once, and which period it's
/// currently tracking. [periodStart] anchors that period. Every repository
/// increment atomically resets elapsed-period progress before adding to it.
@DataClassName('GoalRow')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get iconKey => text()();
  TextColumn get unit => textEnum<GoalUnit>()();

  /// User-provided unit label, only set when [unit] is [GoalUnit.custom].
  TextColumn get customUnitLabel => text().nullable()();

  IntColumn get target => integer()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get frequency => textEnum<GoalFrequency>()();

  /// Start of the period [progress] is currently counting toward — midnight
  /// of today, this week's Monday, or this month's 1st, depending on
  /// [frequency].
  DateTimeColumn get periodStart => dateTime()();

  /// Supabase auth ID of the user who owns this goal.
  TextColumn get userId => text().nullable()();

  /// Remote primary key in Supabase `goals` table.
  TextColumn get supabaseId => text().nullable()();

  /// Stable catalogue key for suggested goals. Custom goals keep this null.
  TextColumn get templateKey => text().nullable()();

  /// Whether the goal is currently visible or retained as history.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Local-first synchronization state (`synced` or `pending`).
  TextColumn get syncState => text().withDefault(const Constant('synced'))();

  /// Last local mutation time, generated in UTC for new local rows.
  DateTimeColumn get changedAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  /// Last `updated_at` value observed from Supabase.
  DateTimeColumn get cloudUpdatedAt => dateTime().nullable()();

  /// Last time this local row completed a successful cloud synchronization.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
}
