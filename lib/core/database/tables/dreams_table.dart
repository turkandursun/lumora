import 'package:drift/drift.dart';

/// A single saved dream entry: when it was recorded, the free-form text the
/// user wrote, and which symbols the local keyword detector recognized in
/// it (see `dreamSymbolKeywords`).
@DataClassName('DreamRow')
class Dreams extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get content => text()();

  /// Comma-separated canonical symbol keys detected in [content] at save
  /// time (e.g. `"water,flying"`). Kept denormalized rather than a join
  /// table — dream entries are immutable once saved, so there's nothing to
  /// keep in sync, and the tag set is always a subset of the small fixed
  /// symbol dictionary.
  TextColumn get symbolTags => text().withDefault(const Constant(''))();

  /// Answers to the optional post-save reflection flow (see
  /// `DreamReflectionScreen`) — every field stays null when its question
  /// was skipped; there's no forced completion.
  TextColumn get feelingTag => text().nullable()();
  TextColumn get familiarPerson => text().nullable()();
  TextColumn get firstThought => text().nullable()();
  TextColumn get lifeConnection => text().nullable()();

  /// Cached AI-generated reflection from the `dream-interpret` Edge
  /// Function, kept alongside the locally-detected [symbolTags] rather than
  /// replacing them. Null until the user explicitly requests an
  /// interpretation; re-requesting overwrites it rather than appending.
  TextColumn get aiInterpretation => text().nullable()();
}
