import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/mood_gradients.dart';
import '../../domain/weekly_summary.dart';
import '../providers/weekly_summary_provider.dart';

/// "Bu hafta" — a personal weekly snapshot the user can read at a glance and
/// share as an image.
class WeeklySummaryCard extends ConsumerStatefulWidget {
  const WeeklySummaryCard({super.key});

  @override
  ConsumerState<WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends ConsumerState<WeeklySummaryCard> {
  final _shotKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(bool isTr) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _shotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final png = data.buffer.asUint8List();
      // XFile.fromData works on web and mobile alike (no dart:io / temp file).
      final file = XFile.fromData(png,
          mimeType: 'image/png', name: 'astra_week.png');
      await Share.shareXFiles([file],
          text: isTr ? 'ASTRA · Bu haftam 🌸' : 'ASTRA · My week 🌸');
    } catch (_) {
      // Sharing is a nicety; never crash the screen.
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final s = ref.watch(weeklySummaryProvider);
    // Brightness-adjusted palette so the card background is dark in dark theme
    // (otherwise the theme's light text is invisible on a light card).
    final palette = AstraKit.palette(context);
    final isDark = AstraKit.tokens(context).isDark;
    final primary = AstraKit.primary(context, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The capture area — a self-contained gradient card so the shared PNG
        // looks good on its own.
        RepaintBoundary(
          key: _shotKey,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.surfaceElevated, palette.gradientBottom],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.softBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('✦',
                        style: TextStyle(
                            color: primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Text(isTr ? 'Bu hafta' : 'This week',
                        style: AstraKit.heading1(context, false, fontSize: 20)),
                    const Spacer(),
                    Text('ASTRA',
                        style: AstraKit.mutedText(context, false, fontSize: 11)
                            .copyWith(letterSpacing: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                if (s.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      isTr
                          ? 'Bu hafta henüz veri yok. Bir ruh hali seç ya da birkaç satır yaz — burası dolmaya başlasın. 🌸'
                          : 'No data yet this week. Log a mood or write a few lines — this will start filling in. 🌸',
                      style: AstraKit.body(context, false, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  )
                else ...[
                  _StatLine(
                    emoji: '📝',
                    text: isTr
                        ? '7 günün ${s.daysJournaled}\'inde yazdın'
                        : 'You wrote on ${s.daysJournaled} of 7 days',
                  ),
                  if (s.topMood != null)
                    _StatLine(
                      emoji: _moodEmoji(s.topMood!),
                      text: isTr
                          ? 'En çok: ${_moodLabel(s.topMood!, true)}'
                          : 'Most felt: ${_moodLabel(s.topMood!, false)}',
                    ),
                  if (s.lowestDayWeekday != null)
                    _StatLine(
                      emoji: '🌧️',
                      text: isTr
                          ? 'En zor gün: ${_weekday(s.lowestDayWeekday!, true)}'
                          : 'Hardest day: ${_weekday(s.lowestDayWeekday!, false)}',
                    ),
                  if (s.streak > 0)
                    _StatLine(
                      emoji: '🔥',
                      text: isTr
                          ? '${s.streak} günlük seri'
                          : '${s.streak}-day streak',
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _sharing ? null : () => _share(isTr),
            icon: Icon(Icons.ios_share_rounded, size: 18, color: primary),
            label: Text(
              isTr ? 'Paylaş' : 'Share',
              style: AstraKit.body(context, false, fontSize: 13.5, fontWeight: FontWeight.w700)
                  .copyWith(color: primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.emoji, required this.text});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: AstraKit.body(context, false,
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

String _moodLabel(AppMood m, bool isTr) => switch (m) {
      AppMood.happy => isTr ? 'Mutlu' : 'Happy',
      AppMood.calm => isTr ? 'Sakin' : 'Calm',
      AppMood.tired => isTr ? 'Yorgun' : 'Tired',
      AppMood.sad => isTr ? 'Üzgün' : 'Sad',
      AppMood.anxious => isTr ? 'Endişeli' : 'Anxious',
    };

String _moodEmoji(AppMood m) => switch (m) {
      AppMood.happy => '😊',
      AppMood.calm => '😌',
      AppMood.tired => '😴',
      AppMood.sad => '😢',
      AppMood.anxious => '😰',
    };

String _weekday(int w, bool isTr) {
  const tr = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  const en = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final i = (w - 1).clamp(0, 6);
  return (isTr ? tr : en)[i];
}
