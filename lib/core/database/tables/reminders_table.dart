import 'package:drift/drift.dart';

/// How often a reminder repeats.
enum ReminderFrequency { daily, weekly, once }

/// A single reminder: what it's for (via [iconKey]), how often and when it
/// fires, and whether it's currently active. [iconKey] doubles as the
/// lookup key for both the reminder's icon and (for the four seeded
/// defaults) its notification body copy — see `_BreathingModeDisplay`-style
/// mappings in the presentation layer.
@DataClassName('ReminderRow')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get iconKey => text()();
  TextColumn get frequency => textEnum<ReminderFrequency>()();

  /// Day of week (1 = Monday .. 7 = Sunday, matching [DateTime.weekday]).
  /// Only meaningful when [frequency] is [ReminderFrequency.weekly].
  IntColumn get weekday => integer().nullable()();

  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
