import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../domain/quote.dart';
import '../providers/quote_favorites_provider.dart';
import '../widgets/share_quote_card.dart';

/// User quote favorites resolved from the local Drift favorite mirror and
/// quote catalogue. Reached from the Profile menu.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);
    final favoritesAsync = ref.watch(favoriteQuotesProvider);
    final quotes = favoritesAsync.valueOrNull ?? const <Quote>[];

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
                      Text(
                        isTr ? 'Favorilerim' : 'My favorites',
                        style: AstraKit.heading1(isDark, fontSize: 22),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: favoritesAsync.isLoading && quotes.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(color: primary),
                        )
                      : quotes.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite_border_rounded,
                                      size: 44,
                                      color: primary.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      isTr
                                          ? 'Henüz favori sözün yok. Ana sayfadaki söz kartında kalbe dokunarak buraya ekleyebilirsin.'
                                          : 'No favorite quotes yet. Tap the heart on the Home quote card to save one here.',
                                      textAlign: TextAlign.center,
                                      style: AstraKit.mutedText(
                                        isDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: quotes.length,
                              itemBuilder: (context, index) {
                                final quote = quotes[index];
                                return _FavoriteQuoteCard(
                                  quote: quote,
                                  isDark: isDark,
                                  primary: primary,
                                  isTr: isTr,
                                  onUnfavorite: () => ref
                                      .read(quoteFavoritesProvider.notifier)
                                      .toggle(quote.id),
                                  onShare: () => ShareQuoteCard.share(
                                    context: context,
                                    quoteText: quote.text(isTr),
                                    isTr: isTr,
                                    author: quote.author,
                                  ),
                                );
                              },
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

class _FavoriteQuoteCard extends StatelessWidget {
  const _FavoriteQuoteCard({
    required this.quote,
    required this.isDark,
    required this.primary,
    required this.isTr,
    required this.onUnfavorite,
    required this.onShare,
  });

  final Quote quote;
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
              quote.text(isTr),
              style: AstraKit.body(
                isDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (quote.author != null) ...[
              const SizedBox(height: 6),
              Text(
                '— ${quote.author}',
                style: AstraKit.label(isDark, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onShare,
                  icon: Icon(
                    Icons.ios_share_rounded,
                    color: primary,
                    size: 20,
                  ),
                  tooltip: isTr ? 'Paylaş' : 'Share',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onUnfavorite,
                  icon: Icon(
                    Icons.favorite_rounded,
                    color: primary,
                    size: 20,
                  ),
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
