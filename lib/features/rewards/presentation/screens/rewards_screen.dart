import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../journal/presentation/providers/journal_streak_provider.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../data/rewards_seen_repository.dart';
import '../../domain/rewards.dart';

const _star = Color(0xFFF6B93B);

/// A single achievement badge.
class _Badge {
  const _Badge({
    required this.id,
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  final String id;
  final IconData icon;
  final String title;
  final bool unlocked;
}

class _RewardData {
  const _RewardData(this.progress, this.badges);
  final RewardProgress progress;
  final List<_Badge> badges;

  int get unlockedCount => badges.where((b) => b.unlocked).length;
  Set<String> get unlockedIds =>
      badges.where((b) => b.unlocked).map((b) => b.id).toSet();
}

/// Rewards screen: a star that grows as the user's activity adds up, plus a
/// grid of unlockable badges. Celebrates when a new level or badge is
/// reached since the last visit.
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final _seen = RewardsSeenRepository();
  Timer? _celebrateTimer;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    // Give the local providers a moment to load, then check whether there's
    // a new level or badge worth celebrating.
    _celebrateTimer = Timer(const Duration(milliseconds: 700), _maybeCelebrate);
  }

  @override
  void dispose() {
    _celebrateTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeCelebrate() async {
    if (_celebrated || !mounted) return;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final data = _gather(isTr);

    final seenLevel = await _seen.lastSeenLevel();
    final seenBadges = await _seen.seenBadges();
    if (!mounted) return;

    final leveledUp = data.progress.level > seenLevel;
    final newBadges =
        data.unlockedIds.where((id) => !seenBadges.contains(id)).toList();

    // Persist current state so we only celebrate genuinely new milestones.
    await _seen.save(level: data.progress.level, badgeIds: data.unlockedIds);

    // Skip the very first visit (nothing "seen" yet) to avoid a celebration
    // for pre-existing progress.
    final firstEverVisit = seenLevel == 0 && seenBadges.isEmpty;
    if (firstEverVisit || (!leveledUp && newBadges.isEmpty) || !mounted) return;

    _celebrated = true;
    _showCelebration(
      isTr: isTr,
      level: leveledUp ? data.progress.level : null,
      newBadgeCount: newBadges.length,
    );
  }

  void _showCelebration({
    required bool isTr,
    required int? level,
    required int newBadgeCount,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _CelebrationDialog(
        isTr: isTr,
        level: level,
        newBadgeCount: newBadgeCount,
      ),
    );
  }

  _RewardData _gather(bool isTr) {
    final journaledDays =
        ref.read(journalEntryDaysProvider).valueOrNull?.length ?? 0;
    final streak = ref.read(journalStreakProvider).count;
    final dreams = ref.read(dreamsStreamProvider).valueOrNull?.length ?? 0;
    final goalStreak = ref.read(goalStreakProvider).count;
    final moodCount = ref.read(moodLogProvider).length;
    return _RewardData(
      computeRewardProgress(
        journaledDays: journaledDays,
        streak: streak,
        dreams: dreams,
        goalStreak: goalStreak,
      ),
      _buildBadges(
        isTr: isTr,
        journaledDays: journaledDays,
        streak: streak,
        dreams: dreams,
        goalStreak: goalStreak,
        moodCount: moodCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    final journaledDays =
        ref.watch(journalEntryDaysProvider).valueOrNull?.length ?? 0;
    final streak = ref.watch(journalStreakProvider).count;
    final dreams = ref.watch(dreamsStreamProvider).valueOrNull?.length ?? 0;
    final goalStreak = ref.watch(goalStreakProvider).count;
    final moodCount = ref.watch(moodLogProvider).length;

    final progress = computeRewardProgress(
      journaledDays: journaledDays,
      streak: streak,
      dreams: dreams,
      goalStreak: goalStreak,
    );
    final badges = _buildBadges(
      isTr: isTr,
      journaledDays: journaledDays,
      streak: streak,
      dreams: dreams,
      goalStreak: goalStreak,
      moodCount: moodCount,
    );
    final unlocked = badges.where((b) => b.unlocked).length;

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
                    isTr ? 'Başarılarım' : 'Achievements',
                    style: AppTheme.displayFont(
                      fontSize: 22,
                      color: SakuraHomePalette.textDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StarCard(progress: progress, isTr: isTr),
                      const SizedBox(height: 18),
                      Text(
                        isTr
                            ? 'Rozetler · $unlocked/${badges.length}'
                            : 'Badges · $unlocked/${badges.length}',
                        style: AppTheme.displayFont(
                          fontSize: 17,
                          color: SakuraHomePalette.textDeep,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.86,
                        children: [for (final b in badges) _BadgeCard(badge: b)],
                      ),
                      const SizedBox(height: 8),
                    ],
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

  List<_Badge> _buildBadges({
    required bool isTr,
    required int journaledDays,
    required int streak,
    required int dreams,
    required int goalStreak,
    required int moodCount,
  }) {
    return [
      _Badge(
        id: 'entry1',
        icon: Icons.edit_note_rounded,
        title: isTr ? 'İlk günlük' : 'First entry',
        unlocked: journaledDays >= 1,
      ),
      _Badge(
        id: 'entry10',
        icon: Icons.auto_stories_rounded,
        title: isTr ? '10 günlük' : '10 entries',
        unlocked: journaledDays >= 10,
      ),
      _Badge(
        id: 'entry50',
        icon: Icons.workspace_premium_rounded,
        title: isTr ? '50 günlük' : '50 entries',
        unlocked: journaledDays >= 50,
      ),
      _Badge(
        id: 'streak3',
        icon: Icons.bolt_rounded,
        title: isTr ? '3 gün seri' : '3-day streak',
        unlocked: streak >= 3,
      ),
      _Badge(
        id: 'streak7',
        icon: Icons.local_fire_department_rounded,
        title: isTr ? '7 gün seri' : '7-day streak',
        unlocked: streak >= 7,
      ),
      _Badge(
        id: 'streak30',
        icon: Icons.whatshot_rounded,
        title: isTr ? '30 gün seri' : '30-day streak',
        unlocked: streak >= 30,
      ),
      _Badge(
        id: 'dream1',
        icon: Icons.nights_stay_rounded,
        title: isTr ? 'İlk rüya' : 'First dream',
        unlocked: dreams >= 1,
      ),
      _Badge(
        id: 'dream10',
        icon: Icons.bedtime_rounded,
        title: isTr ? '10 rüya' : '10 dreams',
        unlocked: dreams >= 10,
      ),
      _Badge(
        id: 'mood1',
        icon: Icons.sentiment_satisfied_rounded,
        title: isTr ? 'İlk ruh hali' : 'First mood',
        unlocked: moodCount >= 1,
      ),
      _Badge(
        id: 'mood7',
        icon: Icons.insights_rounded,
        title: isTr ? '7 gün ruh hali' : '7 moods logged',
        unlocked: moodCount >= 7,
      ),
      _Badge(
        id: 'goal7',
        icon: Icons.track_changes_rounded,
        title: isTr ? 'Hedef serisi' : 'Goal streak',
        unlocked: goalStreak >= 7,
      ),
    ];
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({
    required this.isTr,
    required this.level,
    required this.newBadgeCount,
  });

  final bool isTr;
  final int? level;
  final int newBadgeCount;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (level != null) {
      lines.add(isTr ? 'Seviye $level\'e ulaştın!' : 'You reached level $level!');
    }
    if (newBadgeCount > 0) {
      lines.add(isTr
          ? '$newBadgeCount yeni rozet açtın!'
          : 'You unlocked $newBadgeCount new badge${newBadgeCount > 1 ? 's' : ''}!');
    }

    return Dialog(
      backgroundColor: SakuraHomePalette.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, t, child) =>
                  Transform.scale(scale: t, child: child),
              child: const Icon(Icons.star_rounded, size: 76, color: _star),
            ),
            const SizedBox(height: 14),
            Text(
              isTr ? 'Tebrikler!' : 'Congratulations!',
              style: AppTheme.displayFont(
                fontSize: 22,
                color: SakuraHomePalette.textDeep,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SakuraHomePalette.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            PremiumButton(
              label: isTr ? 'Harika!' : 'Awesome!',
              icon: Icons.celebration_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarCard extends StatelessWidget {
  const _StarCard({required this.progress, required this.isTr});

  final RewardProgress progress;
  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3D6), Color(0xFFFDE8EF)],
        ),
        boxShadow: [
          BoxShadow(
            color: _star.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: progress.isMaxLevel ? 1 : progress.fraction,
                    strokeWidth: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    valueColor: const AlwaysStoppedAnimation(_star),
                  ),
                ),
                _GrowingStar(level: progress.level),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isTr ? 'Seviye ${progress.level}' : 'Level ${progress.level}',
            style: AppTheme.displayFont(
              fontSize: 22,
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progress.isMaxLevel
                ? (isTr ? 'En yüksek seviye! ${progress.points} puan' : 'Max level! ${progress.points} pts')
                : (isTr
                    ? 'Sonraki seviyeye ${progress.pointsToNext} puan'
                    : '${progress.pointsToNext} pts to next level'),
            style: AppTheme.bodyFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The star at the heart of the rewards screen: it starts small and grows
/// as the user levels up (which happens by earning achievements), with a
/// soft pulsing glow and twinkling sparkles.
class _GrowingStar extends StatefulWidget {
  const _GrowingStar({required this.level});

  final int level;

  @override
  State<_GrowingStar> createState() => _GrowingStarState();
}

class _GrowingStarState extends State<_GrowingStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  // (alignment, icon size, phase offset) for each sparkle.
  static const List<(Alignment, double, double)> _sparkles = [
    (Alignment(-0.75, -0.55), 12, 0.0),
    (Alignment(0.8, -0.35), 10, 0.35),
    (Alignment(0.55, 0.72), 13, 0.6),
    (Alignment(-0.6, 0.6), 9, 0.85),
  ];

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Small at level 1, growing with each level earned.
    final size = (24 + widget.level * 8).clamp(24, 116).toDouble();
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _twinkle,
            builder: (context, _) {
              final glow = 0.45 + _twinkle.value * 0.4;
              return Container(
                width: size * 1.4,
                height: size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _star.withValues(alpha: 0.35 * glow),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              );
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Icon(Icons.star_rounded, size: size, color: _star),
          ),
          for (final s in _sparkles)
            Align(
              alignment: s.$1,
              child: AnimatedBuilder(
                animation: _twinkle,
                builder: (context, _) {
                  final phase = (_twinkle.value + s.$3) % 1.0;
                  final tw = (math.sin(phase * 2 * math.pi) + 1) / 2;
                  return Opacity(
                    opacity: 0.25 + 0.75 * tw,
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * tw,
                      child: Icon(Icons.auto_awesome,
                          size: s.$2, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final _Badge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFD98E), _star],
                        )
                      : null,
                  color: unlocked ? null : SakuraHomePalette.lavender,
                ),
                child: Icon(
                  badge.icon,
                  size: 24,
                  color: unlocked
                      ? Colors.white
                      : SakuraHomePalette.textMuted.withValues(alpha: 0.55),
                ),
              ),
              if (!unlocked)
                Positioned(
                  right: 8,
                  bottom: 6,
                  child: Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: SakuraHomePalette.textMuted.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyFont(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: unlocked
                  ? SakuraHomePalette.textDeep
                  : SakuraHomePalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
