import 'package:drift/drift.dart';

/// One day's answer to the Daily Question feature's local, offline question
/// bank (see `daily_question_bank.dart`) — one row per calendar day
/// ([date] normalized to midnight, never two rows for the same day).
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

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
