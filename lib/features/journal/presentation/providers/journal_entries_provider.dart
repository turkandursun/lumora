import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/journal_entries_repository.dart';

final journalEntriesRepositoryProvider = Provider<JournalEntriesRepository>((ref) {
  return JournalEntriesRepository(database: ref.watch(appDatabaseProvider));
});

/// Reactive list of the most recently saved journal entries, newest first.
final recentJournalEntriesProvider = StreamProvider<List<JournalEntryRow>>((ref) {
  return ref.watch(journalEntriesRepositoryProvider).watchRecent();
});

/// Every saved journal entry, newest first — used by analytics/stats.
final allJournalEntriesProvider = StreamProvider<List<JournalEntryRow>>((ref) {
  return ref.watch(journalEntriesRepositoryProvider).watchAll();
});
