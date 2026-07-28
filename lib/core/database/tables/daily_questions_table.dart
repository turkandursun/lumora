import 'package:drift/drift.dart';

/// One day's answer to the Daily Question feature's local, offline question
/// bank (see `daily_question_bank.dart`) — one row per calendar day
/// ([date] normalized to midnight, never two rows for the same day).
///
/// Community sharing (`features/community`) is optional and layered on top:
/// [isSharedToCommunity] and [communityShareId] just mirror whether this
/// answer currently has a matching row in Supabase's `daily_question_shares`
/// table, so the UI knows whether to show the share toggle as already on
/// and can delete/replace that remote row on edit.
@DataClassName('DailyQuestionAnswerRow')
class DailyQuestionAnswers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Midnight of the calendar day this question/answer belongs to.
  DateTimeColumn get date => dateTime()();

  /// Index into `dailyQuestionBank`, so the question text stays localized
  /// and re-orderable rather than frozen as whatever string was shown when
  /// it was answered.
  IntColumn get questionIndex => integer()();

  TextColumn get answerText => text()();

  BoolColumn get isSharedToCommunity => boolean().withDefault(const Constant(false))();

  /// The matching row's id in Supabase's `daily_question_shares` table, or
  /// null when [isSharedToCommunity] is false.
  TextColumn get communityShareId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
