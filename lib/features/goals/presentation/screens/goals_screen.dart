import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/goals_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../data/goals_repository.dart';
import '../providers/goals_providers.dart';
import '../widgets/new_goal_sheet.dart';

/// Localized title for each of the four seeded starter goals, keyed by
/// [DefaultGoalIconKeys]. Lives in the presentation layer since it needs
/// [AppLocalizations]; the repository stays free of any localization
/// concerns.
Map<String, GoalCopy> defaultGoalCopy(AppLocalizations l10n) => {
      DefaultGoalIconKeys.water: GoalCopy(title: l10n.goalsDefaultWaterTitle),
      DefaultGoalIconKeys.journal: GoalCopy(title: l10n.goalsDefaultJournalTitle),
      DefaultGoalIconKeys.meditation: GoalCopy(title: l10n.goalsDefaultMeditationTitle),
      DefaultGoalIconKeys.reading: GoalCopy(title: l10n.goalsDefaultReadingTitle),
    };

IconData iconForGoal(String iconKey) {
  switch (iconKey) {
    case DefaultGoalIconKeys.water:
      return Icons.water_drop_outlined;
    case DefaultGoalIconKeys.journal:
      return Icons.edit_outlined;
    case DefaultGoalIconKeys.meditation:
      return Icons.spa_outlined;
    case DefaultGoalIconKeys.reading:
      return Icons.menu_book_outlined;
    default:
      return Icons.flag_outlined;
  }
}

String unitLabelFor(AppLocalizations l10n, GoalRow goal) =>
    unitLabelForUnit(l10n, goal.unit, goal.customUnitLabel);

/// Localized label for [unit] — [customLabel] is used only when [unit] is
/// [GoalUnit.custom] (the user's own free-text unit name); shared by the
/// goal cards here and the unit picker in `NewGoalSheet`.
String unitLabelForUnit(AppLocalizations l10n, GoalUnit unit, String? customLabel) {
  switch (unit) {
    case GoalUnit.glasses:
      return l10n.goalsUnitGlasses;
    case GoalUnit.minutes:
      return l10n.goalsUnitMinutes;
    case GoalUnit.pages:
      return l10n.goalsUnitPages;
    case GoalUnit.books:
      return l10n.goalsUnitBooks;
    case GoalUnit.custom:
      return customLabel ?? '';
  }
}

/// How much a single tap adds to a goal's progress — big enough to feel
/// meaningful per unit (5 minutes rather than 1), small enough that a
/// goal still takes several taps to complete.
int incrementStepFor(GoalUnit unit) {
  switch (unit) {
    case GoalUnit.glasses:
      return 1;
    case GoalUnit.minutes:
      return 5;
    case GoalUnit.pages:
      return 10;
    case GoalUnit.books:
      return 1;
    case GoalUnit.custom:
      return 1;
  }
}

/// A one-tap starter goal shown as a suggestion chip.
class _GoalPreset {
  const _GoalPreset({
    required this.tr,
    required this.en,
    required this.icon,
    required this.unit,
    required this.target,
    this.customUnitTr,
    this.customUnitEn,
  });

  final String tr;
  final String en;
  final IconData icon;
  final GoalUnit unit;
  final int target;
  final String? customUnitTr;
  final String? customUnitEn;
}

const _goalPresets = <_GoalPreset>[
  _GoalPreset(
      tr: 'Yürüyüş yap',
      en: 'Take a walk',
      icon: Icons.directions_walk_rounded,
      unit: GoalUnit.minutes,
      target: 30),
  _GoalPreset(
      tr: 'Esneme / yoga',
      en: 'Stretch / yoga',
      icon: Icons.self_improvement_rounded,
      unit: GoalUnit.minutes,
      target: 15),
  _GoalPreset(
      tr: 'Erken uyu',
      en: 'Sleep early',
      icon: Icons.bedtime_rounded,
      unit: GoalUnit.custom,
      target: 1,
      customUnitTr: 'gece',
      customUnitEn: 'night'),
  _GoalPreset(
      tr: 'Ekransız mola',
      en: 'Screen-free break',
      icon: Icons.phonelink_erase_rounded,
      unit: GoalUnit.minutes,
      target: 20),
];

/// Goal tracking screen — a streak banner plus a list of goal progress
/// cards, each tappable to quickly log progress. Backed by a local Drift
/// database; see [GoalsRepository] for seeding, per-period resets, and
/// streak bookkeeping.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  bool _didInitialSetup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialSetup) return;
    _didInitialSetup = true;
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(goalsRepositoryProvider);
    repository.ensureSeeded(defaultGoalCopy(l10n)).then((_) => repository.resetElapsedPeriods());
    ref.read(goalStreakProvider.notifier).refresh();
  }

  Future<void> _increment(GoalRow goal) async {
    final l10n = AppLocalizations.of(context);
    final step = incrementStepFor(goal.unit);
    final justCompleted = await ref.read(goalsRepositoryProvider).incrementProgress(goal, step);
    ref.read(goalStreakProvider.notifier).refresh();
    if (!mounted) return;
    if (justCompleted) _showCelebration(l10n, goal.title);
  }

  Future<void> _addPreset(_GoalPreset preset, bool isTr) async {
    await ref.read(goalsRepositoryProvider).addCustomGoal(
          title: isTr ? preset.tr : preset.en,
          unit: preset.unit,
          customUnitLabel: preset.unit == GoalUnit.custom
              ? (isTr ? preset.customUnitTr : preset.customUnitEn)
              : null,
          target: preset.target,
          frequency: GoalFrequency.daily,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SakuraHomePalette.blossomPink,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text(
            isTr ? '"${preset.tr}" hedefi eklendi' : '"${preset.en}" goal added',
            style: LumoraPalette.bodyStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      );
  }

  void _showCelebration(AppLocalizations l10n, String goalTitle) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SakuraHomePalette.blossomPink,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.goalsCelebrationMessage(goalTitle),
                  style: LumoraPalette.bodyStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final goalsAsync = ref.watch(goalsStreamProvider);
    final streak = ref.watch(goalStreakProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: PremiumButton(
        label: l10n.goalsNewButton,
        icon: Icons.add_rounded,
        expand: false,
        onPressed: () => NewGoalSheet.show(context),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Text(
                    l10n.goalsTitle,
                    style: AppTheme.displayFont(
                        fontSize: 24, color: SakuraHomePalette.textDeep),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: _StreakBanner(streak: streak),
                ),
                Expanded(
                  child: goalsAsync.when(
                    data: (goals) {
                      final done = goals.where((g) => g.progress >= g.target).length;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
                        children: [
                          if (goals.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                isTr
                                    ? 'Bugün $done / ${goals.length} tamamlandı'
                                    : '$done of ${goals.length} done today',
                                style: AppTheme.bodyFont(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SakuraHomePalette.textMuted,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          for (final goal in goals)
                            _GoalCard(
                              goal: goal,
                              onIncrement: () => _increment(goal),
                            ),
                          const SizedBox(height: 8),
                          _PresetSuggestions(
                            isTr: isTr,
                            onAdd: (preset) => _addPreset(preset, isTr),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: SakuraHomePalette.blossomPink),
                    ),
                    error: (_, __) => Center(
                      child: Text(
                        l10n.goalsLoadError,
                        style: AppTheme.bodyFont(color: SakuraHomePalette.textMuted),
                      ),
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

/// A horizontal set of one-tap starter-goal suggestions.
class _PresetSuggestions extends StatelessWidget {
  const _PresetSuggestions({required this.isTr, required this.onAdd});

  final bool isTr;
  final ValueChanged<_GoalPreset> onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 16, color: SakuraHomePalette.blossomPink),
            const SizedBox(width: 6),
            Text(
              isTr ? 'Hazır öneriler' : 'Quick suggestions',
              style: AppTheme.bodyFont(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SakuraHomePalette.textDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _goalPresets)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onAdd(preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: SakuraHomePalette.cardWhite,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: SakuraHomePalette.branchMauve.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(preset.icon,
                            size: 16, color: SakuraHomePalette.blossomPink),
                        const SizedBox(width: 6),
                        Text(
                          isTr ? preset.tr : preset.en,
                          style: AppTheme.bodyFont(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: SakuraHomePalette.textDeep,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.add_rounded,
                            size: 15, color: SakuraHomePalette.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.streak});

  final GoalStreak streak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: SakuraHomePalette.ctaGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.blossomPink.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              streak.count > 0
                  ? l10n.goalsStreakBanner(streak.count)
                  : l10n.goalsStreakStartPrompt,
              style: LumoraPalette.bodyStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onIncrement});

  final GoalRow goal;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = unitLabelFor(l10n, goal);
    final progress = goal.target == 0 ? 0.0 : (goal.progress / goal.target).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final step = incrementStepFor(goal.unit);
    final isComplete = goal.progress >= goal.target;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: isComplete ? null : onIncrement,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SakuraHomePalette.blossomPink.withValues(alpha: 0.16),
                      ),
                      child: Icon(iconForGoal(goal.iconKey),
                          color: SakuraHomePalette.blossomPink, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: AppTheme.bodyFont(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: SakuraHomePalette.textDeep,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.goalsProgressFraction(goal.progress, goal.target, unit),
                            style: AppTheme.bodyFont(
                              fontSize: 12.5,
                              color: SakuraHomePalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: AppTheme.bodyFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SakuraHomePalette.blossomPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ProgressBar(progress: progress),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (isComplete) ...[
                      const Icon(Icons.check_circle_rounded,
                          color: SakuraHomePalette.blossomPink, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l10n.goalsCompletedLabel,
                        style: AppTheme.bodyFont(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: SakuraHomePalette.blossomPink,
                        ),
                      ),
                    ],
                    const Spacer(),
                    _IncrementPill(
                      label: l10n.goalsIncrementButton(step, unit),
                      enabled: !isComplete,
                      onTap: onIncrement,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded progress track with a gradient fill matching the app's pink
/// CTA gradient — a plain Material [LinearProgressIndicator] can't do a
/// gradient fill on its own.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 9,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                    color: SakuraHomePalette.branchMauve.withValues(alpha: 0.18)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * progress,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: SakuraHomePalette.ctaGradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IncrementPill extends StatelessWidget {
  const _IncrementPill({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: enabled
                ? const LinearGradient(colors: SakuraHomePalette.ctaGradient)
                : null,
            color: enabled
                ? null
                : SakuraHomePalette.branchMauve.withValues(alpha: 0.2),
          ),
          child: Text(
            label,
            style: LumoraPalette.bodyStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
