import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/goals_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/mood_gradients.dart';
import '../../../../theme/mood_theme_provider.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../providers/journal_streak_provider.dart';

extension _MoodEmoji on AppMood {
  String get emoji {
    switch (this) {
      case AppMood.happy:
        return '😊';
      case AppMood.calm:
        return '😌';
      case AppMood.tired:
        return '😴';
      case AppMood.sad:
        return '😔';
      case AppMood.anxious:
        return '😟';
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case AppMood.happy:
        return l10n.moodHappy;
      case AppMood.calm:
        return l10n.moodCalm;
      case AppMood.tired:
        return l10n.moodTired;
      case AppMood.sad:
        return l10n.moodSad;
      case AppMood.anxious:
        return l10n.moodAnxious;
    }
  }
}

/// A short, rotating gentle self-care nudge — rotates by hour of day so it
/// changes through the day without needing any backing state.
String _selfCareNudge(AppLocalizations l10n) {
  final nudges = [
    l10n.homeSelfCareNudge1,
    l10n.homeSelfCareNudge2,
    l10n.homeSelfCareNudge3,
    l10n.homeSelfCareNudge4,
  ];
  return nudges[DateTime.now().hour % nudges.length];
}

/// Today's goal completion, as a 0-1 fraction — averaged across daily-
/// frequency goals if any exist (falling back to every goal) so the tile
/// reads as "today", not a monthly reading target.
double _todayGoalFraction(List<GoalRow> goals) {
  if (goals.isEmpty) return 0;
  final daily = goals.where((g) => g.frequency == GoalFrequency.daily).toList();
  final source = daily.isNotEmpty ? daily : goals;
  final total = source.fold<double>(
    0,
    (sum, g) => sum + (g.target == 0 ? 0 : g.progress / g.target).clamp(0, 1),
  );
  return (total / source.length).clamp(0, 1);
}

/// The four-tile stats card near the top of Home: journaling streak, mood
/// check-in, today's goal progress, and a rotating self-care nudge.
class HomeStatsRow extends ConsumerWidget {
  const HomeStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final streak = ref.watch(journalStreakProvider);
    final mood = ref.watch(moodThemeProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);
    final goalFraction = goalsAsync.maybeWhen(
      data: _todayGoalFraction,
      orElse: () => 0.0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StreakTile(streakDays: streak.count, l10n: l10n),
            ),
            const _TileDivider(),
            Expanded(
              child: _MoodTile(mood: mood, l10n: l10n),
            ),
            const _TileDivider(),
            Expanded(
              child: _GoalTile(fraction: goalFraction, l10n: l10n),
            ),
            const _TileDivider(),
            Expanded(
              child: _SelfCareTile(text: _selfCareNudge(l10n)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: SakuraHomePalette.branchMauve.withValues(alpha: 0.16),
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streakDays, required this.l10n});

  final int streakDays;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF4A261), size: 20),
          const SizedBox(height: 6),
          Text(
            '$streakDays',
            style: AppTheme.displayFont(fontSize: 18, color: SakuraHomePalette.textDeep),
          ),
          Text(
            l10n.homeStatStreakLabel,
            style: AppTheme.bodyFont(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.homeStatStreakSubtext,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyFont(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: SakuraHomePalette.textMuted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodTile extends ConsumerWidget {
  const _MoodTile({required this.mood, required this.l10n});

  final AppMood? mood;
  final AppLocalizations l10n;

  void _openMoodPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MoodPickerSheet(
        selected: mood,
        onSelected: (m) {
          ref.read(moodThemeProvider.notifier).state = m;
          ref
              .read(moodLogProvider.notifier)
              .setForDay(DateTime.now(), AppMood.values.indexOf(m));
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openMoodPicker(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mood?.emoji ?? '🙂', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Text(
                    mood?.label(l10n) ?? l10n.homeStatMoodUnset,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.displayFont(fontSize: 13, color: SakuraHomePalette.textDeep),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 15,
                  color: SakuraHomePalette.textMuted,
                ),
              ],
            ),
            Text(
              l10n.homeStatMoodLabel,
              style: AppTheme.bodyFont(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: SakuraHomePalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPickerSheet extends StatelessWidget {
  const _MoodPickerSheet({required this.selected, required this.onSelected});

  final AppMood? selected;
  final ValueChanged<AppMood> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: SakuraHomePalette.cream,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeMoodPickerTitle,
              style: AppTheme.displayFont(fontSize: 17, color: SakuraHomePalette.textDeep),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final mood in AppMood.values)
                  _MoodPickerOption(
                    mood: mood,
                    isSelected: mood == selected,
                    onTap: () => onSelected(mood),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPickerOption extends StatelessWidget {
  const _MoodPickerOption({required this.mood, required this.isSelected, required this.onTap});

  final AppMood mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? SakuraHomePalette.blossomPink.withValues(alpha: 0.25)
                  : SakuraHomePalette.lavender,
              border: Border.all(
                color: isSelected ? SakuraHomePalette.blossomPink : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Text(mood.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            mood.label(l10n),
            style: AppTheme.bodyFont(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.fraction, required this.l10n});

  final double fraction;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final percent = (fraction * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.track_changes_rounded, color: SakuraHomePalette.blossomPink, size: 20),
          const SizedBox(height: 6),
          Text(
            '$percent%',
            style: AppTheme.displayFont(fontSize: 18, color: SakuraHomePalette.textDeep),
          ),
          Text(
            l10n.homeStatGoalLabel,
            style: AppTheme.bodyFont(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: SakuraHomePalette.lavender,
              valueColor: const AlwaysStoppedAnimation(SakuraHomePalette.blossomPink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfCareTile extends StatelessWidget {
  const _SelfCareTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: SakuraHomePalette.blossomPink, size: 20),
          const SizedBox(height: 6),
          Text(
            l10n.homeStatSelfCareLabel,
            style: AppTheme.bodyFont(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyFont(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: SakuraHomePalette.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
