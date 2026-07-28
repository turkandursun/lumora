import 'package:shared_preferences/shared_preferences.dart';

const _favoriteQuoteIdsKey = 'favorite_quote_ids';

/// Persists which motivational quotes the user has hearted, by
/// [MotivationalQuote.id] — a flat string set in [SharedPreferences],
/// mirroring the simple local-storage pattern used by the journaling and
/// goal streaks.
class QuoteFavoritesRepository {
  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favoriteQuoteIdsKey) ?? const []).toSet();
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteQuoteIdsKey, ids.toList());
  }
}
