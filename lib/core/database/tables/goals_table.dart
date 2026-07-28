import 'package:drift/drift.dart';

/// Unit a goal's progress is measured in. [custom] pairs with
/// [Goals.customUnitLabel] for user-defined units the four seeded presets
/// don't cover.
enum GoalUnit { glasses, minutes, pages, books, custom }

/// How often a goal's progress resets — see `resetElapsedPeriods` in
/// `GoalsRepository`.
enum GoalFrequency { daily, weekly, monthly }

/// A single trackable goal: what it's for (via [iconKey]), how much
/// [progress] it takes to reach [target] once, and which period it's
/// currently tracking. [periodStart] anchors that period — it's compared
/// against the period [frequency] implies for "now", and whenever they've
/// drifted apart [progress] is zeroed and [periodStart] moved forward (see
/// `GoalsRepository.resetElapsedPeriods`).
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
}
