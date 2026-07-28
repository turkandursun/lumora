import 'package:shared_preferences/shared_preferences.dart';

const _levelKey = 'rewards_seen_level_v1';
const _badgesKey = 'rewards_seen_badges_v1';

/// Remembers the level and badge ids the user has already been celebrated
/// for, so the rewards screen only fires a celebration when something is
/// genuinely new.
class RewardsSeenRepository {
  Future<int> lastSeenLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey) ?? 0;
  }

  Future<Set<String>> seenBadges() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_badgesKey) ?? const []).toSet();
  }

  Future<void> save({required int level, required Set<String> badgeIds}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_levelKey, level);
    await prefs.setStringList(_badgesKey, badgeIds.toList());
  }
}
