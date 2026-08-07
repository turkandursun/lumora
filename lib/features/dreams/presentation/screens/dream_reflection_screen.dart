import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../data/dream_reflection_options.dart';
import '../providers/dreams_providers.dart';

/// Localized chip labels for the reflection flow's quick-select questions,
/// keyed by [DreamFeelingKeys] / [DreamFamiliarPersonKeys]. Shared with
/// [DreamJournalScreen]'s card display (imported there via `show`, mirroring
/// how `goals_screen.dart` shares `unitLabelForUnit` with `NewGoalSheet`).
Map<String, String> dreamFeelingLabels(AppLocalizations l10n) => {
      DreamFeelingKeys.peaceful: l10n.dreamFeelingPeaceful,
      DreamFeelingKeys.anxious: l10n.dreamFeelingAnxious,
      DreamFeelingKeys.confused: l10n.dreamFeelingConfused,
      DreamFeelingKeys.happy: l10n.dreamFeelingHappy,
      DreamFeelingKeys.sad: l10n.dreamFeelingSad,
      DreamFeelingKeys.neutral: l10n.dreamFeelingNeutral,
    };

Map<String, String> dreamFamiliarPersonLabels(AppLocalizations l10n) => {
      DreamFamiliarPersonKeys.yes: l10n.dreamFamiliarPersonYes,
      DreamFamiliarPersonKeys.no: l10n.dreamFamiliarPersonNo,
      DreamFamiliarPersonKeys.notSure: l10n.dreamFamiliarPersonNotSure,
    };

const _pageCount = 4;

/// Short, entirely optional post-save reflection flow for a just-written
/// dream — four questions shown one at a time, paged like onboarding, with
/// "Skip" always available. No AI involved: quick-select answers and free
/// text are stored as-is, and anything left unanswered stays null (see
/// [DreamsRepository.saveReflection]).
class DreamReflectionScreen extends ConsumerStatefulWidget {
  const DreamReflectionScreen({super.key, required this.dreamId});

  final int dreamId;

  @override
  ConsumerState<DreamReflectionScreen> createState() => _DreamReflectionScreenState();
}

class _DreamReflectionScreenState extends ConsumerState<DreamReflectionScreen> {
  final _pageController = PageController();
  final _firstThoughtController = TextEditingController();
  final _lifeConnectionController = TextEditingController();

  double _page = 0;
  String? _feeling;
  String? _familiarPerson;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstThoughtController.dispose();
    _lifeConnectionController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    final current = _page.round();
    if (current == _pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    String? nonEmpty(String text) => text.trim().isEmpty ? null : text.trim();

    await ref.read(dreamsRepositoryProvider).saveReflection(
          id: widget.dreamId,
          feelingTag: _feeling,
          familiarPerson: _familiarPerson,
          firstThought: nonEmpty(_firstThoughtController.text),
          lifeConnection: nonEmpty(_lifeConnectionController.text),
        );

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final isLastPage = _page.round() == _pageCount - 1;
    final pages = _buildPages(l10n, isDark);
    final primary = AstraKit.primary(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                _buildSkipRow(l10n, isDark),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    itemBuilder: (context, index) => _buildAnimatedPage(index, pages[index]),
                  ),
                ),
                _buildDots(primary, isDark),
                const SizedBox(height: 28),
                _buildActionButton(l10n, isLastPage, isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPages(AppLocalizations l10n, bool isDark) {
    final feelingLabels = dreamFeelingLabels(l10n);
    final familiarPersonLabels = dreamFamiliarPersonLabels(l10n);

    return [
      _ReflectionQuestionPage(
        question: l10n.dreamReflectionFeelingQuestion,
        isDark: isDark,
        child: _ChoiceChips(
          options: DreamFeelingKeys.values,
          labels: feelingLabels,
          selected: _feeling,
          isDark: isDark,
          onSelected: (key) => setState(() => _feeling = _feeling == key ? null : key),
        ),
      ),
      _ReflectionQuestionPage(
        question: l10n.dreamReflectionFamiliarPersonQuestion,
        isDark: isDark,
        child: _ChoiceChips(
          options: DreamFamiliarPersonKeys.values,
          labels: familiarPersonLabels,
          selected: _familiarPerson,
          isDark: isDark,
          onSelected: (key) => setState(() => _familiarPerson = _familiarPerson == key ? null : key),
        ),
      ),
      _ReflectionQuestionPage(
        question: l10n.dreamReflectionFirstThoughtQuestion,
        isDark: isDark,
        child: _ReflectionTextField(
          key: const Key('dreamReflectionFirstThoughtField'),
          controller: _firstThoughtController,
          hint: l10n.dreamReflectionTextFieldHint,
          isDark: isDark,
        ),
      ),
      _ReflectionQuestionPage(
        question: l10n.dreamReflectionLifeConnectionQuestion,
        isDark: isDark,
        child: _ReflectionTextField(
          key: const Key('dreamReflectionLifeConnectionField'),
          controller: _lifeConnectionController,
          hint: l10n.dreamReflectionTextFieldHint,
          isDark: isDark,
        ),
      ),
    ];
  }

  /// Subtle fade + rise as a page settles into place — the same calm
  /// transition [OnboardingScreen] uses, rather than a snappy default swipe.
  Widget _buildAnimatedPage(int index, Widget child) {
    final distance = (index - _page).clamp(-1.0, 1.0).abs();
    return Opacity(
      opacity: 1 - (distance * 0.6),
      child: Transform.translate(
        offset: Offset(0, distance * 18),
        child: child,
      ),
    );
  }

  Widget _buildSkipRow(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : _finish,
            child: Text(
              l10n.dreamReflectionSkipButton,
              style: AstraKit.mutedText(isDark, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(Color primary, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (index) {
        final distance = (index - _page).abs();
        final isActive = distance < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? primary : AstraKit.muted(isDark).withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(AppLocalizations l10n, bool isLastPage, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AstraGoldButton(
        isDark: isDark,
        height: 56,
        isLoading: _isSaving,
        enabled: !_isSaving,
        label: isLastPage ? l10n.dreamReflectionFinishButton : l10n.dreamReflectionNextButton,
        onTap: _onNextPressed,
      ),
    );
  }
}

/// One reflection question: the prompt, then whatever answer widget
/// (choice chips or a text field) it's paired with — centered like each
/// onboarding beat.
class _ReflectionQuestionPage extends StatelessWidget {
  const _ReflectionQuestionPage({required this.question, required this.child, required this.isDark});

  final String question;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(question, textAlign: TextAlign.center, style: AstraKit.heading1(isDark, fontSize: 22)),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

/// Single-select set of quick-answer chips — tapping the already-selected
/// chip clears it, since every reflection question is optional.
class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
    required this.options,
    required this.labels,
    required this.selected,
    required this.isDark,
    required this.onSelected,
  });

  final List<String> options;
  final Map<String, String> labels;
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in options)
          _ChoiceChip(
            label: labels[option] ?? option,
            isSelected: option == selected,
            isDark: isDark,
            onTap: () => onSelected(option),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.isSelected, required this.isDark, required this.onTap});

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AstraKit.primary(isDark);
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? primary.withValues(alpha: 0.85)
                  : (isDark ? const Color(0x33231845) : const Color(0x99FBF1DD)),
              border: Border.all(color: isSelected ? primary : primary.withValues(alpha: 0.25), width: 1.1),
            ),
            child: Text(
              label,
              style: AstraKit.body(isDark, fontSize: 13.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectionTextField extends StatelessWidget {
  const _ReflectionTextField({super.key, required this.controller, required this.hint, required this.isDark});

  final TextEditingController controller;
  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = AstraKit.primary(isDark);
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.all(4),
      borderRadius: 18,
      child: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 3,
        style: AstraKit.body(isDark),
        cursorColor: primary,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.all(14),
          hintText: hint,
          hintStyle: AstraKit.mutedText(isDark, fontSize: 13),
        ),
      ),
    );
  }
}
