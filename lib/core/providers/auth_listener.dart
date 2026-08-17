import 'package:flutter/foundation.dart';
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
  ref.invalidate(recentJournalEntriesProvider);
  ref.invalidate(allJournalEntriesProvider);
  ref.invalidate(journalEntryDaysProvider);
  ref.invalidate(moodLogProvider);
  ref.invalidate(goalsStreamProvider);
  ref.invalidate(goalStreakProvider);
  ref.invalidate(goalsRepositoryProvider);
  ref.invalidate(dreamsStreamProvider);
  ref.invalidate(periodDaysProvider);
  ref.invalidate(symptomsProvider);
  ref.invalidate(lettersProvider);
  ref.invalidate(remindersStreamProvider);
  ref.invalidate(todayDailyQuestionAnswerProvider);
  ref.invalidate(dailyQuestionHistoryProvider);
  ref.invalidate(activitiesProvider);
  ref.invalidate(quoteFavoritesProvider);
  ref.invalidate(favoriteQuotesProvider);
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
