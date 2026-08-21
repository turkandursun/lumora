import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/activities/presentation/providers/activity_providers.dart';
import '../../features/calendar/presentation/providers/calendar_providers.dart';
import '../../features/daily_question/presentation/providers/daily_question_providers.dart';
import '../../features/dreams/presentation/providers/dreams_providers.dart';
import '../../features/goals/presentation/providers/goals_providers.dart';
import '../../features/hobbies/presentation/providers/hobbies_providers.dart';
import '../../features/journal/presentation/providers/journal_entries_provider.dart';
import '../../features/journal/presentation/providers/journal_streak_provider.dart';
import '../../features/journal/presentation/providers/quote_favorites_provider.dart';
import '../../features/letters/presentation/providers/letter_providers.dart';
import '../../features/mood/presentation/providers/mood_providers.dart';
import '../../features/profile/presentation/providers/visit_tracker_providers.dart';
import '../../features/reminders/presentation/providers/reminders_providers.dart';
import '../../features/special_days/presentation/providers/special_days_providers.dart';
import '../../features/wellbeing/presentation/providers/focus_providers.dart';
import '../../features/auth/presentation/providers/account_deletion_provider.dart';
import 'astra_palette_provider.dart';
import 'astra_theme_provider.dart';

/// Invalidate all user-specific Riverpod providers on auth change (signedIn, signedOut).
void invalidateUserProviders(WidgetRef ref) {
  ref.invalidate(astraPaletteProvider);
  ref.invalidate(astraThemeProvider);
  ref.invalidate(hobbiesProvider);
  ref.invalidate(journalStreakProvider);
  ref.invalidate(visitDaysCountProvider);
  ref.invalidate(weeklyVisitDatesProvider);
  ref.invalidate(recentJournalEntriesProvider);
  ref.invalidate(allJournalEntriesProvider);
  ref.invalidate(journalEntriesRepositoryProvider);
  ref.invalidate(journalEntryDaysProvider);
  ref.invalidate(moodLogProvider);
  ref.invalidate(goalsStreamProvider);
  ref.invalidate(goalStreakProvider);
  ref.invalidate(goalsRepositoryProvider);
  ref.invalidate(dreamsStreamProvider);
  ref.invalidate(dreamsRepositoryProvider);
  ref.invalidate(periodRepositoryProvider);
  ref.invalidate(symptomRepositoryProvider);
  ref.invalidate(periodDaysProvider);
  ref.invalidate(symptomsProvider);
  ref.invalidate(lettersProvider);
  ref.invalidate(letterRepositoryProvider);
  ref.invalidate(remindersStreamProvider);
  ref.invalidate(specialDaysProvider);
  ref.invalidate(specialDaysRepositoryProvider);
  ref.invalidate(todayDailyQuestionAnswerProvider);
  ref.invalidate(dailyQuestionHistoryProvider);
  ref.invalidate(activitiesProvider);
  ref.invalidate(activityRepositoryProvider);
  ref.invalidate(quoteFavoritesProvider);
  ref.invalidate(favoriteQuotesProvider);
  ref.invalidate(activeFocusSessionProvider);
  ref.invalidate(focusStatsProvider);
  ref.invalidate(focusRepositoryProvider);
}

/// Retries all persistent user-content outboxes. Each repository captures and
/// revalidates the authenticated user, so a late response from account A can
/// never mutate account B's visible state.
Future<void> syncUserContentOutboxes(WidgetRef ref) async {
  await Future.wait<void>([
    ref.read(journalEntriesRepositoryProvider).syncForCurrentUser(),
    ref.read(dreamsRepositoryProvider).syncForCurrentUser(),
    ref.read(activityRepositoryProvider).syncForCurrentUser(),
    ref.read(letterRepositoryProvider).syncForCurrentUser(),
    ref.read(specialDaysRepositoryProvider).syncForCurrentUser(),
  ]);
  final isTr =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr';
  await ref.read(specialDaysProvider.notifier).rearm(isTr: isTr);
}

/// Clears local user data stored in SQLite / Drift tables on sign out.
Future<void> clearLocalUserData(WidgetRef ref, {String? userId}) async {
  try {
    final scopedUserId =
        userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (scopedUserId == null) return;
    await ref
        .read(localUserDataCleanupServiceProvider)
        .clearSignedOutAccount(scopedUserId);
    debugPrint(
        '[AuthListener] Successfully cleared local cache for signed-out user');
  } catch (e) {
    debugPrint('[AuthListener] Error clearing signed-out user cache: $e');
  }
}
