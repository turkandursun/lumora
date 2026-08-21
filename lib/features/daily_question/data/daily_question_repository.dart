import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Owns Daily Question persistence via [AppDatabase] — one row per calendar
/// day, upserted on save so re-answering the same day edits in place rather
/// than creating a duplicate.
class DailyQuestionRepository {
  DailyQuestionRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  /// The single answer row for [date]'s calendar day, or null if
  /// unanswered.
  Stream<DailyQuestionAnswerRow?> watchForDate(DateTime date) {
    final day = _dateOnly(date);
    return (_db.select(_db.dailyQuestionAnswers)..where((t) => t.date.equals(day)))
        .watchSingleOrNull();
  }

  /// Every answer strictly before [date]'s calendar day, most recent first —
  /// meant to back the "past questions" history list below today's card.
  Stream<List<DailyQuestionAnswerRow>> watchHistoryBefore(DateTime date) {
    final day = _dateOnly(date);
    return (_db.select(_db.dailyQuestionAnswers)
          ..where((t) => t.date.isSmallerThanValue(day))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Inserts today's answer, or updates it in place if this calendar day
  /// already has one (editing).
  Future<void> saveAnswer({
    required DateTime date,
    required int questionIndex,
    required String answerText,
  }) async {
    final day = _dateOnly(date);
    final now = DateTime.now();
    final existing =
        await (_db.select(_db.dailyQuestionAnswers)..where((t) => t.date.equals(day))).getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.dailyQuestionAnswers).insert(
            DailyQuestionAnswersCompanion.insert(
              date: day,
              questionIndex: questionIndex,
              answerText: answerText,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(_db.dailyQuestionAnswers)..where((t) => t.id.equals(existing.id))).write(
        DailyQuestionAnswersCompanion(
          answerText: Value(answerText),
          updatedAt: Value(now),
        ),
      );
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
