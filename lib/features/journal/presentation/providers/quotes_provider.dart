import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/quotes_repository.dart';
import '../../domain/quote.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return QuotesRepository(database: ref.watch(appDatabaseProvider));
});

/// Active quote catalogue from Drift, refreshed from Supabase in the
/// background after the bundled offline seed has been ensured.
final quotesProvider = StreamProvider<List<Quote>>((ref) async* {
  debugPrint('[Quotes] quotesProvider instantiated');
  final repository = ref.watch(quotesRepositoryProvider);
  await repository.ensureSeeded();
  unawaited(repository.fetchAndSyncFromSupabase());
  yield* repository.watchActiveQuotes();
});
