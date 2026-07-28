import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../gratitude/presentation/providers/gratitude_providers.dart';
import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../../../theme/app_background.dart';
import '../../../journal/presentation/providers/journal_streak_provider.dart';
import '../../../letters/presentation/providers/letter_providers.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../domain/journal_text_stats.dart';

const _periodColor = Color(0xFFE0748F);
const List<int> _moodScores = [5, 4, 3, 1, 2];
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

    final entryDays =
        ref.watch(journalEntryDaysProvider).valueOrNull ?? const <DateTime>{};
    final streak = ref.watch(journalStreakProvider).count;
    final dreams = ref.watch(dreamsStreamProvider).valueOrNull?.length ?? 0;
    final moodLog = ref.watch(moodLogProvider);
    final periodDays = ref.watch(periodDaysProvider);
    final gratitudeCount = ref.watch(gratitudeProvider).length;
    final lettersCount = ref.watch(lettersProvider).length;
    final contents = ref.watch(allJournalEntriesProvider).valueOrNull
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
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr ? 'İstatistikler' : 'Statistics',
                style: AppTheme.displayFont(
                  fontSize: 24,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _OverviewCard(
                      isTr: isTr,
                      journaledDays: entryDays.length,
                      streak: streak,
                      dreams: dreams,
                      moods: moodLog.length,
                      periodDays: periodDays.length,
                      gratitude: gratitudeCount,
                      letters: lettersCount,
                    ),
                    const SizedBox(height: 12),
                    _MoodDistributionCard(
                      isTr: isTr,
                      moodLog: moodLog,
                      labels: moodLabels,
                    ),
                    const SizedBox(height: 12),
                    _WeekdayCard(isTr: isTr, entryDays: entryDays),
                    const SizedBox(height: 12),
                    _CycleMoodCard(
                      isTr: isTr,
                      moodLog: moodLog,
                      periodDays: periodDays,
                    ),
                    const SizedBox(height: 12),
                    _JournalAnalysisCard(isTr: isTr, stats: textStats),
                    const SizedBox(height: 12),
                    const _AiAnalysisCard(),
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

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            // Translucent frosted glass so the mood photo shows through
            // instead of a solid white block.
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.isTr,
    required this.journaledDays,
    required this.streak,
    required this.dreams,
    required this.moods,
    required this.periodDays,
    required this.gratitude,
    required this.letters,
  });

  final bool isTr;
  final int journaledDays;
  final int streak;
  final int dreams;
  final int moods;
  final int periodDays;
  final int gratitude;
  final int letters;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        icon: Icons.edit_note_rounded,
        color: SakuraHomePalette.blossomPink,
        value: '$journaledDays',
        label: isTr ? 'günlük gün' : 'journaled',
      ),
      _StatTile(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF4A261),
        value: '$streak',
        label: isTr ? 'gün seri' : 'day streak',
      ),
      _StatTile(
        icon: Icons.nights_stay_rounded,
        color: const Color(0xFF8FA9D9),
        value: '$dreams',
        label: isTr ? 'rüya' : 'dreams',
      ),
      _StatTile(
        icon: Icons.insights_rounded,
        color: const Color(0xFF9FD8B0),
        value: '$moods',
        label: isTr ? 'ruh hali' : 'moods',
      ),
      _StatTile(
        icon: Icons.water_drop_rounded,
        color: _periodColor,
        value: '$periodDays',
        label: isTr ? 'regl günü' : 'period days',
      ),
      _StatTile(
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFFC4A5E8),
        value: '$gratitude',
        label: isTr ? 'şükran' : 'gratitude',
      ),
      _StatTile(
        icon: Icons.mail_rounded,
        color: const Color(0xFFE59BB0),
        value: '$letters',
        label: isTr ? 'mektup' : 'letters',
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Genel bakış' : 'Overview',
            style: AppTheme.displayFont(
              fontSize: 16,
              color: SakuraHomePalette.textDeep,
            ),
          ),
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
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          style: AppTheme.displayFont(fontSize: 20, color: SakuraHomePalette.textDeep),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyFont(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: SakuraHomePalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MoodDistributionCard extends StatelessWidget {
  const _MoodDistributionCard({
    required this.isTr,
    required this.moodLog,
    required this.labels,
  });

  final bool isTr;
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

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded,
                  size: 18, color: SakuraHomePalette.blossomPink),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Ruh hali dağılımı' : 'Mood distribution',
                style: AppTheme.displayFont(
                  fontSize: 16,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Text(
              isTr
                  ? 'Ana sayfada ruh halini seçtikçe dağılım burada oluşacak.'
                  : 'Pick your mood on Home to see the distribution here.',
              style: AppTheme.bodyFont(
                fontSize: 13,
                color: SakuraHomePalette.textMuted,
              ),
            )
          else ...[
            for (var i = 0; i < 5; i++) ...[
              _MoodRow(
                emoji: _moodEmojis[i],
                label: labels[i],
                color: _moodColors[i],
                fraction: total == 0 ? 0 : counts[i] / total,
                percent: total == 0 ? 0 : (counts[i] / total * 100).round(),
              ),
              if (i < 4) const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            if (mostIndex >= 0)
              Row(
                children: [
                  Text(_moodEmojis[mostIndex], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    isTr
                        ? 'En sık: ${labels[mostIndex]}'
                        : 'Most common: ${labels[mostIndex]}',
                    style: AppTheme.bodyFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SakuraHomePalette.textDeep,
                    ),
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
    required this.fraction,
    required this.percent,
  });

  final String emoji;
  final String label;
  final Color color;
  final double fraction;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 22, child: Text(emoji, style: const TextStyle(fontSize: 15))),
        const SizedBox(width: 6),
        SizedBox(
          width: 58,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyFont(
              fontSize: 12,
              color: SakuraHomePalette.textDeep,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: SakuraHomePalette.lavender,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '%$percent',
            textAlign: TextAlign.right,
            style: AppTheme.bodyFont(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.isTr, required this.entryDays});

  final bool isTr;
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

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 18, color: SakuraHomePalette.blossomPink),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Yazma alışkanlığı' : 'Writing habit',
                style: AppTheme.displayFont(
                  fontSize: 16,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
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
                        Text(
                          '${counts[i]}',
                          style: AppTheme.bodyFont(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: SakuraHomePalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 14,
                          height: maxCount == 0
                              ? 4
                              : 6 + (counts[i] / maxCount) * 60,
                          decoration: BoxDecoration(
                            color: SakuraHomePalette.blossomPink,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          labels[i],
                          style: AppTheme.bodyFont(
                            fontSize: 9.5,
                            color: SakuraHomePalette.textMuted,
                          ),
                        ),
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

class _CycleMoodCard extends StatelessWidget {
  const _CycleMoodCard({
    required this.isTr,
    required this.moodLog,
    required this.periodDays,
  });

  final bool isTr;
  final Map<DateTime, int> moodLog;
  final Set<DateTime> periodDays;

  @override
  Widget build(BuildContext context) {
    final onPeriod = <int>[];
    final offPeriod = <int>[];
    moodLog.forEach((day, index) {
      final score = _moodScores[index.clamp(0, 4)];
      if (periodDays.contains(day)) {
        onPeriod.add(score);
      } else {
        offPeriod.add(score);
      }
    });
    double? avg(List<int> l) =>
        l.isEmpty ? null : l.reduce((a, b) => a + b) / l.length;
    final avgOn = avg(onPeriod);
    final avgOff = avg(offPeriod);
    final hasBoth = avgOn != null && avgOff != null;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, size: 18, color: _periodColor),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Ruh hali & döngü' : 'Mood & cycle',
                style: AppTheme.displayFont(
                  fontSize: 16,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasBoth)
            Text(
              isTr
                  ? 'Hem regl günlerinde hem diğer günlerde ruh halini kaydettikçe, buradaki karşılaştırma oluşacak.'
                  : 'Log moods on both period and non-period days to see this comparison.',
              style: AppTheme.bodyFont(
                fontSize: 13,
                color: SakuraHomePalette.textMuted,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    color: _periodColor,
                    value: avgOn.toStringAsFixed(1),
                    label: isTr ? 'regl günü ort.' : 'period avg',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    color: SakuraHomePalette.blossomPink,
                    value: avgOff.toStringAsFixed(1),
                    label: isTr ? 'diğer günler ort.' : 'other days avg',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.displayFont(fontSize: 22, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyFont(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SakuraHomePalette.textMuted,
          ),
        ),
      ],
    );
  }
}

/// On-device journal analysis: entry/word counts and the most-used words.
class _JournalAnalysisCard extends StatelessWidget {
  const _JournalAnalysisCard({required this.isTr, required this.stats});

  final bool isTr;
  final JournalTextStats stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  size: 18, color: SakuraHomePalette.blossomPink),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Günlük analizi' : 'Journal analysis',
                style: AppTheme.displayFont(
                  fontSize: 16,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (stats.isEmpty)
            Text(
              isTr
                  ? 'Günlük yazdıkça yazı sayın, kelime sayın ve en çok kullandığın kelimeler burada görünecek.'
                  : 'As you journal, your entry count, word count and most-used words will appear here.',
              style: AppTheme.bodyFont(
                fontSize: 13,
                color: SakuraHomePalette.textMuted,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    color: SakuraHomePalette.blossomPink,
                    value: '${stats.entryCount}',
                    label: isTr ? 'yazı' : 'entries',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    color: const Color(0xFF9FD8B0),
                    value: '${stats.totalWords}',
                    label: isTr ? 'kelime' : 'words',
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    color: const Color(0xFF8FA9D9),
                    value: '${stats.avgWords.round()}',
                    label: isTr ? 'ort. kelime' : 'avg words',
                  ),
                ),
              ],
            ),
            if (stats.topWords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                isTr ? 'En çok kullandığın kelimeler' : 'Your most-used words',
                style: AppTheme.bodyFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SakuraHomePalette.textMuted,
                ),
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
                        color: SakuraHomePalette.lavender,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${w.$1} · ${w.$2}',
                        style: AppTheme.bodyFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SakuraHomePalette.textDeep,
                        ),
                      ),
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
  const _AiAnalysisCard();

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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: Color(0xFFC4A5E8)),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Luma ile analiz' : 'Analysis with Luma',
                style: AppTheme.displayFont(
                  fontSize: 16,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Bu analiz için son günlüklerin Luma\'ya (yapay zeka) gönderilir.'
                : 'Your recent entries are sent to Luma (AI) for this analysis.',
            style: AppTheme.bodyFont(
              fontSize: 11.5,
              color: SakuraHomePalette.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (_result != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: SakuraHomePalette.lavender,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _result!,
                style: AppTheme.bodyFont(
                  fontSize: 14,
                  color: SakuraHomePalette.textDeep,
                ).copyWith(height: 1.45),
              ),
            ),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                isTr
                    ? 'Analiz alınamadı. İnternetini kontrol edip tekrar dene.'
                    : "Couldn't get the analysis. Check your connection and try again.",
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  color: _periodColor,
                ),
              ),
            ),
          PremiumButton(
            label: _loading
                ? (isTr ? 'Analiz ediliyor...' : 'Analyzing...')
                : (isTr ? 'Luma ile analiz et' : 'Analyze with Luma'),
            icon: Icons.auto_awesome,
            loading: _loading,
            gradient: const [Color(0xFFC4A5E8), Color(0xFFDCC6F2)],
            onPressed: _loading ? null : _run,
          ),
        ],
      ),
    );
  }
}
