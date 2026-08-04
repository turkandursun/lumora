import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../domain/motivational_quote.dart';
import '../providers/journal_streak_provider.dart';
import '../providers/quote_favorites_provider.dart';

const _gold = Color(0xFFE9C98C);
const List<String> _moodEmojis = ['😊', '😌', '😴', '😔', '😟'];

int? _mostCommonMoodLast7(Map<DateTime, int> log) {
  final today = DateTime.now();
  final counts = List<int>.filled(5, 0);
  var any = false;
  for (var i = 0; i < 7; i++) {
    final d = today.subtract(Duration(days: i));
    final key = DateTime(d.year, d.month, d.day);
    final v = log[key];
    if (v != null) {
      counts[v.clamp(0, 4)]++;
      any = true;
    }
  }
  if (!any) return null;
  var best = 0;
  for (var i = 1; i < 5; i++) {
    if (counts[i] > counts[best]) best = i;
  }
  return best;
}

String _moodLabel(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return l10n.moodHappy;
    case 1:
      return l10n.moodCalm;
    case 2:
      return l10n.moodTired;
    case 3:
      return l10n.moodSad;
    default:
      return l10n.moodAnxious;
  }
}

/// "Today's Motivational Quote" card — a swipeable deck of short, original
/// quotes seeded locally (see [motivationalQuotes]), opening on the quote
/// the day's rotation picked (see [dailyStartIndex]) with a dot indicator
/// and a per-quote favorite heart.
class MotivationQuoteCarousel extends ConsumerStatefulWidget {
  const MotivationQuoteCarousel({super.key});

  @override
  ConsumerState<MotivationQuoteCarousel> createState() => _MotivationQuoteCarouselState();
}

class _MotivationQuoteCarouselState extends ConsumerState<MotivationQuoteCarousel> {
  late final PageController _pageController;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = 0;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quotes = motivationalQuotes(l10n);
    final favorites = ref.watch(quoteFavoritesProvider);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final streak = ref.watch(journalStreakProvider).count;
    final moodLog = ref.watch(moodLogProvider);
    final dayQuote = quotes[dailyStartIndex(DateTime.now(), quotes.length)];
    const total = 5;

    return AstraGlassCard(
      isDark: true,
      primaryColor: _gold,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 132,
            child: PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _QuoteSlide(
                      quote: dayQuote,
                      isFavorite: favorites.contains(dayQuote.id),
                      onToggleFavorite: () => ref
                          .read(quoteFavoritesProvider.notifier)
                          .toggle(dayQuote.id),
                    );
                  case 1:
                    return _AffirmationSlide(isTr: isTr);
                  case 2:
                    return _QuestionSlide(isTr: isTr);
                  case 3:
                    return _StreakStatSlide(
                        isTr: isTr, streak: streak, moodLog: moodLog);
                  default:
                    return _ActionsSlide(isTr: isTr);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                onTap: _page > 0 ? () => _go(_page - 1) : null,
              ),
              const SizedBox(width: 4),
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? _gold : _gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 4),
              _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                onTap: _page < total - 1 ? () => _go(_page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteSlide extends StatelessWidget {
  const _QuoteSlide({
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final MotivationalQuote quote;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(icon: Icons.format_quote_rounded, title: l10n.homeQuoteCardTitle),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quote.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AstraKit.body(true, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    const SizedBox(
                      width: 88,
                      height: 22,
                      child: CustomPaint(painter: _SunriseLineArtPainter()),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: isFavorite
                    ? AppLocalizations.of(context).homeQuoteUnfavorite
                    : AppLocalizations.of(context).homeQuoteFavorite,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onToggleFavorite,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(isFavorite),
                          color: _gold,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small tappable arrow for stepping through the deck (in addition to
/// swiping) — handy on desktop/emulator where dragging is fiddly.
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 22, color: enabled ? _gold : _gold.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// Shared little header (icon + title) shown at the top of each card in the
/// swipeable daily deck.
class _SlideHeader extends StatelessWidget {
  const _SlideHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _gold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: AstraKit.label(true, fontSize: 12.5)),
        ),
      ],
    );
  }
}

/// Daily affirmation card.
class _AffirmationSlide extends StatelessWidget {
  const _AffirmationSlide({required this.isTr});

  final bool isTr;

  static const _tr = [
    'Ben yeterliyim.',
    'Adım adım ilerliyorum.',
    'Duygularıma yer açabilirim.',
    'Bugün kendime nazik davranıyorum.',
    'Zorluklarla başa çıkabilirim.',
    'Her nefes beni sakinleştiriyor.',
  ];
  static const _en = [
    'I am enough.',
    'I move forward step by step.',
    'I can make space for my feelings.',
    'I am kind to myself today.',
    'I can handle challenges.',
    'Every breath calms me.',
  ];

  @override
  Widget build(BuildContext context) {
    final list = isTr ? _tr : _en;
    final text = list[dailyStartIndex(DateTime.now(), list.length)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(icon: Icons.spa_rounded, title: isTr ? 'Günün Olumlaması' : 'Daily Affirmation'),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(text, style: AstraKit.body(true, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

/// A prompt that opens the daily question screen.
class _QuestionSlide extends StatelessWidget {
  const _QuestionSlide({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(AppRoutes.dailyQuestion),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideHeader(icon: Icons.help_outline_rounded, title: isTr ? 'Günün Sorusu' : 'Daily Question'),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              isTr
                  ? 'Bugün seni en çok ne düşündürdü? Yazmak için dokun.'
                  : "What's been on your mind today? Tap to write.",
              style: AstraKit.body(true, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(isTr ? 'Cevapla' : 'Answer', style: AstraKit.label(true, fontSize: 12.5)),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _gold),
            ],
          ),
        ],
      ),
    );
  }
}

/// A live "your progress" card: journaling streak + most common recent mood.
class _StreakStatSlide extends StatelessWidget {
  const _StreakStatSlide({
    required this.isTr,
    required this.streak,
    required this.moodLog,
  });

  final bool isTr;
  final int streak;
  final Map<DateTime, int> moodLog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mostMood = _mostCommonMoodLast7(moodLog);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(icon: Icons.local_fire_department_rounded, title: isTr ? 'Bugünkü durumun' : 'Your progress'),
        const SizedBox(height: 10),
        Text(
          streak > 0
              ? (isTr ? '🔥 $streak gündür yazıyorsun' : '🔥 $streak-day streak')
              : (isTr ? 'Bugün yazarak seriyi başlat' : 'Start a streak by writing today'),
          style: AstraKit.body(true, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          mostMood == null
              ? (isTr
                  ? 'Ruh halini seçtikçe burada haftalık özetin çıkar.'
                  : 'Log your mood to see a weekly summary here.')
              : (isTr
                  ? '${_moodEmojis[mostMood]}  Bu hafta en sık: ${_moodLabel(l10n, mostMood)}'
                  : '${_moodEmojis[mostMood]}  Most common this week: ${_moodLabel(l10n, mostMood)}'),
          style: AstraKit.mutedText(true, fontSize: 13.5),
        ),
      ],
    );
  }
}

/// Quick self-care actions: gratitude and a breathing break.
class _ActionsSlide extends StatelessWidget {
  const _ActionsSlide({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(icon: Icons.favorite_rounded, title: isTr ? 'Küçük bir mola?' : 'A little moment?'),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.volunteer_activism_rounded,
                  label: isTr ? 'Şükran' : 'Gratitude',
                  onTap: () => context.push(AppRoutes.gratitude),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.air_rounded,
                  label: isTr ? 'Nefes' : 'Breathe',
                  onTap: () => context.push(AppRoutes.breathing),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x33231845),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _gold, size: 22),
              const SizedBox(height: 6),
              Text(label, style: AstraKit.body(true, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny soft-line illustration of a mountain range with a rising sun —
/// purely decorative, tucked under each quote's text.
class _SunriseLineArtPainter extends CustomPainter {
  const _SunriseLineArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint = Paint()..color = _gold.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.62), 9, sunPaint);

    final linePaint = Paint()
      ..color = _gold.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final mountains = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.22, size.height * 0.32)
      ..lineTo(size.width * 0.4, size.height * 0.6)
      ..lineTo(size.width * 0.58, size.height * 0.18)
      ..lineTo(size.width * 0.8, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.3);
    canvas.drawPath(mountains, linePaint);

    final groundPaint = Paint()
      ..color = _gold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      groundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
