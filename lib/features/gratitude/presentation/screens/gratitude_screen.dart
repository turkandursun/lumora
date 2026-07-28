import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
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

    final streak = gratitudeStreak(entries);
    final memory = _memoryOf(entries);
    final promptIndex =
        DateTime.now().difference(DateTime(2020)).inDays % _prompts.length;
    final prompt = isTr ? _prompts[promptIndex].$1 : _prompts[promptIndex].$2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: SakuraHomePalette.textDeep),
                    ),
                    Text(
                      isTr ? 'Şükran Günlüğü' : 'Gratitude',
                      style: AppTheme.displayFont(
                        fontSize: 22,
                        color: SakuraHomePalette.textDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _StreakCard(
                        isTr: isTr,
                        streak: streak,
                        total: entries.length,
                      ),
                      const SizedBox(height: 14),
                      _PromptCard(isTr: isTr, prompt: prompt),
                      const SizedBox(height: 14),
                      _InputCard(
                        isTr: isTr,
                        controllers: _controllers,
                        mood: _mood,
                        onMoodSelected: (m) => setState(
                            () => _mood = _mood == m ? null : m),
                        onSave: _save,
                      ),
                      const SizedBox(height: 18),
                      if (memory != null) ...[
                        _MemoryCard(entry: memory, locale: locale, isTr: isTr),
                        const SizedBox(height: 18),
                      ],
                      if (entries.isNotEmpty)
                        Text(
                          isTr ? 'Geçmiş' : 'History',
                          style: AppTheme.displayFont(
                            fontSize: 16,
                            color: SakuraHomePalette.textDeep,
                          ),
                        ),
                      const SizedBox(height: 8),
                      for (final entry in entries)
                        _HistoryCard(entry: entry, locale: locale),
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
    required this.streak,
    required this.total,
  });

  final bool isTr;
  final int streak;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: SakuraHomePalette.ctaGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.blossomPink.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.28),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              streak > 0
                  ? (isTr
                      ? '$streak gündür şükran yazıyorsun 🌸'
                      : "$streak-day gratitude streak 🌸")
                  : (isTr
                      ? 'Bugün ilk şükranını yaz'
                      : 'Write your first gratitude today'),
              style: AppTheme.bodyFont(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                '$total',
                style:
                    AppTheme.displayFont(fontSize: 20, color: Colors.white),
              ),
              Text(
                isTr ? 'gün' : 'days',
                style: AppTheme.bodyFont(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The rotating daily prompt.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.isTr, required this.prompt});

  final bool isTr;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: SakuraHomePalette.lavender,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: SakuraHomePalette.blossomPink.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 18, color: SakuraHomePalette.blossomPink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Bugünün ilhamı' : "Today's prompt",
                  style: AppTheme.bodyFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SakuraHomePalette.blossomPink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  prompt,
                  style: AppTheme.bodyFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SakuraHomePalette.textDeep,
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

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.isTr,
    required this.controllers,
    required this.mood,
    required this.onMoodSelected,
    required this.onSave,
  });

  final bool isTr;
  final List<TextEditingController> controllers;
  final String? mood;
  final ValueChanged<String> onMoodSelected;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr
                ? 'Bugün minnettar olduğun şeyler'
                : "Things you're grateful for today",
            style: AppTheme.displayFont(
              fontSize: 16,
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < controllers.length; i++) ...[
            TextField(
              controller: controllers[i],
              style: AppTheme.bodyFont(
                fontSize: 14,
                color: SakuraHomePalette.textDeep,
              ),
              cursorColor: SakuraHomePalette.blossomPink,
              decoration: InputDecoration(
                hintText: isTr ? '${i + 1}. ...' : '${i + 1}. ...',
                hintStyle: AppTheme.bodyFont(
                  fontSize: 14,
                  color: SakuraHomePalette.textMuted,
                ),
                filled: true,
                fillColor: SakuraHomePalette.lavender,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (i < controllers.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          Text(
            isTr ? 'Bugün nasıl hissettin?' : 'How did you feel?',
            style: AppTheme.bodyFont(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textDeep,
            ),
          ),
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
                      color: mood == m
                          ? SakuraHomePalette.blossomPink.withValues(alpha: 0.22)
                          : SakuraHomePalette.lavender,
                      border: Border.all(
                        color: mood == m
                            ? SakuraHomePalette.blossomPink
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(m, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          PremiumButton(
            label: isTr ? 'Kaydet' : 'Save',
            icon: Icons.favorite_rounded,
            onPressed: onSave,
          ),
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
  });

  final GratitudeEntry entry;
  final String locale;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SakuraHomePalette.blush,
            SakuraHomePalette.lavender,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 18, color: SakuraHomePalette.branchMauve),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Geçmişten bir an' : 'A moment from the past',
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SakuraHomePalette.textDeep,
                ),
              ),
              const Spacer(),
              if (entry.mood != null)
                Text(entry.mood!, style: const TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('d MMMM yyyy', locale).format(entry.date),
            style: AppTheme.bodyFont(
              fontSize: 11.5,
              color: SakuraHomePalette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in entry.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌸  ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTheme.bodyFont(
                        fontSize: 13.5,
                        color: SakuraHomePalette.textDeep,
                      ),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.locale});

  final GratitudeEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('d MMMM yyyy', locale).format(entry.date),
                style: AppTheme.bodyFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SakuraHomePalette.blossomPink,
                ),
              ),
              const Spacer(),
              if (entry.mood != null)
                Text(entry.mood!, style: const TextStyle(fontSize: 16)),
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
                  Expanded(
                    child: Text(
                      item,
                      style: AppTheme.bodyFont(
                        fontSize: 13.5,
                        color: SakuraHomePalette.textDeep,
                      ),
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
