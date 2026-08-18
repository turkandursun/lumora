import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/goals_table.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../data/goals_repository.dart';
import '../../domain/goal_template.dart';
import '../goal_template_localization.dart';
import '../providers/goals_providers.dart';
import '../widgets/edit_goal_sheet.dart';
import '../widgets/new_goal_sheet.dart';

IconData iconForGoal(String iconKey) {
  switch (iconKey) {
    case GoalTemplateKeys.water:
      return Icons.water_drop_outlined;
    case GoalTemplateKeys.journal:
      return Icons.edit_outlined;
    case GoalTemplateKeys.meditation:
      return Icons.spa_outlined;
    case GoalTemplateKeys.breathing:
      return Icons.air_rounded;
    case GoalTemplateKeys.reading:
      return Icons.menu_book_outlined;
    case GoalTemplateKeys.walking:
      return Icons.directions_walk_rounded;
    case GoalTemplateKeys.stretching:
      return Icons.self_improvement_rounded;
    case GoalTemplateKeys.sleepEarly:
      return Icons.bedtime_rounded;
    case GoalTemplateKeys.screenFree:
      return Icons.phonelink_erase_rounded;
    default:
      return Icons.flag_outlined;
  }
}

String unitLabelFor(AppLocalizations l10n, GoalRow goal) =>
    unitLabelForUnit(l10n, goal.unit, goal.customUnitLabel);

String unitLabelForUnit(
  AppLocalizations l10n,
  GoalUnit unit,
  String? customLabel,
) {
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
      return customLabel ?? l10n.goalsUnitCustomLabel;
  }
}

String frequencyLabelFor(AppLocalizations l10n, GoalFrequency frequency) {
  switch (frequency) {
    case GoalFrequency.daily:
      return l10n.goalsFrequencyDaily;
    case GoalFrequency.weekly:
      return l10n.goalsFrequencyWeekly;
    case GoalFrequency.monthly:
      return l10n.goalsFrequencyMonthly;
  }
}

int incrementStepFor(GoalUnit unit) {
  switch (unit) {
    case GoalUnit.glasses:
      return 1;
    case GoalUnit.minutes:
      return 5;
    case GoalUnit.pages:
      return 10;
    case GoalUnit.books:
    case GoalUnit.custom:
      return 1;
  }
}

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(
      () => ref.read(goalStreakProvider.notifier).refresh(),
    ));
  }

  Future<void> _increment(GoalRow goal) async {
    final l10n = AppLocalizations.of(context);
    final justCompleted = await ref
        .read(goalsRepositoryProvider)
        .incrementProgress(goal, incrementStepFor(goal.unit));
    await ref.read(goalStreakProvider.notifier).refresh();
    if (!mounted || !justCompleted) return;
    _showToast(
      l10n.goalsCelebrationMessage(goal.title),
      icon: Icons.auto_awesome_rounded,
    );
  }

  Future<void> _addTemplate(GoalTemplate template) async {
    final l10n = AppLocalizations.of(context);
    final title = localizedGoalTemplateTitle(l10n, template);
    final created = await ref.read(goalsRepositoryProvider).addGoalFromTemplate(
          template: template,
          localizedTitle: title,
          localizedCustomUnitLabel:
              localizedGoalTemplateCustomUnit(l10n, template),
        );
    if (!mounted || !created) return;
    _showToast(
      l10n.goalsTemplateAddedMessage(title),
      icon: Icons.add_task_rounded,
    );
  }

  Future<void> _editGoal(GoalRow goal) async {
    final draft = await EditGoalSheet.show(context, goal);
    if (!mounted || draft == null) return;
    final l10n = AppLocalizations.of(context);

    final resetsProgress =
        draft.unit != goal.unit || draft.frequency != goal.frequency;
    if (resetsProgress &&
        !await _confirm(
          title: l10n.goalsEditResetTitle,
          body: l10n.goalsEditResetBody,
        )) {
      return;
    }
    if (!resetsProgress &&
        draft.target < goal.progress &&
        !await _confirm(
          title: l10n.goalsEditClampTitle,
          body: l10n.goalsEditClampBody,
        )) {
      return;
    }

    final updated = await ref.read(goalsRepositoryProvider).updateGoal(
          localId: goal.id,
          title: draft.title,
          target: draft.target,
          unit: draft.unit,
          customUnitLabel: draft.customUnitLabel,
          frequency: draft.frequency,
        );
    if (!mounted || !updated) return;
    _showToast(l10n.goalsUpdatedMessage, icon: Icons.edit_rounded);
  }

  Future<void> _archiveGoal(GoalRow goal) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      title: l10n.goalsArchiveConfirmTitle,
      body: l10n.goalsArchiveConfirmBody,
    );
    if (!confirmed || !mounted) return;
    await ref.read(goalsRepositoryProvider).archiveGoal(goal.id);
    if (!mounted) return;
    _showToast(l10n.goalsArchivedMessage, icon: Icons.archive_outlined);
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.goalsCancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.goalsConfirmButton),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showToast(String message, {required IconData icon}) {
    final isDark = ref.read(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isDark ? const Color(0xF01A1233) : const Color(0xF0FFF8EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primary.withValues(alpha: 0.4)),
          ),
          content: Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: AstraKit.body(context, isDark, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final streak = ref.watch(goalStreakProvider);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AstraGoldButton(
        isDark: isDark,
        label: l10n.goalsCreateCustomButton,
        icon: Icons.add_rounded,
        expand: false,
        onTap: () => NewGoalSheet.show(context),
      ),
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.goalsTitle,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                  child: _StreakBanner(
                    streak: streak,
                    isDark: isDark,
                    primary: primary,
                  ),
                ),
                Expanded(
                  child: goalsAsync.when(
                    data: (goals) => _GoalsContent(
                      goals: goals,
                      isDark: isDark,
                      primary: primary,
                      onIncrement: _increment,
                      onEdit: _editGoal,
                      onArchive: _archiveGoal,
                      onAddTemplate: _addTemplate,
                    ),
                    loading: () => Center(
                      child: CircularProgressIndicator(color: primary),
                    ),
                    error: (_, __) => Center(
                      child: Text(
                        l10n.goalsLoadError,
                        style:
                            AstraKit.mutedText(context, isDark, fontSize: 13),
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

class _GoalsContent extends StatelessWidget {
  const _GoalsContent({
    required this.goals,
    required this.isDark,
    required this.primary,
    required this.onIncrement,
    required this.onEdit,
    required this.onArchive,
    required this.onAddTemplate,
  });

  final List<GoalRow> goals;
  final bool isDark;
  final Color primary;
  final ValueChanged<GoalRow> onIncrement;
  final ValueChanged<GoalRow> onEdit;
  final ValueChanged<GoalRow> onArchive;
  final ValueChanged<GoalTemplate> onAddTemplate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = goals.where((goal) => goal.progress >= goal.target).length;
    final activeTemplates =
        goals.map((goal) => goal.templateKey).whereType<String>().toSet();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
      children: [
        _SectionTitle(
          icon: Icons.track_changes_rounded,
          title: l10n.goalsMyGoalsTitle,
          isDark: isDark,
          primary: primary,
        ),
        const SizedBox(height: 10),
        if (goals.isEmpty)
          _EmptyGoalsCard(isDark: isDark, primary: primary)
        else ...[
          Text(
            l10n.goalsPeriodSummary(done, goals.length),
            style: AstraKit.mutedText(
              context,
              isDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final goal in goals)
            _GoalCard(
              goal: goal,
              isDark: isDark,
              primary: primary,
              onIncrement: () => onIncrement(goal),
              onEdit: () => onEdit(goal),
              onArchive: () => onArchive(goal),
            ),
        ],
        const SizedBox(height: 22),
        _SectionTitle(
          icon: Icons.auto_awesome_rounded,
          title: l10n.goalsSuggestedTitle,
          isDark: isDark,
          primary: primary,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 620
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final template in goalTemplates)
                  SizedBox(
                    width: width,
                    child: _TemplateCard(
                      template: template,
                      isActive: activeTemplates.contains(template.key),
                      isDark: isDark,
                      primary: primary,
                      onAdd: () => onAddTemplate(template),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.primary,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 17, color: primary),
          const SizedBox(width: 7),
          Text(
            title,
            style: AstraKit.body(
              context,
              isDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard({required this.isDark, required this.primary});

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Column(
        children: [
          Icon(Icons.flag_circle_outlined, color: primary, size: 40),
          const SizedBox(height: 10),
          Text(
            l10n.goalsEmptyTitle,
            textAlign: TextAlign.center,
            style: AstraKit.body(
              context,
              isDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            l10n.goalsEmptyBody,
            textAlign: TextAlign.center,
            style: AstraKit.mutedText(context, isDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isActive,
    required this.isDark,
    required this.primary,
    required this.onAdd,
  });

  final GoalTemplate template;
  final bool isActive;
  final bool isDark;
  final Color primary;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = unitLabelForUnit(
      l10n,
      template.unit,
      localizedGoalTemplateCustomUnit(l10n, template),
    );
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderRadius: 18,
      child: Row(
        children: [
          Icon(iconForGoal(template.iconKey), color: primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedGoalTemplateTitle(l10n, template),
                  style: AstraKit.body(
                    context,
                    isDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${template.defaultTarget} $unit · '
                  '${frequencyLabelFor(l10n, template.frequency)}',
                  style: AstraKit.mutedText(context, isDark, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: isActive ? null : onAdd,
            icon: Icon(
              isActive ? Icons.check_rounded : Icons.add_rounded,
              size: 16,
            ),
            label: Text(
              isActive ? l10n.goalsActiveBadge : l10n.goalsAddTemplate,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({
    required this.streak,
    required this.isDark,
    required this.primary,
  });

  final GoalStreak streak;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.18),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              streak.count > 0
                  ? l10n.goalsStreakBanner(streak.count)
                  : l10n.goalsStreakStartPrompt,
              style: AstraKit.body(
                context,
                isDark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.isDark,
    required this.primary,
    required this.onIncrement,
    required this.onEdit,
    required this.onArchive,
  });

  final GoalRow goal;
  final bool isDark;
  final Color primary;
  final VoidCallback onIncrement;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unit = unitLabelFor(l10n, goal);
    final progress =
        goal.target == 0 ? 0.0 : (goal.progress / goal.target).clamp(0.0, 1.0);
    final isComplete = goal.progress >= goal.target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        borderRadius: 22,
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
                    color: primary.withValues(alpha: 0.16),
                    border: Border.all(color: primary.withValues(alpha: 0.35)),
                  ),
                  child: Icon(iconForGoal(goal.iconKey), color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: AstraKit.body(
                          context,
                          isDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.goalsProgressFraction(goal.progress, goal.target, unit)} · '
                        '${frequencyLabelFor(l10n, goal.frequency)}',
                        style:
                            AstraKit.mutedText(context, isDark, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_GoalAction>(
                  tooltip: '',
                  icon: Icon(Icons.more_horiz_rounded, color: primary),
                  onSelected: (action) {
                    if (action == _GoalAction.edit) onEdit();
                    if (action == _GoalAction.archive) onArchive();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _GoalAction.edit,
                      child: Text(l10n.goalsEditAction),
                    ),
                    PopupMenuItem(
                      value: _GoalAction.archive,
                      child: Text(l10n.goalsArchiveAction),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProgressBar(progress: progress, primary: primary),
            const SizedBox(height: 13),
            Row(
              children: [
                if (isComplete) ...[
                  Icon(Icons.check_circle_rounded, color: primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.goalsCompletedLabel,
                    style: AstraKit.body(
                      context,
                      isDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
                const Spacer(),
                _IncrementPill(
                  label: l10n.goalsIncrementButton(
                    incrementStepFor(goal.unit),
                    unit,
                  ),
                  enabled: !isComplete,
                  isDark: isDark,
                  primary: primary,
                  onTap: onIncrement,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _GoalAction { edit, archive }

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.primary});

  final double progress;
  final Color primary;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 9,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Container(color: primary.withValues(alpha: 0.16)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _IncrementPill extends StatelessWidget {
  const _IncrementPill({
    required this.label,
    required this.enabled,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: enabled
                  ? LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.75)],
                    )
                  : null,
              color: enabled ? null : primary.withValues(alpha: 0.16),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? const Color(0xFF1A0F00)
                    : AstraKit.muted(context, isDark),
              ),
            ),
          ),
        ),
      );
}
