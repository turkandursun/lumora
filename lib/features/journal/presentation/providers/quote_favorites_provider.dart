import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/quote_favorites_repository.dart';
import '../../domain/quote.dart';
import 'quotes_provider.dart';

final quoteFavoritesRepositoryProvider =
    Provider<QuoteFavoritesRepository>((ref) {
  return QuoteFavoritesRepository(database: ref.watch(appDatabaseProvider));
});

/// User-scoped favorite ids emitted by the local Drift mirror. Cloud writes
/// happen in the repository and never block the optimistic local UI update.
class QuoteFavoritesNotifier extends StateNotifier<Set<String>> {
  QuoteFavoritesNotifier(this._repository) : super(const <String>{}) {
    unawaited(_initialize());
  }

  final QuoteFavoritesRepository _repository;
  StreamSubscription<Set<String>>? _subscription;

  Future<void> _initialize() async {
    _subscription = _repository.watchFavoriteIdsForCurrentUser().listen(
      (ids) {
        if (mounted) state = ids;
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[QuoteFavorites] local stream error: $error');
      },
    );
    await _repository.migrateLegacyFavoritesForCurrentUser();
    await _repository.syncForCurrentUser();
  }

  Future<void> toggle(String quoteId) => _repository.toggle(quoteId);

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final quoteFavoritesProvider =
    StateNotifierProvider<QuoteFavoritesNotifier, Set<String>>((ref) {
  return QuoteFavoritesNotifier(ref.watch(quoteFavoritesRepositoryProvider));
});

/// Full quote models for the Favorites screen, resolved by joining the local
/// favorite mirror with the local quote catalogue.
final favoriteQuotesProvider = StreamProvider<List<Quote>>((ref) {
  ref.watch(quoteFavoritesProvider);
  ref.watch(quotesProvider);
  return ref
      .watch(quoteFavoritesRepositoryProvider)
      .watchFavoriteQuotesForCurrentUser();
});
