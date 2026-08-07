import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/daily_ai_questions_service.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/mood_gradients.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../../mood/presentation/providers/mood_providers.dart';

class AiQuestionsScreen extends ConsumerStatefulWidget {
  const AiQuestionsScreen({super.key});

  @override
  ConsumerState<AiQuestionsScreen> createState() => _AiQuestionsScreenState();
}

class _AiQuestionsScreenState extends ConsumerState<AiQuestionsScreen> {
  List<String> _questions = const [];
  List<String> _answers = const [];
  bool _questionsRequested = false;
  bool _questionsLoading = true;
  String? _questionsError;
  bool _loading = false;
  String? _analysis;

  bool get _hasAnswer => _answers.any((answer) => answer.trim().isNotEmpty);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_questionsRequested) return;
    _questionsRequested = true;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    setState(() {
      _questionsLoading = true;
      _questionsError = null;
    });

    try {
      List<JournalEntryRow> journals = const [];
      List<DreamRow> dreams = const [];
      try {
        journals = await ref.read(recentJournalEntriesProvider.future);
      } catch (_) {}
      try {
        dreams = await ref.read(dreamsStreamProvider.future);
      } catch (_) {}
      if (!mounted) return;

      final moodLog = ref.read(moodLogProvider);
      MapEntry<DateTime, int>? latestMood;
      for (final entry in moodLog.entries) {
        if (latestMood == null || entry.key.isAfter(latestMood.key)) {
          latestMood = entry;
        }
      }

      final questions = await DailyAiQuestionsService().fetchQuestions(
        language: isTr ? 'tr' : 'en',
        recentMood: latestMood == null
            ? null
            : _moodLabel(latestMood.value, isTr: isTr),
        recentJournalSnippet:
            journals.isEmpty ? null : _snippet(journals.first.content),
        recentDreamSnippet:
            dreams.isEmpty ? null : _snippet(dreams.first.content),
      );

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _answers = List<String>.filled(questions.length, '');
        _questionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _questionsLoading = false;
        _questionsError = isTr
            ? 'Bugünün soruları şu anda yüklenemedi. İnternet bağlantını kontrol edip tekrar deneyebilirsin.'
            : "Today's questions couldn't be loaded. Check your connection and try again.";
      });
    }
  }

  static String _snippet(String text) {
    final trimmed = text.trim();
    return String.fromCharCodes(trimmed.runes.take(200));
  }

  static String _moodLabel(int index, {required bool isTr}) {
    if (index < 0 || index >= AppMood.values.length) return index.toString();
    final mood = AppMood.values[index];
    if (!isTr) return mood.name;
    return switch (mood) {
      AppMood.happy => 'Mutlu',
      AppMood.calm => 'Sakin',
      AppMood.tired => 'Yorgun',
      AppMood.sad => 'Üzgün',
      AppMood.anxious => 'Kaygılı',
    };
  }

  Future<void> _analyze() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final lines = <String>[];
    for (var i = 0; i < _questions.length; i++) {
      final answer = _answers[i].trim();
      if (answer.isEmpty) continue;
      lines.add('${_questions[i]} -> $answer');
    }
    if (lines.isEmpty) return;
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
                      if (_questionsLoading)
                        _QuestionsLoadingCard(
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                        )
                      else if (_questionsError != null)
                        _QuestionsErrorCard(
                          message: _questionsError!,
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          onRetry: _loadQuestions,
                        )
                      else ...[
                        for (var i = 0; i < _questions.length; i++) ...[
                          _QuestionCard(
                            index: i,
                            question: _questions[i],
                            isTr: isTr,
                            isDark: isDark,
                            primary: primary,
                            onChanged: (answer) =>
                                setState(() => _answers[i] = answer),
                          ),
                          const SizedBox(height: 12),
                        ],
                        AstraGoldButton(
                          isDark: isDark,
                          label: _loading
                              ? (isTr
                                  ? 'Analiz ediliyor...'
                                  : 'Analyzing...')
                              : (isTr
                                  ? 'Luma ile analiz et'
                                  : 'Analyze with Luma'),
                          icon: Icons.auto_awesome,
                          isLoading: _loading,
                          enabled: _hasAnswer && !_loading,
                          onTap: _analyze,
                        ),
                      ],
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
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onChanged,
  });

  final int index;
  final String question;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onChanged;

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
          TextField(
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            onChanged: onChanged,
            style: AstraKit.body(
              isDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: isTr ? 'Cevabını yaz...' : 'Write your answer...',
              hintStyle: AstraKit.mutedText(isDark, fontSize: 13),
              filled: true,
              fillColor: isDark
                  ? const Color(0x33231845)
                  : const Color(0x73FBF1DC),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: primary.withValues(alpha: 0.35),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionsLoadingCard extends StatelessWidget {
  const _QuestionsLoadingCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isTr
                  ? 'Luma bugünün sorularını hazırlıyor...'
                  : "Luma is preparing today's questions...",
              textAlign: TextAlign.center,
              style: AstraKit.mutedText(isDark, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionsErrorCard extends StatelessWidget {
  const _QuestionsErrorCard({
    required this.message,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onRetry,
  });

  final String message;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, color: primary, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AstraKit.body(
              isDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, color: primary),
            label: Text(
              isTr ? 'Tekrar dene' : 'Try again',
              style: AstraKit.body(
                isDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
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
