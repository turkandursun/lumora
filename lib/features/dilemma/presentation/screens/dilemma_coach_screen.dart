import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../data/dilemma_coach_service.dart';

/// "Kendi İkilemin" — a short, guided decision companion. The user writes a real
/// dilemma, answers just TWO reflective prompts (drawn at random from a pool of
/// proven decision frameworks, so the questions change every time), and Luma
/// reconciles their answers into a warm synthesis — reflecting, never dictating.
class DilemmaCoachScreen extends ConsumerStatefulWidget {
  const DilemmaCoachScreen({super.key});

  @override
  ConsumerState<DilemmaCoachScreen> createState() => _DilemmaCoachScreenState();
}

class _DilemmaCoachScreenState extends ConsumerState<DilemmaCoachScreen> {
  // One controller per possible field; only the two selected prompts are shown.
  final _c = <String, TextEditingController>{
    for (final k in [
      'dilemma',
      'A',
      'B',
      'widen',
      'values',
      'tenTen',
      'regret',
      'friend'
    ])
      k: TextEditingController(),
  };

  final _service = DilemmaCoachService();

  /// The two framework prompts chosen for this session (random → always fresh).
  late final List<_FwSpec> _selected;

  // 0 = write, 1.._selected.length = prompts, then synthesis.
  int _step = 0;
  bool _loading = false;
  bool _failed = false;
  bool _saved = false;
  DilemmaSynthesis? _result;

  int get _promptCount => _selected.length;
  int get _synthesisStep => _promptCount + 1;
  int get _inputScreens => _promptCount + 1; // write + prompts
  bool get _onSynthesis => _step >= _synthesisStep;

  @override
  void initState() {
    super.initState();
    final pool = _pool();
    pool.shuffle(Random());
    _selected = pool.take(2).toList();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _tr(BuildContext c) => Localizations.localeOf(c).languageCode == 'tr';
  bool get _canAdvanceFromWrite => _c['dilemma']!.text.trim().length >= 3;

  void _next() {
    if (_step == 0 && !_canAdvanceFromWrite) return;
    if (_step < _promptCount) {
      setState(() => _step++);
    } else {
      _synthesize();
    }
    FocusScope.of(context).unfocus();
  }

  /// Back semantics: from the result/synthesis screen, exit straight back to the
  /// dilemma screen (not step-by-step). From an input step, go back one step.
  void _handleBack() {
    FocusScope.of(context).unfocus();
    if (_onSynthesis || _step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _synthesize() async {
    setState(() {
      _step = _synthesisStep;
      _loading = true;
      _failed = false;
    });
    final language = _tr(context) ? 'tr' : 'en';
    String t(String k) => _c[k]!.text.trim();
    try {
      final result = await _service.synthesize(
        input: DilemmaInput(
          dilemma: t('dilemma'),
          optionA: t('A'),
          optionB: t('B'),
          widen: t('widen'),
          values: t('values'),
          tenTen: t('tenTen'),
          regret: t('regret'),
          friend: t('friend'),
        ),
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _saveToJournal() async {
    final r = _result;
    if (r == null || _saved) return;
    final tr = _tr(context);
    final a = _c['A']!.text.trim();
    final b = _c['B']!.text.trim();
    final body = StringBuffer()
      ..writeln(tr ? '🧭 Karar günlüğü' : '🧭 Decision journal')
      ..writeln()
      ..writeln('${tr ? 'İkilem' : 'Dilemma'}: ${_c['dilemma']!.text.trim()}');
    if (a.isNotEmpty || b.isNotEmpty) body.writeln('A: $a   •   B: $b');
    body
      ..writeln()
      ..writeln(r.reflection)
      ..writeln()
      ..writeln('${tr ? 'Eğilim' : 'Leaning'}: ${r.lean}')
      ..writeln()
      ..writeln('${tr ? 'Üzerine düşün' : 'Sit with'}: ${r.question}');

    try {
      await ref
          .read(journalEntriesRepositoryProvider)
          .save(body.toString().trim(), title: r.title);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(tr ? 'Günlüğe kaydedildi' : 'Saved to journal'),
        ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr ? 'Kaydedilemedi' : 'Could not save'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final tr = _tr(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AstraMountainBackground(
          isDark: isDark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    isDark: isDark,
                    primary: primary,
                    title: tr ? 'Kendi İkilemin' : 'Your Own Dilemma',
                    step: _step,
                    total: _inputScreens,
                    onBack: _handleBack,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(
                          _onSynthesis
                              ? 'synthesis-$_loading-$_failed'
                              : 'step-$_step',
                        ),
                        child: _onSynthesis
                            ? _buildSynthesis(isDark, primary, tr)
                            : _buildStep(isDark, primary, tr),
                      ),
                    ),
                  ),
                  if (!_onSynthesis) ...[
                    const SizedBox(height: 12),
                    _NavBar(
                      isDark: isDark,
                      tr: tr,
                      isLast: _step == _promptCount,
                      canAdvance: _step != 0 || _canAdvanceFromWrite,
                      optional: _step != 0,
                      onNext: _next,
                      onSkip: _next,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark, Color primary, bool tr) {
    if (_step == 0) {
      return _WriteStep(
        isDark: isDark,
        primary: primary,
        tr: tr,
        dilemma: _c['dilemma']!,
        optionA: _c['A']!,
        optionB: _c['B']!,
        onChanged: () => setState(() {}),
      );
    }
    final s = _selected[_step - 1];
    return _FrameworkStep(
      isDark: isDark,
      primary: primary,
      badge: s.badge,
      title: s.title,
      helper: s.helper,
      hint: s.hint,
      controller: _c[s.key]!,
    );
  }

  Widget _buildSynthesis(bool isDark, Color primary, bool tr) {
    if (_loading) return _CoachLoading(isDark: isDark, tr: tr);
    if (_failed) {
      return _CoachFailed(
        isDark: isDark,
        primary: primary,
        tr: tr,
        onRetry: _synthesize,
      );
    }
    return _SynthesisView(
      isDark: isDark,
      primary: primary,
      tr: tr,
      result: _result!,
      saved: _saved,
      onSave: _saveToJournal,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }

  List<_FwSpec> _pool() {
    final tr = _tr(context);
    return [
      _FwSpec(
        key: 'widen',
        badge: tr ? 'GENİŞLET' : 'WIDEN',
        title: tr ? 'Üçüncü bir yol var mı?' : 'Is there a third path?',
        helper: tr
            ? 'İkili seçim çoğu zaman bir tuzaktır. A ve B dışında bir olasılık hayal et.'
            : 'A binary choice is often a trap. Imagine a possibility beyond A and B.',
        hint: tr
            ? 'Aklına gelen üçüncü seçenek…'
            : 'A third option that comes to mind…',
      ),
      _FwSpec(
        key: 'values',
        badge: tr ? 'DEĞERLER' : 'VALUES',
        title:
            tr ? 'Hangi değerlerin çatışıyor?' : 'Which values are in tension?',
        helper: tr
            ? 'Zor kararlar genelde iki değerin çarpışmasıdır — ör. güvenlik ↔ özgürlük.'
            : 'Hard decisions are usually two values colliding — e.g. security ↔ freedom.',
        hint: tr
            ? 'İçinde çarpışan iki değer…'
            : 'Two values pulling against each other…',
      ),
      _FwSpec(
        key: 'tenTen',
        badge: '10 · 10 · 10',
        title:
            tr ? '10 dakika, 10 ay, 10 yıl' : '10 minutes, 10 months, 10 years',
        helper: tr
            ? 'Seçimini yapsan, 10 dakika / 10 ay / 10 yıl sonra nasıl hissederdin?'
            : 'If you chose, how would you feel in 10 min / 10 months / 10 years?',
        hint: tr
            ? 'Zaman içinde nasıl hissederdin…'
            : 'How it would feel over time…',
      ),
      _FwSpec(
        key: 'regret',
        badge: tr ? 'PİŞMANLIK' : 'REGRET',
        title: tr ? '80 yaşındaki sen' : 'You at 80',
        helper: tr
            ? 'Hayatının sonunda geriye baktığında hangisinden en az pişman olurdun?'
            : 'Looking back at the end of your life, which would you regret least?',
        hint: tr ? 'En az pişman olacağın…' : 'The one you’d regret least…',
      ),
      _FwSpec(
        key: 'friend',
        badge: tr ? 'MESAFE' : 'DISTANCE',
        title:
            tr ? 'Bir arkadaşına ne derdin?' : 'What would you tell a friend?',
        helper: tr
            ? 'Aynı ikilemi yaşayan en yakın arkadaşına ne tavsiye ederdin?'
            : 'What would you advise your closest friend in the same spot?',
        hint: tr ? 'Arkadaşına söyleyeceğin…' : 'What you’d tell them…',
      ),
    ];
  }
}

class _FwSpec {
  const _FwSpec({
    required this.key,
    required this.badge,
    required this.title,
    required this.helper,
    required this.hint,
  });
  final String key;
  final String badge;
  final String title;
  final String helper;
  final String hint;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.primary,
    required this.title,
    required this.step,
    required this.total,
    required this.onBack,
  });

  final bool isDark;
  final Color primary;
  final String title;
  final int step;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = step >= total ? 1.0 : (step / (total - 1)).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            AstraCircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              isDark: isDark,
              primaryColor: primary,
              onTap: onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: AstraKit.heading1(context, isDark, fontSize: 22)),
            ),
            if (step < total)
              Text('${step + 1}/$total',
                  style: AstraKit.mutedText(context, isDark, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 4,
              backgroundColor: primary.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _WriteStep extends StatelessWidget {
  const _WriteStep({
    required this.isDark,
    required this.primary,
    required this.tr,
    required this.dilemma,
    required this.optionA,
    required this.optionB,
    required this.onChanged,
  });

  final bool isDark;
  final Color primary;
  final bool tr;
  final TextEditingController dilemma;
  final TextEditingController optionA;
  final TextEditingController optionB;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr ? 'Seni ne ikileme düşürdü?' : 'What are you torn about?',
                style: AstraKit.heading2(context, isDark, fontSize: 19)),
            const SizedBox(height: 8),
            Text(
              tr
                  ? 'Kararını yaz. Sonra sadece iki kısa soru, ardından Luma’nın yansıması.'
                  : 'Write your decision. Then just two short questions and Luma’s reflection.',
              style: AstraKit.mutedText(context, isDark, fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            _Field(
              isDark: isDark,
              primary: primary,
              controller: dilemma,
              hint: tr
                  ? 'Örn. İstanbul’daki işi kabul etsem mi, burada mı kalsam?'
                  : 'e.g. Should I take the job in Istanbul, or stay here?',
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    isDark: isDark,
                    primary: primary,
                    controller: optionA,
                    hint:
                        tr ? 'Seçenek A (isteğe bağlı)' : 'Option A (optional)',
                    minLines: 1,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    isDark: isDark,
                    primary: primary,
                    controller: optionB,
                    hint:
                        tr ? 'Seçenek B (isteğe bağlı)' : 'Option B (optional)',
                    minLines: 1,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameworkStep extends StatelessWidget {
  const _FrameworkStep({
    required this.isDark,
    required this.primary,
    required this.badge,
    required this.title,
    required this.helper,
    required this.hint,
    required this.controller,
  });

  final bool isDark;
  final Color primary;
  final String badge;
  final String title;
  final String helper;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.16 : 0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: AstraKit.heading2(context, isDark, fontSize: 20)),
            const SizedBox(height: 8),
            Text(helper,
                style: AstraKit.mutedText(context, isDark, fontSize: 13.5)),
            const SizedBox(height: 18),
            _Field(
              isDark: isDark,
              primary: primary,
              controller: controller,
              hint: hint,
              minLines: 4,
              maxLines: 8,
              autofocus: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.isDark,
    required this.primary,
    required this.controller,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 4,
    this.autofocus = false,
    this.onChanged,
  });

  final bool isDark;
  final Color primary;
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : primary.withValues(alpha: 0.22),
        ),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        autofocus: autofocus,
        onChanged: onChanged,
        style: AstraKit.body(context, isDark, fontSize: 15, height: 1.5),
        cursorColor: primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          hintText: hint,
          hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14.5)
              .copyWith(color: AstraKit.faint(context, isDark)),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.isDark,
    required this.tr,
    required this.isLast,
    required this.canAdvance,
    required this.optional,
    required this.onNext,
    required this.onSkip,
  });

  final bool isDark;
  final bool tr;
  final bool isLast;
  final bool canAdvance;
  final bool optional;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (optional)
          TextButton(
            onPressed: onSkip,
            child: Text(tr ? 'Atla' : 'Skip',
                style: AstraKit.mutedText(context, isDark,
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        const Spacer(),
        AstraGoldButton(
          label: isLast
              ? (tr ? 'Luma’ya danış' : 'Ask Luma')
              : (tr ? 'İleri' : 'Next'),
          isDark: isDark,
          enabled: canAdvance,
          expand: false,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _CoachLoading extends StatefulWidget {
  const _CoachLoading({required this.isDark, required this.tr});
  final bool isDark;
  final bool tr;

  @override
  State<_CoachLoading> createState() => _CoachLoadingState();
}

class _CoachLoadingState extends State<_CoachLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_c.value);
              return Transform.scale(
                scale: 0.9 + 0.16 * t,
                child: Opacity(
                  opacity: 0.7 + 0.3 * t,
                  child: Image.asset('assets/images/luma_star_closed.png',
                      width: 46, height: 46),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            widget.tr ? 'Luma düşünüyor…' : 'Luma is thinking…',
            style: AstraKit.heading2(context, widget.isDark, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            widget.tr
                ? 'Cevaplarını bir araya getiriyor.'
                : 'Bringing your answers together.',
            style: AstraKit.mutedText(context, widget.isDark, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _CoachFailed extends StatelessWidget {
  const _CoachFailed({
    required this.isDark,
    required this.primary,
    required this.tr,
    required this.onRetry,
  });
  final bool isDark;
  final Color primary;
  final bool tr;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 40, color: primary.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Text(
            tr
                ? 'Luma şu an yanıt veremedi.'
                : 'Luma couldn’t respond right now.',
            textAlign: TextAlign.center,
            style: AstraKit.body(context, isDark,
                fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          AstraGoldButton(
            label: tr ? 'Tekrar dene' : 'Try again',
            isDark: isDark,
            expand: false,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _SynthesisView extends StatelessWidget {
  const _SynthesisView({
    required this.isDark,
    required this.primary,
    required this.tr,
    required this.result,
    required this.saved,
    required this.onSave,
    required this.onClose,
  });

  final bool isDark;
  final Color primary;
  final bool tr;
  final DilemmaSynthesis result;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset('assets/images/luma_star_closed.png',
                  width: 26, height: 26),
              const SizedBox(width: 10),
              Text(tr ? 'Luma’nın yansıması' : 'Luma’s reflection',
                  style: AstraKit.mutedText(context, isDark,
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AstraKit.heading(context, isDark),
            ),
          ),
          const SizedBox(height: 14),
          AstraGlassCard(
            isDark: isDark,
            primaryColor: primary,
            padding: const EdgeInsets.all(18),
            child: Text(
              result.reflection,
              style:
                  AstraKit.body(context, isDark, fontSize: 15.5, height: 1.6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.10 : 0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primary.withValues(alpha: 0.24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.trending_flat_rounded, size: 20, color: primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(result.lean,
                      style: AstraKit.body(context, isDark,
                          fontSize: 14.5, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '“${result.question}”',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: AstraKit.heading(context, isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr ? 'Karar senin.' : 'The choice is yours.',
            style: AstraKit.mutedText(context, isDark,
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          AstraGoldButton(
            label: saved
                ? (tr ? 'Kaydedildi ✓' : 'Saved ✓')
                : (tr ? 'Günlüğe kaydet' : 'Save to journal'),
            isDark: isDark,
            enabled: !saved,
            onTap: onSave,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onClose,
            child: Text(tr ? 'Kapat' : 'Close',
                style: AstraKit.mutedText(context, isDark,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
