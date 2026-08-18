import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../../journal/presentation/providers/journal_streak_provider.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../domain/weekly_summary.dart';

/// The user's "this week" snapshot, recomputed whenever moods, entries or the
/// streak change.
final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  final moodLog = ref.watch(moodLogProvider);
  final entries = ref.watch(allJournalEntriesProvider).valueOrNull ?? const [];
  final streak = ref.watch(journalStreakProvider).count;
  return WeeklySummary.compute(
    moodLog: moodLog,
    entryDates: entries.map((e) => e.createdAt).toList(),
    streak: streak,
  );
});
