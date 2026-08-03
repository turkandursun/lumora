import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../theme/astra_screen_kit.dart';

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
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final qs = isTr ? _questionsTr : _questionsEn;
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

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
                    Text(isTr ? 'AI Soruları' : 'AI Questions', style: AstraKit.heading1(isDark, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      AstraGlassCard(
                        isDark: isDark,
                        primaryColor: primary,
                        child: Text(
                          isTr
                              ? 'Birkaç soruyu yanıtla, Luma ruh haline dair kısa bir analiz yapsın.'
                              : 'Answer a few questions and Luma will give a short read on your mood.',
                          style: AstraKit.body(isDark, fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _order.length; i++) ...[
                        _QuestionCard(
                          index: i,
                          question: qs[_order[i]].$1,
                          options: qs[_order[i]].$2,
                          selected: _selected[i],
                          isDark: isDark,
                          primary: primary,
                          onSelect: (opt) => setState(() => _selected[i] = opt),
                        ),
                        const SizedBox(height: 12),
                      ],
                      AstraGoldButton(
                        isDark: isDark,
                        label: _loading
                            ? (isTr ? 'Analiz ediliyor...' : 'Analyzing...')
                            : (isTr ? 'Luma ile analiz et' : 'Analyze with Luma'),
                        icon: Icons.auto_awesome,
                        isLoading: _loading,
                        enabled: _allAnswered && !_loading,
                        onTap: _analyze,
                      ),
                      if (_analysis != null) ...[
                        const SizedBox(height: 14),
                        _AnalysisCard(isTr: isTr, text: _analysis!, isDark: isDark, primary: primary),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.options,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onSelect,
  });

  final int index;
  final String question;
  final List<String> options;
  final int? selected;
  final bool isDark;
  final Color primary;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. $question', style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var o = 0; o < options.length; o++)
                ChoiceChip(
                  label: Text(options[o]),
                  labelStyle: AstraKit.body(isDark, fontSize: 12.5, fontWeight: FontWeight.w600,
                      color: selected == o ? const Color(0xFF1A0F00) : null),
                  showCheckmark: false,
                  backgroundColor: isDark ? const Color(0x33231845) : const Color(0x66FFF8EE),
                  selectedColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
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

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.isTr,
    required this.text,
    required this.isDark,
    required this.primary,
  });

  final bool isTr;
  final String text;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_rounded, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(isTr ? 'Luma\'nın analizi' : "Luma's analysis", style: AstraKit.label(isDark, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: AstraKit.body(isDark, fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.45)),
        ],
      ),
    );
  }
}
