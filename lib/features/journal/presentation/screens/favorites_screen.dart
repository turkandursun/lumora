import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../domain/daily_content.dart';
import '../providers/quote_favorites_provider.dart';
import '../widgets/share_quote_card.dart';

/// A resolved favorite — a quote (with author) or an intention (no author).
class _FavItem {
  const _FavItem({required this.id, required this.text, this.author});
  final String id;
  final String text;
  final String? author;
}

/// Favorites — every quote and intention the user has hearted on the Home
/// deck, gathered in one place to revisit, re-share or remove. Reached from
/// the Profile menu.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  List<_FavItem> _resolve(Set<String> ids, bool isTr) {
    final items = <_FavItem>[];
    for (final id in ids) {
      if (id.startsWith('fq_')) {
        FamousQuote? match;
        for (final q in famousQuotes) {
          if (q.id == id) {
            match = q;
            break;
          }
        }
        if (match != null) items.add(_FavItem(id: id, text: match.text(isTr), author: match.author));
      } else if (id.startsWith('intent_')) {
        final idx = int.tryParse(id.substring('intent_'.length));
        if (idx != null && idx >= 0 && idx < dailyIntentions.length) {
          items.add(_FavItem(id: id, text: isTr ? dailyIntentions[idx].$1 : dailyIntentions[idx].$2));
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);
    final favorites = ref.watch(quoteFavoritesProvider);
    final items = _resolve(favorites, isTr);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(isTr ? 'Favorilerim' : 'My favorites', style: AstraKit.heading1(isDark, fontSize: 22)),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_border_rounded, size: 44, color: primary.withValues(alpha: 0.7)),
                                const SizedBox(height: 14),
                                Text(
                                  isTr
                                      ? 'Henüz favori yok. Ana sayfadaki kartlarda kalbe dokunarak söz ve niyetleri buraya ekle.'
                                      : 'No favorites yet. Tap the heart on the Home cards to save quotes and intentions here.',
                                  textAlign: TextAlign.center,
                                  style: AstraKit.mutedText(isDark, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: items.length,
                          itemBuilder: (context, index) => _FavCard(
                            item: items[index],
                            isDark: isDark,
                            primary: primary,
                            isTr: isTr,
                            onUnfavorite: () => ref.read(quoteFavoritesProvider.notifier).toggle(items[index].id),
                            onShare: () => ShareQuoteCard.share(
                              context: context,
                              quoteText: items[index].text,
                              isTr: isTr,
                              author: items[index].author,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  const _FavCard({
    required this.item,
    required this.isDark,
    required this.primary,
    required this.isTr,
    required this.onUnfavorite,
    required this.onShare,
  });

  final _FavItem item;
  final bool isDark;
  final Color primary;
  final bool isTr;
  final VoidCallback onUnfavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.text,
              style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
            ),
            if (item.author != null) ...[
              const SizedBox(height: 6),
              Text('— ${item.author}', style: AstraKit.label(isDark, fontSize: 12.5)),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onShare,
                  icon: Icon(Icons.ios_share_rounded, color: primary, size: 20),
                  tooltip: isTr ? 'Paylaş' : 'Share',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onUnfavorite,
                  icon: Icon(Icons.favorite_rounded, color: primary, size: 20),
                  tooltip: isTr ? 'Favoriden çıkar' : 'Remove favorite',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
