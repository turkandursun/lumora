/// Turns the user's activity into points, a level and progress toward the
/// next level — the numbers behind the "growing star". Pure Dart so it can
/// be unit-tested without any widgets.
class RewardProgress {
  const RewardProgress({
    required this.points,
    required this.level,
    required this.pointsIntoLevel,
    required this.pointsToNext,
    required this.fraction,
    required this.isMaxLevel,
  });

  final int points;

  /// 1-based level shown to the user.
  final int level;

  final int pointsIntoLevel;
  final int pointsToNext;

  /// 0–1 progress toward the next level.
  final double fraction;

  final bool isMaxLevel;
}

/// Cumulative point thresholds for each level. Reaching a threshold levels
/// the star up.
const List<int> _thresholds = [
  0, 50, 120, 220, 350, 520, 750, 1050, 1400, 1800, 2300,
];

/// Point weights per activity — journaling and streaks are worth the most,
/// since daily use is what we most want to encourage.
RewardProgress computeRewardProgress({
  required int journaledDays,
  required int streak,
  required int dreams,
  required int goalStreak,
}) {
  final points = journaledDays * 10 +
      streak * 5 +
      dreams * 8 +
      goalStreak * 5;

  var levelIndex = 0;
  for (var i = 0; i < _thresholds.length; i++) {
    if (points >= _thresholds[i]) levelIndex = i;
  }

  final isMax = levelIndex >= _thresholds.length - 1;
  final base = _thresholds[levelIndex];
  final next = isMax ? base : _thresholds[levelIndex + 1];
  final span = next - base;
  final into = points - base;
  final fraction = (isMax || span <= 0) ? 1.0 : (into / span).clamp(0.0, 1.0);

  return RewardProgress(
    points: points,
    level: levelIndex + 1,
    pointsIntoLevel: into,
    pointsToNext: isMax ? 0 : next - points,
    fraction: fraction.toDouble(),
    isMaxLevel: isMax,
  );
}
