import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../data/gratitude_repository.dart';
import '../providers/gratitude_providers.dart';

/// Rotating daily prompts to inspire the day's gratitude (tr, en).
const List<(String, String)> _prompts = [
  ('Bugün seni gülümseten kimdi?', 'Who made you smile today?'),
  ('Sahip olduğun küçük bir konfor ne?', "What's a small comfort you have?"),
  ('Bugün işine yarayan bir şey neydi?', 'What helped you today?'),
  ('Minnettar olduğun bir kişi kim?', "Who's someone you're grateful for?"),
  ('Bedeninin yapabildiği ne için teşekkür edersin?',
      'What can your body do that you thank it for?'),
  ('Bugün fark ettiğin güzel bir detay neydi?',
      'What lovely detail did you notice today?'),
  ('Seni destekleyen biri kim?', "Who's been supporting you?"),
  ('Son zamanlarda öğrendiğin bir şey ne?',
      'What have you learned lately?'),
  ('Evinde sevdiğin bir köşe neresi?',
      "What's a corner of your home you love?"),
  ('Bugün tadını çıkardığın bir an neydi?',
      'What moment did you savor today?'),
  ('Geçmişte verdiğin iyi bir karar neydi?',
      'What good decision did you once make?'),
  ('Doğada seni huzurlandıran ne?',
      'What in nature brings you peace?'),
];

const List<String> _moodOptions = [
  '😊', '🥰', '😌', '🙏', '✨', '🌷', '💪', '😴',
];

class GratitudeScreen extends ConsumerStatefulWidget {
  const GratitudeScreen({super.key});

  @override
  ConsumerState<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends ConsumerState<GratitudeScreen> {
  final _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool _prefilled = false;
  String? _mood;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefillFromToday(List<GratitudeEntry> entries) {
    if (_prefilled) return;
    _prefilled = true;
    final today = GratitudeRepository.dateOnly(DateTime.now());
    final todays = entries
        .where((e) =>
            e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day)
        .toList();
    if (todays.isEmpty) return;
    final entry = todays.first;
    for (var i = 0; i < _controllers.length && i < entry.items.length; i++) {
      _controllers[i].text = entry.items[i];
    }
    _mood = entry.mood;
  }

  /// A stable "memory" for today: a random past entry (not today's), picked
  /// deterministically per day so it doesn't jump around on rebuilds.
  GratitudeEntry? _memoryOf(List<GratitudeEntry> entries) {
    final today = GratitudeRepository.dateOnly(DateTime.now());
    final past = entries
        .where((e) => !(e.date.year == today.year &&
            e.date.month == today.month &&
            e.date.day == today.day))
        .toList();
    if (past.isEmpty) return null;
    final seed = today.year * 1000 + today.month * 50 + today.day;
    return past[Random(seed).nextInt(past.length)];
  }

  Future<void> _save() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    await ref
        .read(gratitudeProvider.notifier)
        .saveToday(_controllers.map((c) => c.text).toList(), mood: _mood);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isTr ? 'Kaydedildi 🌸' : 'Saved 🌸')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final locale = Localizations.localeOf(context).languageCode;
    final entries = ref.watch(gratitudeProvider);
    _prefillFromToday(entries);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    final streak = gratitudeStreak(entries);
    final memory = _memoryOf(entries);
    final promptIndex =
        DateTime.now().difference(DateTime(2020)).inDays % _prompts.length;
    final prompt = isTr ? _prompts[promptIndex].$1 : _prompts[promptIndex].$2;

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
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(isTr ? 'Şükran Günlüğü' : 'Gratitude', style: AstraKit.heading1(isDark, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _StreakCard(isTr: isTr, isDark: isDark, primary: primary, streak: streak, total: entries.length),
                      const SizedBox(height: 14),
                      _PromptCard(isTr: isTr, isDark: isDark, primary: primary, prompt: prompt),
                      const SizedBox(height: 14),
                      _InputCard(
                        isTr: isTr,
                        isDark: isDark,
                        primary: primary,
                        controllers: _controllers,
                        mood: _mood,
                        onMoodSelected: (m) => setState(() => _mood = _mood == m ? null : m),
                        onSave: _save,
                      ),
                      const SizedBox(height: 18),
                      if (memory != null) ...[
                        _MemoryCard(entry: memory, locale: locale, isTr: isTr, isDark: isDark, primary: primary),
                        const SizedBox(height: 18),
                      ],
                      if (entries.isNotEmpty)
                        Text(isTr ? 'Geçmiş' : 'History', style: AstraKit.heading2(isDark, fontSize: 16)),
                      const SizedBox(height: 8),
                      for (final entry in entries)
                        _HistoryCard(entry: entry, locale: locale, isDark: isDark, primary: primary),
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

/// Streak + total-days summary.
class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.streak,
    required this.total,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final int streak;
  final int total;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.18),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.local_fire_department_rounded, color: primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              streak > 0
                  ? (isTr ? '$streak gündür şükran yazıyorsun 🌸' : "$streak-day gratitude streak 🌸")
                  : (isTr ? 'Bugün ilk şükranını yaz' : 'Write your first gratitude today'),
              style: AstraKit.body(isDark, fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
          ),
          Column(
            children: [
              Text('$total', style: AstraKit.heading1(isDark, fontSize: 20)),
              Text(isTr ? 'gün' : 'days', style: AstraKit.mutedText(isDark, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The rotating daily prompt.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.isTr, required this.isDark, required this.primary, required this.prompt});

  final bool isTr;
  final bool isDark;
  final Color primary;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isTr ? 'Bugünün ilhamı' : "Today's prompt", style: AstraKit.label(isDark, fontSize: 11.5)),
                const SizedBox(height: 3),
                Text(prompt, style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.controllers,
    required this.mood,
    required this.onMoodSelected,
    required this.onSave,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final List<TextEditingController> controllers;
  final String? mood;
  final ValueChanged<String> onMoodSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Bugün minnettar olduğun şeyler' : "Things you're grateful for today",
            style: AstraKit.heading2(isDark, fontSize: 16),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < controllers.length; i++) ...[
            TextField(
              controller: controllers[i],
              style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w500),
              cursorColor: primary,
              decoration: InputDecoration(
                hintText: isTr ? '${i + 1}. ...' : '${i + 1}. ...',
                hintStyle: AstraKit.mutedText(isDark, fontSize: 14),
                filled: true,
                fillColor: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
            if (i < controllers.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          Text(isTr ? 'Bugün nasıl hissettin?' : 'How did you feel?', style: AstraKit.body(isDark, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _moodOptions)
                GestureDetector(
                  onTap: () => onMoodSelected(m),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mood == m ? primary.withValues(alpha: 0.22) : (isDark ? const Color(0x33231845) : const Color(0x55FFF8EE)),
                      border: Border.all(color: mood == m ? primary : Colors.transparent, width: 2),
                    ),
                    child: Text(m, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AstraGoldButton(isDark: isDark, label: isTr ? 'Kaydet' : 'Save', icon: Icons.favorite_rounded, onTap: onSave),
        ],
      ),
    );
  }
}

/// "A moment from the past" — resurfaces a random earlier entry.
class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.entry,
    required this.locale,
    required this.isTr,
    required this.isDark,
    required this.primary,
  });

  final GratitudeEntry entry;
  final String locale;
  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(isTr ? 'Geçmişten bir an' : 'A moment from the past', style: AstraKit.body(isDark, fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (entry.mood != null) Text(entry.mood!, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 6),
          Text(DateFormat('d MMMM yyyy', locale).format(entry.date), style: AstraKit.mutedText(isDark, fontSize: 11.5)),
          const SizedBox(height: 8),
          for (final item in entry.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌸  ', style: TextStyle(fontSize: 12)),
                  Expanded(child: Text(item, style: AstraKit.body(isDark, fontSize: 13.5, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.locale, required this.isDark, required this.primary});

  final GratitudeEntry entry;
  final String locale;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('d MMMM yyyy', locale).format(entry.date),
                  style: AstraKit.body(isDark, fontSize: 12.5, fontWeight: FontWeight.w700, color: primary),
                ),
                const Spacer(),
                if (entry.mood != null) Text(entry.mood!, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in entry.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌸  ', style: TextStyle(fontSize: 12)),
                    Expanded(child: Text(item, style: AstraKit.body(isDark, fontSize: 13.5, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
