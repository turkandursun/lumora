import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/daily_question_repository.dart';

final dailyQuestionRepositoryProvider = Provider<DailyQuestionRepository>((ref) {
  return DailyQuestionRepository(database: ref.watch(appDatabaseProvider));
});

DateTime _todayDateOnly() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Today's answer row, or null if today's question hasn't been answered
/// yet.
final todayDailyQuestionAnswerProvider = StreamProvider<DailyQuestionAnswerRow?>((ref) {
  return ref.watch(dailyQuestionRepositoryProvider).watchForDate(_todayDateOnly());
});

/// Past answers, most recent first, excluding today (shown separately above
/// the history list).
final dailyQuestionHistoryProvider = StreamProvider<List<DailyQuestionAnswerRow>>((ref) {
  return ref.watch(dailyQuestionRepositoryProvider).watchHistoryBefore(_todayDateOnly());
});
