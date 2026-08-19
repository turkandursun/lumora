import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/daily_quote_service.dart';
import '../../data/quotes_repository.dart';
import '../../domain/quote.dart';

final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  return QuotesRepository(database: ref.watch(appDatabaseProvider));
});

final dailyQuoteServiceProvider =
    Provider<DailyQuoteService>((ref) => DailyQuoteService());

/// The AI-generated "quote of the day" for [language] ('tr' / 'en'), or null.
/// When null (AI daily quotes disabled, offline, or the call failed) the daily
/// card falls back to the correctly-attributed famous-quote rotation, so it
/// always has trustworthy content. Surfaced signed as "Luma" — never falsely
/// attributed to a real person.
final dailyAiQuoteProvider =
    FutureProvider.family<Quote?, String>((ref, language) async {
  final text =
      await ref.watch(dailyQuoteServiceProvider).fetchDailyQuote(language: language);
  if (text == null) return null;
  final now = DateTime.now();
  final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  return Quote(
    id: 'ai_daily_$stamp',
    textTr: text,
    textEn: text,
    author: 'Luma',
    isActive: true,
    source: 'ai',
    updatedAt: now,
  );
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
