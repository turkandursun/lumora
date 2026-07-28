import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/quote_favorites_repository.dart';

final quoteFavoritesRepositoryProvider = Provider<QuoteFavoritesRepository>((ref) {
  return QuoteFavoritesRepository();
});

/// The set of favorited quote ids, loaded once on first read and updated
/// optimistically as the user taps hearts on the Home carousel.
class QuoteFavoritesNotifier extends StateNotifier<Set<String>> {
  QuoteFavoritesNotifier(this._repository) : super(const {}) {
    _load();
  }

  final QuoteFavoritesRepository _repository;

  Future<void> _load() async {
    state = await _repository.loadFavoriteIds();
  }

  Future<void> toggle(String quoteId) async {
    final next = {...state};
    if (!next.remove(quoteId)) next.add(quoteId);
    state = next;
    await _repository.saveFavoriteIds(next);
  }
}

final quoteFavoritesProvider =
    StateNotifierProvider<QuoteFavoritesNotifier, Set<String>>((ref) {
  return QuoteFavoritesNotifier(ref.watch(quoteFavoritesRepositoryProvider));
});
