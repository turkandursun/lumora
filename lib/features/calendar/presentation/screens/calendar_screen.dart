import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../../theme/mood_gradients.dart';
import '../../../profile/presentation/providers/visit_tracker_providers.dart';
import '../providers/calendar_providers.dart';

/// Positivity score per AppMood index (order: happy, calm, tired, sad,
/// anxious) — higher reads as a better day on the mood chart.
const List<int> _moodScores = [5, 4, 3, 1, 2];
const List<Color> _moodColors = [
  Color(0xFFF4C95D), // happy
  Color(0xFF9FD8B0), // calm
  Color(0xFFB9A7E0), // tired
  Color(0xFF8FA9D9), // sad
  Color(0xFFE59BB0), // anxious
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Month-view calendar: marks the days that have a journal entry and lets the
/// user tag menstruation days. Tapping a day opens a small sheet with that
/// day's summary and a period toggle.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  bool _isTr(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'tr';

  void _openDaySheet(DateTime day, bool hasEntry, bool isDark, Color primary) {
    final isTr = _isTr(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(
        builder: (context, ref, __) {
          final moodIdx = ref.watch(moodLogProvider)[_dateOnly(day)];
          final dateLabel = DateFormat(
            'd MMMM yyyy · EEEE',
            Localizations.localeOf(context).languageCode,
          ).format(day);
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              child: AstraGlassCard(
                isDark: isDark,
                primaryColor: primary,
                borderRadius: 24,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateLabel, style: AstraKit.heading2(isDark, fontSize: 17)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          hasEntry ? Icons.edit_note_rounded : Icons.remove_rounded,
                          size: 18,
                          color: hasEntry ? primary : AstraKit.muted(isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasEntry
                              ? (isTr ? 'Bu gün günlük yazdın' : 'You journaled this day')
                              : (isTr ? 'Günlük kaydı yok' : 'No journal entry'),
                          style: AstraKit.mutedText(isDark, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isTr ? 'Bugünkü ruh halin' : 'Mood for this day',
                      style: AstraKit.mutedText(isDark, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var m = 0; m < moodSymbolIcons.length; m++)
                          GestureDetector(
                            onTap: () {
                              if (moodIdx == m) {
                                ref.read(moodLogProvider.notifier).clearForDay(day);
                              } else {
                                ref.read(moodLogProvider.notifier).setForDay(day, m);
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: moodIdx == m
                                    ? moodSymbolColors[m]
                                    : moodSymbolColors[m].withValues(alpha: 0.16),
                                border: Border.all(
                                  color: moodIdx == m ? moodSymbolColors[m] : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                moodSymbolIcons[m],
                                size: 20,
                                color: moodIdx == m ? Colors.white : moodSymbolColors[m],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = _isTr(context);
    final locale = Localizations.localeOf(context).languageCode;
    final entryDays = ref.watch(journalEntryDaysProvider).valueOrNull ?? const {};
    final streak = ref.watch(visitDaysCountProvider).valueOrNull ?? 0;
    final moodLog = ref.watch(moodLogProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);
    final journaledThisMonth = entryDays
        .where((d) => d.year == _visibleMonth.year && d.month == _visibleMonth.month)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isTr ? 'Takvim' : 'Calendar',
                      style: AstraKit.heading1(isDark, fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _MonthCard(
                          month: _visibleMonth,
                          locale: locale,
                          entryDays: entryDays,
                          moodLog: moodLog,
                          isDark: isDark,
                          primary: primary,
                          onPrev: () => _changeMonth(-1),
                          onNext: () => _changeMonth(1),
                          onDayTap: (day, hasEntry) => _openDaySheet(day, hasEntry, isDark, primary),
                        ),
                        const SizedBox(height: 14),
                        _Legend(isTr: isTr, isDark: isDark, primary: primary),
                        const SizedBox(height: 16),
                        _MonthlySummaryCard(
                          month: _visibleMonth,
                          locale: locale,
                          isTr: isTr,
                          journaledDays: journaledThisMonth,
                          streak: streak,
                          isDark: isDark,
                          primary: primary,
                        ),
                        const SizedBox(height: 12),
                        _MoodChartCard(moodLog: moodLog, isTr: isTr, isDark: isDark, primary: primary),
                        const SizedBox(height: 8),
                      ],
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

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.month,
    required this.locale,
    required this.entryDays,
    required this.moodLog,
    required this.isDark,
    required this.primary,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });

  final DateTime month;
  final String locale;
  final Set<DateTime> entryDays;
  final Map<DateTime, int> moodLog;
  final bool isDark;
  final Color primary;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime day, bool hasEntry) onDayTap;

  @override
  Widget build(BuildContext context) {
    final isTr = locale == 'tr';
    final weekdayLabels = isTr
        ? const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1 -> 0 blanks
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = _dateOnly(DateTime.now());

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final hasEntry = entryDays.contains(day);
      cells.add(_DayCell(
        day: d,
        isToday: day == today,
        hasEntry: hasEntry,
        moodIndex: moodLog[day],
        isDark: isDark,
        primary: primary,
        onTap: () => onDayTap(day, hasEntry),
      ));
    }

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrev,
                icon: Icon(Icons.chevron_left_rounded, color: primary),
              ),
              Text(
                DateFormat.yMMMM(locale).format(month),
                style: AstraKit.heading2(isDark, fontSize: 17),
              ),
              IconButton(
                onPressed: onNext,
                icon: Icon(Icons.chevron_right_rounded, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final label in weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AstraKit.mutedText(isDark, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasEntry,
    required this.moodIndex,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool hasEntry;
  final int? moodIndex;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMood = moodIndex != null &&
        moodIndex! >= 0 &&
        moodIndex! < moodSymbolIcons.length;

    // A day tagged with a mood fills its whole circle with that mood's
    // colour + weather symbol — these stay the mood system's own colors so
    // the meaning (which mood) doesn't change with the app theme.
    final Color fill = hasMood ? moodSymbolColors[moodIndex!] : Colors.transparent;
    final bool filled = hasMood;
    final Color textColor = filled ? Colors.white : AstraKit.ink(isDark);

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: isToday && !filled
                  ? Border.all(color: primary, width: 1.4)
                  : (isToday && filled ? Border.all(color: Colors.white, width: 1.4) : null),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasMood) ...[
                  // Whole-circle mood: big symbol centred, day number small on top.
                  Icon(moodSymbolIcons[moodIndex!], size: 22, color: Colors.white),
                  Positioned(
                    top: 1,
                    child: Text(
                      '$day',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ] else
                  Text(
                    '$day',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                if (hasEntry)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? Colors.white : primary,
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

class _Legend extends StatelessWidget {
  const _Legend({required this.isTr, required this.isDark, required this.primary});

  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    Widget item(Widget swatch, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 6),
            Text(label, style: AstraKit.mutedText(isDark, fontSize: 12)),
          ],
        );

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        item(
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: primary),
          ),
          isTr ? 'Günlük yazıldı' : 'Journaled',
        ),
        item(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary, width: 1.6),
            ),
          ),
          isTr ? 'Bugün' : 'Today',
        ),
      ],
    );
  }
}

/// "This month" summary: journaled days and current streak.
class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.month,
    required this.locale,
    required this.isTr,
    required this.journaledDays,
    required this.streak,
    required this.isDark,
    required this.primary,
  });

  final DateTime month;
  final String locale;
  final bool isTr;
  final int journaledDays;
  final int streak;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr
                ? 'Bu ay · ${DateFormat.MMMM(locale).format(month)}'
                : 'This month · ${DateFormat.MMMM(locale).format(month)}',
            style: AstraKit.heading2(isDark, fontSize: 16),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  icon: Icons.edit_note_rounded,
                  color: primary,
                  value: '$journaledDays',
                  label: isTr ? 'günlük gün' : 'journaled',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _StatBlock(
                  icon: Icons.local_fire_department_rounded,
                  color: primary,
                  value: '$streak',
                  label: isTr ? 'gün seri' : 'day streak',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: AstraKit.heading1(isDark, fontSize: 20)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(isDark, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// A simple 14-day mood bar chart, coloured by the mood logged each day.
class _MoodChartCard extends StatelessWidget {
  const _MoodChartCard({
    required this.moodLog,
    required this.isTr,
    required this.isDark,
    required this.primary,
  });

  final Map<DateTime, int> moodLog;
  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));
    final hasAny = days.any(moodLog.containsKey);

    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Ruh hali · son 14 gün' : 'Mood · last 14 days',
                style: AstraKit.heading2(isDark, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [for (final d in days) Expanded(child: _bar(d, isDark))],
            ),
          ),
          if (!hasAny) ...[
            const SizedBox(height: 10),
            Text(
              isTr
                  ? 'Ana sayfada ruh halini seçtikçe burada grafik oluşacak.'
                  : 'Pick your mood on Home and this chart will fill in.',
              style: AstraKit.mutedText(isDark, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(DateTime day, bool isDark) {
    final has = moodLog.containsKey(day);
    final index = has ? moodLog[day]!.clamp(0, 4) : 0;
    final score = has ? _moodScores[index] : 0;
    final height = has ? (8 + score / 5 * 68) : 4.0;
    final color = has ? _moodColors[index] : AstraKit.muted(isDark).withValues(alpha: 0.25);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 9,
          height: height.toDouble(),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 4),
        Text('${day.day}', style: AstraKit.mutedText(isDark, fontSize: 8)),
      ],
    );
  }
}
