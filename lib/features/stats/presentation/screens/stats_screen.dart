import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../../letters/presentation/providers/letter_providers.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../profile/presentation/providers/visit_tracker_providers.dart';
import '../../domain/journal_text_stats.dart';
import '../widgets/weekly_summary_card.dart';

const List<Color> _moodColors = [
  Color(0xFFF4C95D), // happy
  Color(0xFF9FD8B0), // calm
  Color(0xFFB9A7E0), // tired
  Color(0xFF8FA9D9), // sad
  Color(0xFFE59BB0), // anxious
];
const List<String> _moodEmojis = ['😊', '😌', '😴', '😔', '😟'];

/// Aggregated statistics across the app — the destination of the bottom
/// nav's stats tab.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    final entryDays =
        ref.watch(journalEntryDaysProvider).valueOrNull ?? const <DateTime>{};
    final streak = ref.watch(visitDaysCountProvider).valueOrNull ?? 0;
    final dreams = ref.watch(dreamsStreamProvider).valueOrNull?.length ?? 0;
    final moodLog = ref.watch(moodLogProvider);
    final lettersCount = ref.watch(lettersProvider).length;
    final contents = ref
            .watch(allJournalEntriesProvider)
            .valueOrNull
            ?.map((e) => e.content)
            .toList() ??
        const <String>[];
    final textStats = computeJournalTextStats(contents);

    final moodLabels = [
      l10n.moodHappy,
      l10n.moodCalm,
      l10n.moodTired,
      l10n.moodSad,
      l10n.moodAnxious,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(isTr ? 'İstatistikler' : 'Statistics',
                        style:
                            AstraKit.heading1(context, isDark, fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      const WeeklySummaryCard(),
                      const SizedBox(height: 12),
                      _OverviewCard(
                        isTr: isTr,
                        isDark: isDark,
                        primary: primary,
                        journaledDays: entryDays.length,
                        streak: streak,
                        dreams: dreams,
                        moods: moodLog.length,
                        letters: lettersCount,
                      ),
                      const SizedBox(height: 12),
                      _MoodDistributionCard(
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          moodLog: moodLog,
                          labels: moodLabels),
                      const SizedBox(height: 12),
                      _WeekdayCard(
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          entryDays: entryDays),
                      const SizedBox(height: 12),
                      _JournalAnalysisCard(
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          stats: textStats),
                      const SizedBox(height: 12),
                      _AiAnalysisCard(isDark: isDark, primary: primary),
                      const SizedBox(height: 8),
                    ],
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.journaledDays,
    required this.streak,
    required this.dreams,
    required this.moods,
    required this.letters,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final int journaledDays;
  final int streak;
  final int dreams;
  final int moods;
  final int letters;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
          icon: Icons.edit_note_rounded,
          primary: primary,
          isDark: isDark,
          value: journaledDays,
          label: isTr ? 'günlük gün' : 'journaled'),
      _StatTile(
          icon: Icons.local_fire_department_rounded,
          primary: primary,
          isDark: isDark,
          value: streak,
          label: isTr ? 'gün seri' : 'day streak'),
      _StatTile(
          icon: Icons.nights_stay_rounded,
          primary: primary,
          isDark: isDark,
          value: dreams,
          label: isTr ? 'rüya' : 'dreams'),
      _StatTile(
          icon: Icons.insights_rounded,
          primary: primary,
          isDark: isDark,
          value: moods,
          label: isTr ? 'ruh hali' : 'moods'),
      _StatTile(
          icon: Icons.mail_rounded,
          primary: primary,
          isDark: isDark,
          value: letters,
          label: isTr ? 'mektup' : 'letters'),
    ];

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isTr ? 'Genel bakış' : 'Overview',
              style: AstraKit.heading2(context, isDark, fontSize: 16)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            mainAxisExtent: 84,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.primary,
    required this.isDark,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color primary;
  final bool isDark;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(height: 5),
        AstraCountUp(
            value: value,
            style: AstraKit.heading1(context, isDark, fontSize: 20)),
        const SizedBox(height: 1),
        Text(label,
            textAlign: TextAlign.center,
            style: AstraKit.mutedText(context, isDark,
                fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MoodDistributionCard extends StatelessWidget {
  const _MoodDistributionCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.moodLog,
    required this.labels,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final Map<DateTime, int> moodLog;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(5, 0);
    for (final v in moodLog.values) {
      final i = v.clamp(0, 4);
      counts[i] = counts[i] + 1;
    }
    final total = moodLog.length;
    final mostIndex = total == 0
        ? -1
        : counts.indexOf(counts.reduce((a, b) => a > b ? a : b));

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(isTr ? 'Ruh hali dağılımı' : 'Mood distribution',
                  style: AstraKit.heading2(context, isDark, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Text(
              isTr
                  ? 'Ana sayfada ruh halini seçtikçe dağılım burada oluşacak.'
                  : 'Pick your mood on Home to see the distribution here.',
              style: AstraKit.mutedText(context, isDark, fontSize: 13),
            )
          else ...[
            for (var i = 0; i < 5; i++) ...[
              _MoodRow(
                emoji: _moodEmojis[i],
                label: labels[i],
                color: _moodColors[i],
                isDark: isDark,
                fraction: total == 0 ? 0 : counts[i] / total,
                percent: total == 0 ? 0 : (counts[i] / total * 100).round(),
              ),
              if (i < 4) const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            if (mostIndex >= 0)
              Row(
                children: [
                  Text(_moodEmojis[mostIndex],
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    isTr
                        ? 'En sık: ${labels[mostIndex]}'
                        : 'Most common: ${labels[mostIndex]}',
                    style: AstraKit.body(context, isDark,
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isDark,
    required this.fraction,
    required this.percent,
  });

  final String emoji;
  final String label;
  final Color color;
  final bool isDark;
  final double fraction;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 22,
            child: Text(emoji, style: const TextStyle(fontSize: 15))),
        const SizedBox(width: 6),
        SizedBox(
          width: 58,
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AstraKit.body(context, isDark,
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor:
                  AstraKit.muted(context, isDark).withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text('%$percent',
              textAlign: TextAlign.right,
              style: AstraKit.mutedText(context, isDark,
                  fontSize: 11.5, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard(
      {required this.isTr,
      required this.isDark,
      required this.primary,
      required this.entryDays});

  final bool isTr;
  final bool isDark;
  final Color primary;
  final Set<DateTime> entryDays;

  @override
  Widget build(BuildContext context) {
    final labels = isTr
        ? const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = List<int>.filled(7, 0);
    for (final d in entryDays) {
      final i = d.weekday - 1; // Mon=1 -> 0
      if (i >= 0 && i < 7) counts[i] = counts[i] + 1;
    }
    final maxCount = counts.fold<int>(0, (m, c) => c > m ? c : m);

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(isTr ? 'Yazma alışkanlığı' : 'Writing habit',
                  style: AstraKit.heading2(context, isDark, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${counts[i]}',
                            style: AstraKit.mutedText(context, isDark,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Container(
                          width: 14,
                          height: maxCount == 0
                              ? 4
                              : 6 + (counts[i] / maxCount) * 60,
                          decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        const SizedBox(height: 5),
                        Text(labels[i],
                            style: AstraKit.mutedText(context, isDark,
                                fontSize: 9.5)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.isDark,
      required this.primary,
      required this.value,
      required this.label});

  final bool isDark;
  final Color primary;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AstraCountUp(
            value: value,
            style: AstraKit.heading1(context, isDark,
                    fontSize: 22, fontWeight: FontWeight.w700)
                .copyWith(color: primary)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: AstraKit.mutedText(context, isDark,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// On-device journal analysis: entry/word counts and the most-used words.
class _JournalAnalysisCard extends StatelessWidget {
  const _JournalAnalysisCard(
      {required this.isTr,
      required this.isDark,
      required this.primary,
      required this.stats});

  final bool isTr;
  final bool isDark;
  final Color primary;
  final JournalTextStats stats;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(isTr ? 'Günlük analizi' : 'Journal analysis',
                  style: AstraKit.heading2(context, isDark, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.isEmpty)
            Text(
              isTr
                  ? 'Günlük yazdıkça yazı sayın, kelime sayın ve en çok kullandığın kelimeler burada görünecek.'
                  : 'As you journal, your entry count, word count and most-used words will appear here.',
              style: AstraKit.mutedText(context, isDark, fontSize: 13),
            )
          else ...[
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                        isDark: isDark,
                        primary: primary,
                        value: stats.entryCount,
                        label: isTr ? 'yazı' : 'entries')),
                Expanded(
                    child: _MiniStat(
                        isDark: isDark,
                        primary: primary,
                        value: stats.totalWords,
                        label: isTr ? 'kelime' : 'words')),
                Expanded(
                    child: _MiniStat(
                        isDark: isDark,
                        primary: primary,
                        value: stats.avgWords.round(),
                        label: isTr ? 'ort. kelime' : 'avg words')),
              ],
            ),
            if (stats.topWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                isTr ? 'En çok kullandığın kelimeler' : 'Your most-used words',
                style: AstraKit.mutedText(context, isDark,
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in stats.topWords)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: primary.withValues(alpha: 0.3)),
                      ),
                      child: Text('${w.$1} · ${w.$2}',
                          style: AstraKit.body(context, isDark,
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Optional AI (Luma) summary of recent journal entries.
class _AiAnalysisCard extends ConsumerStatefulWidget {
  const _AiAnalysisCard({required this.isDark, required this.primary});

  final bool isDark;
  final Color primary;

  @override
  ConsumerState<_AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends ConsumerState<_AiAnalysisCard> {
  bool _loading = false;
  bool _error = false;
  String? _result;

  Future<void> _run() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final rows = ref.read(allJournalEntriesProvider).valueOrNull ?? const [];
    final recent = rows.take(10).map((e) => e.content).toList();

    if (recent.isEmpty) {
      setState(() {
        _loading = false;
        _error = false;
        _result = isTr
            ? 'Analiz için önce birkaç günlük yaz.'
            : 'Write a few entries first for an analysis.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
      _result = null;
    });

    final joined = recent.join('\n---\n');
    final trimmed = joined.length > 1800 ? joined.substring(0, 1800) : joined;
    final message = isTr
        ? 'Son günlük yazılarımı ve ruh halimi nazikçe analiz eder misin? Kısa bir özet ve fark ettiğin duygu ya da temaları paylaş.'
        : 'Could you gently analyze my recent journal entries and mood? Share a short summary and any emotions or themes you notice.';

    try {
      final reply = await AiService().sendLumaMessage(
        message: message,
        language: isTr ? 'tr' : 'en',
        context: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = reply;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = widget.isDark;
    final primary = widget.primary;
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(isTr ? 'Luma ile analiz' : 'Analysis with Luma',
                  style: AstraKit.heading2(context, isDark, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Bu analiz için son günlüklerin Luma\'ya (yapay zeka) gönderilir.'
                : 'Your recent entries are sent to Luma (AI) for this analysis.',
            style: AstraKit.mutedText(context, isDark, fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Text(_result!,
                  style: AstraKit.body(context, isDark,
                      fontSize: 14, fontWeight: FontWeight.w500, height: 1.45)),
            ),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                isTr
                    ? 'Analiz alınamadı. İnternetini kontrol edip tekrar dene.'
                    : "Couldn't get the analysis. Check your connection and try again.",
                style: const TextStyle(fontSize: 13, color: Color(0xFFE07A7A)),
              ),
            ),
          AstraGoldButton(
            isDark: isDark,
            label: _loading
                ? (isTr ? 'Analiz ediliyor...' : 'Analyzing...')
                : (isTr ? 'Luma ile analiz et' : 'Analyze with Luma'),
            icon: Icons.auto_awesome,
            isLoading: _loading,
            enabled: !_loading,
            onTap: _run,
          ),
        ],
      ),
    );
  }
}
