import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../domain/daily_content.dart';
import '../providers/quote_favorites_provider.dart';
import '../widgets/share_quote_card.dart';

/// Full-screen swipeable "quote gallery" in the Reflectly style: big cards on a
/// darkened image, a snapping [PageView] where the centred card is full size /
/// opaque and its neighbours shrink and fade, a word-by-word text reveal each
/// time a card centres, a worm dot indicator, and a bouncy share button that
/// opens a staggered options sheet.
class QuoteGalleryScreen extends ConsumerStatefulWidget {
  const QuoteGalleryScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<QuoteGalleryScreen> createState() => _QuoteGalleryScreenState();
}

class _QuoteGalleryScreenState extends ConsumerState<QuoteGalleryScreen> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, famousQuotes.length - 1);
    _controller = PageController(viewportFraction: 0.85, initialPage: _current);
    _controller.addListener(() {
      final p = _controller.page?.round() ?? _current;
      if (p != _current) setState(() => _current = p);
    });
  }

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
    final activeQuote = famousQuotes[_current];
    final isFav = favorites.contains(activeQuote.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                child: Row(
                  children: [
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(isTr ? 'Sözler' : 'Quotes',
                        style:
                            AstraKit.heading1(context, isDark, fontSize: 22)),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: famousQuotes.length,
                  itemBuilder: (context, i) {
                    final card = _QuoteCard(
                      quote: famousQuotes[i],
                      index: i,
                      controller: _controller,
                      isTr: isTr,
                    );
                    return AnimatedBuilder(
                      animation: _controller,
                      child: card,
                      builder: (context, child) {
                        final page = _controller.hasClients
                            ? (_controller.page ?? _current.toDouble())
                            : _current.toDouble();
                        final t = (1 - (page - i).abs().clamp(0.0, 1.0));
                        // Centred card: scale 1.0 / opacity 1. Neighbours snap
                        // down to 0.9 / 0.6 as they leave focus.
                        final scale = 0.9 + 0.1 * t;
                        final opacity = 0.6 + 0.4 * t;
                        return Center(
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(scale: scale, child: child),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SmoothPageIndicator(
                controller: _controller,
                count: famousQuotes.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 6,
                  activeDotColor: primary,
                  dotColor: primary.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 20),
              Row(
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
                  const SizedBox(width: 20),
                  _CircleAction(
                    icon: Icons.ios_share_rounded,
                    isDark: isDark,
                    primary: primary,
                    big: true,
                    onTap: () => _ShareOptionsSheet.show(
                        context, activeQuote, isTr, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single quote card: darkened image background, 32px soft corners, and a
/// word-by-word reveal that replays whenever the card scrolls to centre.
class _QuoteCard extends StatefulWidget {
  const _QuoteCard(
      {required this.quote,
      required this.index,
      required this.controller,
      required this.isTr});

  final FamousQuote quote;
  final int index;
  final PageController controller;
  final bool isTr;

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    widget.controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!mounted) return;
    final page = widget.controller.hasClients
        ? (widget.controller.page ?? widget.controller.initialPage.toDouble())
        : widget.controller.initialPage.toDouble();
    final active = page.round() == widget.index;
    if (active && !_wasActive) {
      _wasActive = true;
      _reveal.forward(from: 0);
    } else if (!active && _wasActive) {
      _wasActive = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/app_theme_dark.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF1B1330))),
            // Darkening gradient so the words stay legible.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0xCC0B0818)],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: Color(0xAAE3C264), size: 40),
                  const SizedBox(height: 12),
                  _WordReveal(
                    text: widget.quote.text(widget.isTr),
                    reveal: _reveal,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF7F1E4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _reveal,
                    builder: (context, child) {
                      final a = Curves.easeOutBack
                          .transform(_reveal.value.clamp(0.0, 1.0));
                      return Opacity(
                        opacity: _reveal.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                            offset: Offset(0, 16 * (1 - a)), child: child),
                      );
                    },
                    child: Text(
                      '— ${widget.quote.author}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE3C264)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Word-by-word "reveal from below" — each word fades in and springs up in
/// sequence, driven by a shared [reveal] controller.
class _WordReveal extends StatelessWidget {
  const _WordReveal(
      {required this.text, required this.reveal, required this.style});

  final String text;
  final Animation<double> reveal;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        return Wrap(
          spacing: 7,
          runSpacing: 2,
          children: [
            for (var i = 0; i < words.length; i++)
              _buildWord(words[i], i, words.length),
          ],
        );
      },
    );
  }

  Widget _buildWord(String word, int index, int total) {
    // Stagger each word across the first ~70% of the timeline.
    final start = (index / total) * 0.7;
    final local = ((reveal.value - start) / 0.3).clamp(0.0, 1.0);
    final eased = Curves.easeOutBack.transform(local);
    return Opacity(
      opacity: local,
      child: Transform.translate(
        offset: Offset(0, 22 * (1 - eased)),
        child: Text(word, style: style),
      ),
    );
  }
}

/// Round bouncy action button used under the carousel.
class _CircleAction extends StatelessWidget {
  const _CircleAction(
      {required this.icon,
      required this.isDark,
      required this.primary,
      required this.onTap,
      this.big = false});

  final IconData icon;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 64.0 : 52.0;
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

/// Bottom sheet whose share options spring in one after another (staggered).
class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet(
      {required this.quote, required this.isTr, required this.ref});

  final FamousQuote quote;
  final bool isTr;
  final WidgetRef ref;

  static Future<void> show(
      BuildContext context, FamousQuote quote, bool isTr, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareOptionsSheet(quote: quote, isTr: isTr, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _OptionRow(
        icon: Icons.image_rounded,
        label: isTr ? 'Görsel olarak paylaş' : 'Share as image',
        onTap: () {
          Navigator.of(context).pop();
          ShareQuoteCard.share(
              context: context,
              quoteText: quote.text(isTr),
              isTr: isTr,
              author: quote.author);
        },
      ),
      _OptionRow(
        icon: Icons.copy_rounded,
        label: isTr ? 'Metni kopyala' : 'Copy text',
        onTap: () {
          Clipboard.setData(
              ClipboardData(text: '"${quote.text(isTr)}" — ${quote.author}'));
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isTr ? 'Kopyalandı' : 'Copied')),
          );
        },
      ),
      _OptionRow(
        icon: Icons.favorite_border_rounded,
        label: isTr ? 'Favorilere ekle' : 'Add to favorites',
        onTap: () {
          ref.read(quoteFavoritesProvider.notifier).toggle(quote.id);
          Navigator.of(context).pop();
        },
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF01B1330),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x55C084FC)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          for (var i = 0; i < rows.length; i++)
            rows[i]
                .animate()
                .fadeIn(delay: (i * 70).ms, duration: 300.ms)
                .slideY(
                    begin: 0.4,
                    end: 0,
                    delay: (i * 70).ms,
                    duration: 420.ms,
                    curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC084FC), size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFF4EEFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
