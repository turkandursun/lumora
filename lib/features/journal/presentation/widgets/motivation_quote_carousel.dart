import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../domain/daily_content.dart';
import '../providers/journal_entries_provider.dart';
import '../providers/quote_favorites_provider.dart';
import 'share_quote_card.dart';

// ── Mood-adaptive affirmations ─────────────────────────────────────────────
// When the user's most common mood over the last 7 days is known, the
// affirmation slide speaks to that mood instead of a generic line — celebrating
// on good days, comforting on hard ones. Mood indices match the app's mood set:
// 0 happy · 1 calm · 2 tired · 3 sad · 4 anxious.
const Map<int, List<String>> _moodAffirmationsTr = {
  0: [
    'Bu neşeyi içinde tut, hak ettin.',
    'Güzel anların farkındasın; bu bir hediye.',
    'Mutluluğunu paylaşmak onu büyütür.',
    'Bugün parlıyorsun, tadını çıkar.',
  ],
  1: [
    'Bu huzuru koru, sana yakışıyor.',
    'Sakinliğin bir güç; onu taşı.',
    'Dengedesin ve bu çok güzel.',
    'Yavaşlamak da bir başarıdır.',
  ],
  2: [
    'Yorgunsan, dinlenmek de üretkenliktir.',
    'Kendine nazik ol; mola vermek güçtür.',
    'Her şeyi bugün çözmek zorunda değilsin.',
    'Bedenini dinle, o sana yol gösterir.',
  ],
  3: [
    'Bu duygu geçici; yalnız değilsin.',
    'Hüzün de insan olmanın bir parçası.',
    'Kendine şefkat göstermeyi hak ediyorsun.',
    'Ağır günler de geçer; derin bir nefes al.',
  ],
  4: [
    'Şu an güvendesin; yavaşça nefes al.',
    'Kaygı bazen yalan söyler; sen güçlüsün.',
    'Bir seferde tek adım yeterli.',
    'Ayaklarını yere bas; buradasın, iyisin.',
  ],
};
const Map<int, List<String>> _moodAffirmationsEn = {
  0: [
    'Hold on to this joy — you earned it.',
    "You notice the good moments; that's a gift.",
    'Sharing your happiness makes it grow.',
    'You are shining today; savor it.',
  ],
  1: [
    'Keep this calm — it suits you.',
    'Your calm is a strength; carry it.',
    'You are in balance, and it feels good.',
    'Slowing down is an achievement too.',
  ],
  2: [
    'If you are tired, rest is productive too.',
    'Be gentle with yourself; pausing is strength.',
    "You don't have to solve everything today.",
    'Listen to your body; it will guide you.',
  ],
  3: [
    'This feeling is temporary; you are not alone.',
    'Sadness is part of being human.',
    'You deserve to show yourself compassion.',
    'Heavy days pass too; take a slow breath.',
  ],
  4: [
    'You are safe right now; breathe slowly.',
    'Anxiety can lie; you are stronger than it.',
    'One step at a time is enough.',
    'Feel your feet on the ground; you are okay.',
  ],
};

/// A resurfaced past journal entry — Lumora's "on this day" memory.
class _Memory {
  const _Memory({required this.label, required this.text});
  final String label;
  final String text;
}

/// Finds the most striking "on this day" memory among past entries: the same
/// calendar day a year (or more) ago first, then one month ago, then one week
/// ago. Returns null when nothing lines up, so the slide simply doesn't appear.
_Memory? _findMemory(List<JournalEntryRow> entries, DateTime now, bool isTr) {
  if (entries.isEmpty) return null;
  DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = dayOf(now);

  JournalEntryRow? onDay(DateTime target) {
    for (final e in entries) {
      if (dayOf(e.createdAt) == target) return e;
    }
    return null;
  }

  JournalEntryRow? chosen;
  String? label;

  for (final e in entries) {
    final d = dayOf(e.createdAt);
    if (d.month == today.month && d.day == today.day && d.year < today.year) {
      final yrs = today.year - d.year;
      chosen = e;
      label = isTr ? '$yrs yıl önce bugün' : '$yrs year${yrs > 1 ? 's' : ''} ago today';
      break;
    }
  }
  if (chosen == null) {
    final e = onDay(DateTime(today.year, today.month - 1, today.day));
    if (e != null) {
      chosen = e;
      label = isTr ? '1 ay önce bugün' : '1 month ago today';
    }
  }
  if (chosen == null) {
    final e = onDay(today.subtract(const Duration(days: 7)));
    if (e != null) {
      chosen = e;
      label = isTr ? '1 hafta önce bugün' : '1 week ago today';
    }
  }
  if (chosen == null || label == null) return null;

  final title = chosen.title?.trim();
  final text = (title != null && title.isNotEmpty) ? title : chosen.content;
  return _Memory(label: label, text: text.trim());
}

/// Accent used across this card's slides — the app's theme accent, matching the
/// Profile screen: soft lavender on the moon scene, gold on the bright sun
/// scene.
Color _accent(bool isDark) => AstraKit.primary(isDark);

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

/// Home's swipeable daily deck: quick self-care tools, a daily intention, a
/// famous quote (with attribution), a mood-adaptive affirmation, a reflection
/// prompt, an optional "on this day" memory and a progress beat — all rotating
/// daily (see [dailyRotationIndex]). Quotes and intentions can be favorited and
/// shared as a branded card.
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
    final favorites = ref.watch(quoteFavoritesProvider);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final moodLog = ref.watch(moodLogProvider);
    final now = DateTime.now();
    final dayQuote = famousQuotes[dailyRotationIndex(now, famousQuotes.length)];
    final themeDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final accent = _accent(themeDark);

    // Personalization signals: dominant recent mood + an "on this day" memory.
    final mood = _mostCommonMoodLast7(moodLog);
    final entries = ref.watch(allJournalEntriesProvider).valueOrNull ?? const <JournalEntryRow>[];
    final memory = _findMemory(entries, now, isTr);

    final slides = <Widget>[
      // Quick tools first, directly visible on open.
      _ActionsSlide(isDark: themeDark, isTr: isTr),
      _QuoteSlide(
        isDark: themeDark,
        quote: dayQuote,
        isFavorite: favorites.contains(dayQuote.id),
        onToggleFavorite: () => ref.read(quoteFavoritesProvider.notifier).toggle(dayQuote.id),
        onShare: () => ShareQuoteCard.share(context: context, quoteText: dayQuote.text(isTr), isTr: isTr, author: dayQuote.author),
        onOpen: () => context.push(AppRoutes.quotes, extra: dailyRotationIndex(now, famousQuotes.length)),
      ),
      _AffirmationSlide(isDark: themeDark, isTr: isTr, mood: mood),
      if (memory != null) _MemorySlide(isDark: themeDark, memory: memory),
    ];
    final total = slides.length;
    final page = _page.clamp(0, total - 1);

    return AstraGlassCard(
      isDark: themeDark,
      primaryColor: accent,
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
              itemBuilder: (context, index) => slides[index],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CarouselArrow(
                isDark: themeDark,
                icon: Icons.chevron_left_rounded,
                onTap: page > 0 ? () => _go(page - 1) : null,
              ),
              const SizedBox(width: 4),
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == page ? accent : accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const SizedBox(width: 4),
              _CarouselArrow(
                isDark: themeDark,
                icon: Icons.chevron_right_rounded,
                onTap: page < total - 1 ? () => _go(page + 1) : null,
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
    required this.isDark,
    required this.quote,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onOpen,
  });

  final bool isDark;
  final FamousQuote quote;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(
            isDark: isDark,
            icon: Icons.format_quote_rounded,
            title: isTr ? 'Günün Sözü' : 'Quote of the day'),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpen,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quote.text(isTr),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ${quote.author}',
                      style: AstraKit.label(isDark, fontSize: 12.5),
                    ),
                  ],
                ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                              color: _accent(isDark),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: Localizations.localeOf(context).languageCode == 'tr' ? 'Paylaş' : 'Share',
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onShare,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.ios_share_rounded, color: _accent(isDark), size: 19),
                        ),
                      ),
                    ),
                  ),
                ],
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
  const _CarouselArrow(
      {required this.isDark, required this.icon, required this.onTap});

  final bool isDark;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = _accent(isDark);
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon,
            size: 22,
            color: enabled ? accent : accent.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// Shared little header (icon + title) shown at the top of each card in the
/// swipeable daily deck.
class _SlideHeader extends StatelessWidget {
  const _SlideHeader(
      {required this.isDark, required this.icon, required this.title});

  final bool isDark;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _accent(isDark), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: AstraKit.label(isDark, fontSize: 12.5)),
        ),
      ],
    );
  }
}

/// Daily affirmation card — mood-adaptive when a recent mood is known, so it
/// speaks to how the user has actually been feeling.
class _AffirmationSlide extends StatelessWidget {
  const _AffirmationSlide({required this.isDark, required this.isTr, this.mood});

  final bool isDark;
  final bool isTr;
  final int? mood;

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
    final List<String> list;
    final String title;
    if (mood != null) {
      list = (isTr ? _moodAffirmationsTr : _moodAffirmationsEn)[mood!] ?? (isTr ? _tr : _en);
      title = isTr ? 'Senin için' : 'For you';
    } else {
      list = isTr ? _tr : _en;
      title = isTr ? 'Günün Olumlaması' : 'Daily Affirmation';
    }
    final text = list[dailyRotationIndex(DateTime.now(), list.length)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(isDark: isDark, icon: Icons.spa_rounded, title: title),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(text, style: AstraKit.body(isDark, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

/// "On this day" memory — resurfaces a past journal entry from the same day a
/// year/month/week ago, so returning to Lumora feels like revisiting yourself.
class _MemorySlide extends StatelessWidget {
  const _MemorySlide({required this.isDark, required this.memory});

  final bool isDark;
  final _Memory memory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(isDark: isDark, icon: Icons.auto_stories_rounded, title: memory.label),
        const SizedBox(height: 8),
        Expanded(
          child: Text(
            memory.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AstraKit.body(isDark, fontSize: 14.5, fontWeight: FontWeight.w600, height: 1.35)
                .copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

/// Quick self-care tools — one-tap access to the calm/anxiety flow, a focus
/// timer and a breathing break, right inside the daily deck.
class _ActionsSlide extends StatelessWidget {
  const _ActionsSlide({required this.isDark, required this.isTr});

  final bool isDark;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideHeader(isDark: isDark, icon: Icons.favorite_rounded, title: isTr ? 'Kendine bir an' : 'A moment for you'),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
                  icon: Icons.spa_rounded,
                  label: isTr ? 'Sakinleş' : 'Calm',
                  onTap: () => context.push(AppRoutes.calm),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
                  icon: Icons.timer_outlined,
                  label: isTr ? 'Odak' : 'Focus',
                  onTap: () => context.push(AppRoutes.focusTimer),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  isDark: isDark,
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
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accent(isDark);
    return Material(
      color: isDark ? const Color(0x33231845) : const Color(0x59FBECCB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(height: 6),
              Text(label, style: AstraKit.body(isDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

