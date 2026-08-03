import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/journal_entries_repository.dart';

final journalEntriesRepositoryProvider = Provider<JournalEntriesRepository>((ref) {
  return JournalEntriesRepository(database: ref.watch(appDatabaseProvider));
});

/// Reactive list of the most recently saved journal entries, newest first.
final recentJournalEntriesProvider = StreamProvider<List<JournalEntryRow>>((ref) {
  final repo = ref.watch(journalEntriesRepositoryProvider);
  repo.fetchAndSyncFromSupabase();
  return repo.watchRecent();
});

/// Every saved journal entry, newest first — used by analytics/stats.
final allJournalEntriesProvider = StreamProvider<List<JournalEntryRow>>((ref) {
  final repo = ref.watch(journalEntriesRepositoryProvider);
  repo.fetchAndSyncFromSupabase();
  return repo.watchAll();
});

/// Local entry id → attached photo path, for the sealed-journals archive.
/// Re-reads whenever the entry list changes so a freshly sealed photo shows.
final journalPhotoPathsProvider = FutureProvider<Map<String, String>>((ref) {
  ref.watch(allJournalEntriesProvider);
  return JournalEntriesRepository.loadPhotoPaths();
});
