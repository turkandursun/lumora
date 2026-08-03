import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/activities/presentation/providers/activity_providers.dart';
import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/daily_question/presentation/providers/daily_question_providers.dart';
import '../../features/dreams/presentation/providers/dreams_providers.dart';
import '../../features/goals/presentation/providers/goals_providers.dart';
import '../../features/gratitude/presentation/providers/gratitude_providers.dart';
import '../../features/hobbies/presentation/providers/hobbies_providers.dart';
import '../../features/journal/presentation/providers/journal_entries_provider.dart';
import '../../features/journal/presentation/providers/journal_streak_provider.dart';
import '../../features/journal/presentation/providers/quote_favorites_provider.dart';
import '../../features/letters/presentation/providers/letter_providers.dart';
import '../../features/mood/presentation/providers/mood_providers.dart';
import '../../features/profile/presentation/providers/visit_tracker_providers.dart';
import '../../features/reminders/presentation/providers/reminders_providers.dart';

/// Invalidate all user-specific Riverpod providers on auth change (signedIn, signedOut).
void invalidateUserProviders(WidgetRef ref) {
  ref.invalidate(hobbiesProvider);
  ref.invalidate(journalStreakProvider);
  ref.invalidate(visitDaysCountProvider);
  ref.invalidate(recentJournalEntriesProvider);
  ref.invalidate(allJournalEntriesProvider);
  ref.invalidate(journalEntryDaysProvider);
  ref.invalidate(moodLogProvider);
  ref.invalidate(goalsStreamProvider);
  ref.invalidate(goalStreakProvider);
  ref.invalidate(dreamsStreamProvider);
  ref.invalidate(periodDaysProvider);
  ref.invalidate(symptomsProvider);
  ref.invalidate(gratitudeProvider);
  ref.invalidate(lettersProvider);
  ref.invalidate(remindersStreamProvider);
  ref.invalidate(todayDailyQuestionAnswerProvider);
  ref.invalidate(dailyQuestionHistoryProvider);
  ref.invalidate(activitiesProvider);
  ref.invalidate(quoteFavoritesProvider);
}

/// Clears local user data stored in SQLite / Drift tables on sign out.
Future<void> clearLocalUserData(WidgetRef ref) async {
  try {
    await ref.read(journalEntriesRepositoryProvider).deleteAll();
    await ref.read(goalsRepositoryProvider).deleteAll();
    await ref.read(dreamsRepositoryProvider).deleteAll();
    await ref.read(gratitudeRepositoryProvider).deleteAll();
    await ref.read(activityRepositoryProvider).deleteAll();
    await ref.read(remindersRepositoryProvider).deleteAll();
    debugPrint('[AuthListener] Successfully cleared local user database tables');
  } catch (e) {
    debugPrint('[AuthListener] Error clearing local user database tables: $e');
  }
}
