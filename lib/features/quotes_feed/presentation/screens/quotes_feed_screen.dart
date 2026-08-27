import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../journal/domain/daily_content.dart';
import '../../../journal/presentation/providers/quote_favorites_provider.dart';
import '../../../journal/presentation/widgets/share_quote_card.dart';

/// "Günün Sözleri" — a full-screen, one-quote-per-page vertical feed of famous
/// thinkers' quotes. Reached by swiping right on Home (it sits to the left of
/// the home page in the shell's PageView). Swipe up/down to move between
/// quotes; each has favourite + share actions. Uses the same bundled
/// [famousQuotes] catalogue that previously fed the home "quote of the day".
class QuotesFeedScreen extends ConsumerStatefulWidget {
  const QuotesFeedScreen({super.key});

  @override
  ConsumerState<QuotesFeedScreen> createState() => _QuotesFeedScreenState();
}

class _QuotesFeedScreenState extends ConsumerState<QuotesFeedScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final favorites = ref.watch(quoteFavoritesProvider);
    final activeQuote = famousQuotes[_current.clamp(0, famousQuotes.length - 1)];
    final isFav = favorites.contains(activeQuote.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              scrollDirection: Axis.vertical,
              itemCount: famousQuotes.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) => _QuotePage(
                quote: famousQuotes[i],
                isTr: isTr,
                isDark: isDark,
                primary: primary,
                showScrollHint: i == 0 && famousQuotes.length > 1,
              ),
            ),
            // Header: title + position.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, size: 20, color: primary),
                    const SizedBox(width: 10),
                    Text(
                      isTr ? 'Günün Sözleri' : 'Words of the Day',
                      style: AstraKit.heading1(context, isDark, fontSize: 21),
                    ),
                    const Spacer(),
                    Text('${_current + 1} / ${famousQuotes.length}',
                        style: AstraKit.mutedText(context, isDark,
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            // Bottom actions for the current quote: favourite + share.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  // Clears the shell's floating bottom nav bar (~68px).
                  padding: const EdgeInsets.only(bottom: 82),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleAction(
                        icon: isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        isDark: isDark,
                        primary: primary,
                        onTap: () => ref
                            .read(quoteFavoritesProvider.notifier)
                            .toggle(activeQuote.id),
                      ),
                      const SizedBox(width: 22),
                      _CircleAction(
                        icon: Icons.ios_share_rounded,
                        isDark: isDark,
                        primary: primary,
                        big: true,
                        onTap: () => ShareQuoteCard.share(
                          context: context,
                          quoteText: activeQuote.text(isTr),
                          isTr: isTr,
                          author: activeQuote.author,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // A quiet hint that Home is a swipe to the right.
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(Icons.chevron_right_rounded,
                    size: 26, color: primary.withValues(alpha: 0.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single full-screen quote: a soft glass panel holding an oversized quote
/// glyph, the words in an elegant serif, and the author.
class _QuotePage extends StatelessWidget {
  const _QuotePage({
    required this.quote,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.showScrollHint,
  });

  final FamousQuote quote;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final bool showScrollHint;

  @override
  Widget build(BuildContext context) {
    final ink = AstraKit.ink(context, isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 96, 28, 120),
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_rounded,
                  size: 54, color: primary.withValues(alpha: 0.55)),
              const SizedBox(height: 18),
              Text(
                quote.text(isTr),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 27,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 26,
                      height: 1.6,
                      color: primary.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Text(
                    quote.author,
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: primary,
                    ),
                  ),
                ],
              ),
              if (showScrollHint) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.keyboard_arrow_up_rounded,
                          size: 26, color: ink.withValues(alpha: 0.5)),
                      Text(
                        isTr
                            ? 'Yukarı kaydır · sonraki söz'
                            : 'Swipe up · next quote',
                        style: AstraKit.mutedText(context, isDark, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Round bouncy action button (favourite / share).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.isDark,
    required this.primary,
    required this.onTap,
    this.big = false,
  });

  final IconData icon;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 62.0 : 50.0;
    return BouncyTap(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: big
              ? LinearGradient(
                  colors: [primary, primary.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: big
              ? null
              : (isDark ? const Color(0x44231845) : const Color(0xCCFCF4E2)),
          border: Border.all(color: primary.withValues(alpha: 0.4)),
          boxShadow: big
              ? [
                  BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Icon(icon,
            color: big ? Colors.white : primary, size: big ? 26 : 22),
      ),
    );
  }
}
