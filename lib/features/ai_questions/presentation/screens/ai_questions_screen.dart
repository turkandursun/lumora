import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/ai_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../../theme/app_background.dart';

const int _questionCount = 5;

const List<(String, List<String>)> _questionsTr = [
  ('Bugün enerjin nasıl?', ['Yüksek', 'Orta', 'Düşük', 'İnişli çıkışlı']),
  (
    'Son günlerde en çok hangi duyguyu yaşadın?',
    ['Mutluluk', 'Huzur', 'Kaygı', 'Üzüntü', 'Yorgunluk']
  ),
  ('Kendine ne kadar zaman ayırabildin?', ['Bolca', 'Biraz', 'Neredeyse hiç']),
  ('Uykun nasıldı?', ['İyi', 'İdare eder', 'Kötü']),
  (
    'Şu an en çok neye ihtiyacın var?',
    ['Dinlenmeye', 'Konuşmaya', 'Motivasyona', 'Anlaşılmaya']
  ),
  ('Bugün kendine karşı nasıldın?', ['Şefkatli', 'Nötr', 'Sert']),
  ('Zihnin bugün nasıl?', ['Sakin', 'Dağınık', 'Yoğun', 'Yorgun']),
  ('Bugün insanlarla ne kadar bağ kurdun?', ['Çok', 'Biraz', 'Yalnızdım']),
  ('Bedenin bugün nasıl hissediyor?', ['Dinç', 'İdare eder', 'Gergin', 'Yorgun']),
  ('Bugünü bir kelimeyle anlatsan?', ['Güzel', 'Sıradan', 'Zor', 'Karışık']),
  ('Stres seviyen bugün nasıl?', ['Düşük', 'Orta', 'Yüksek']),
  ('Yarına dair ne hissediyorsun?', ['Umutlu', 'Nötr', 'Endişeli']),
];

const List<(String, List<String>)> _questionsEn = [
  ('How is your energy today?', ['High', 'Medium', 'Low', 'Up and down']),
  (
    'Which emotion have you felt most lately?',
    ['Happiness', 'Calm', 'Anxiety', 'Sadness', 'Tiredness']
  ),
  ('How much time did you make for yourself?', ['Plenty', 'A little', 'Almost none']),
  ('How was your sleep?', ['Good', 'Okay', 'Poor']),
  (
    'What do you need most right now?',
    ['Rest', 'To talk', 'Motivation', 'To be understood']
  ),
  ('How were you toward yourself today?', ['Kind', 'Neutral', 'Harsh']),
  ('How is your mind today?', ['Calm', 'Scattered', 'Busy', 'Tired']),
  ('How connected did you feel with people today?', ['A lot', 'A little', 'I felt alone']),
  ('How does your body feel today?', ['Fresh', 'Okay', 'Tense', 'Tired']),
  ('If you described today in one word?', ['Nice', 'Ordinary', 'Hard', 'Mixed']),
  ('How is your stress today?', ['Low', 'Medium', 'High']),
  ('How do you feel about tomorrow?', ['Hopeful', 'Neutral', 'Anxious']),
];

class AiQuestionsScreen extends ConsumerStatefulWidget {
  const AiQuestionsScreen({super.key});

  @override
  ConsumerState<AiQuestionsScreen> createState() => _AiQuestionsScreenState();
}

class _AiQuestionsScreenState extends ConsumerState<AiQuestionsScreen> {
  // A fresh random subset of questions each time the screen opens.
  late final List<int> _order =
      (List<int>.generate(_questionsTr.length, (i) => i)..shuffle())
          .take(_questionCount)
          .toList();
  final List<int?> _selected = List<int?>.filled(_questionCount, null);
  bool _loading = false;
  String? _analysis;
  bool _offline = false;

  bool get _allAnswered => _selected.every((e) => e != null);

  Future<void> _analyze() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final qs = isTr ? _questionsTr : _questionsEn;
    final lines = <String>[];
    for (var i = 0; i < _order.length; i++) {
      final sel = _selected[i];
      if (sel != null) {
        lines.add('${qs[_order[i]].$1} -> ${qs[_order[i]].$2[sel]}');
      }
    }
    final summary = lines.join('\n');

    setState(() {
      _loading = true;
      _offline = false;
      _analysis = null;
    });

    final message = isTr
        ? 'Kısa bir öz-değerlendirme doldurdum. Cevaplarım:\n$summary\n\nRuh halime dair kısa, sıcak ve destekleyici bir analiz ve küçük bir öneri yaz.'
        : 'I filled a short self-check. My answers:\n$summary\n\nWrite a short, warm, supportive analysis of my mood and one small suggestion.';

    try {
      final reply = await AiService().sendLumaMessage(
        message: message,
        language: isTr ? 'tr' : 'en',
      );
      if (!mounted) return;
      setState(() {
        _analysis = reply.trim();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analysis = isTr
            ? 'Şu an analize ulaşılamadı (internet gerekebilir). Yine de bu değerlendirmeyi doldurman, kendine kulak vermenin güzel bir yolu. 🌸'
            : "Couldn't reach the analysis right now (you may need internet). Still, checking in with yourself this way is a lovely thing to do. 🌸";
        _offline = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final qs = isTr ? _questionsTr : _questionsEn;

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
                      isTr ? 'AI Soruları' : 'AI Questions',
                      style: AppTheme.displayFont(
                          fontSize: 22, color: SakuraHomePalette.textDeep),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _FrostedCard(
                        child: Text(
                          isTr
                              ? 'Birkaç soruyu yanıtla, Luma ruh haline dair kısa bir analiz yapsın.'
                              : 'Answer a few questions and Luma will give a short read on your mood.',
                          style: AppTheme.bodyFont(
                            fontSize: 13.5,
                            color: SakuraHomePalette.textDeep,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _order.length; i++) ...[
                        _QuestionCard(
                          index: i,
                          question: qs[_order[i]].$1,
                          options: qs[_order[i]].$2,
                          selected: _selected[i],
                          onSelect: (opt) => setState(() => _selected[i] = opt),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _AnalyzeButton(
                        isTr: isTr,
                        enabled: _allAnswered && !_loading,
                        loading: _loading,
                        onTap: _analyze,
                      ),
                      if (_analysis != null) ...[
                        const SizedBox(height: 14),
                        _AnalysisCard(
                          isTr: isTr,
                          text: _analysis!,
                          offline: _offline,
                        ),
                      ],
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

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});

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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final String question;
  final List<String> options;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return _FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $question',
            style: AppTheme.bodyFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var o = 0; o < options.length; o++)
                ChoiceChip(
                  label: Text(options[o]),
                  labelStyle: AppTheme.bodyFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected == o ? Colors.white : SakuraHomePalette.textDeep,
                  ),
                  showCheckmark: false,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  selectedColor: SakuraHomePalette.blossomPink,
                  selected: selected == o,
                  onSelected: (_) => onSelect(o),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({
    required this.isTr,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool isTr;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumButton(
      label: loading
          ? (isTr ? 'Analiz ediliyor...' : 'Analyzing...')
          : (isTr ? 'Luma ile analiz et' : 'Analyze with Luma'),
      icon: Icons.auto_awesome,
      loading: loading,
      gradient: const [Color(0xFFA678D6), Color(0xFFC9A9E9)],
      onPressed: enabled ? onTap : null,
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.isTr,
    required this.text,
    required this.offline,
  });

  final bool isTr;
  final String text;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return _FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, size: 18, color: Color(0xFFA678D6)),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Luma\'nın analizi' : "Luma's analysis",
                style: AppTheme.bodyFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: SakuraHomePalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: AppTheme.bodyFont(
              fontSize: 14.5,
              color: SakuraHomePalette.textDeep,
            ).copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
