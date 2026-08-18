import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_glass_theme.dart';
import '../../../../theme/responsive_content.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../profile/presentation/providers/visit_tracker_providers.dart';
import '../providers/journal_entries_provider.dart';
import '../providers/journal_streak_provider.dart';
import '../widgets/daily_streak_banner.dart';
import '../widgets/dream_journal_banner.dart';
import '../widgets/home_feature_grid.dart';
import '../widgets/home_header.dart';
import '../widgets/home_stats_row.dart';
import '../widgets/motivation_quote_carousel.dart';

/// Home — a personalized greeting + mock weather, a rotating motivational
/// quote, a Journal Writing hero card, a 2-column feature shortcut grid, and
/// a Dream Journal banner. Restyled (Aug 2026) onto the fixed [LumaGlass]
/// pink glassmorphism theme — a flat pink wash instead of the ASTRA
/// mountain photo, and every card swapped from [AstraGlassCard] to
/// [LumaGlassCard] — while keeping this screen's original layout, section
/// order and content exactly as they were. Journal writing itself lives on
/// its own dedicated, individually PIN-gateable screen (see
/// [JournalEntryScreen]), reached via the feature grid's "Journal Writing"
/// card.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _didInitialStreakLoad = false;

  static const _streakBannerDateKey = 'streak_banner_shown_date';
  bool _showStreakBanner = false;
  Timer? _bannerTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialStreakLoad) return;
    _didInitialStreakLoad = true;
    ref.read(journalStreakProvider.notifier).refresh();
    ref.read(journalEntriesRepositoryProvider).fetchAndSyncFromSupabase();
    ref.read(dreamsRepositoryProvider).fetchAndSyncDreamsFromSupabase();
    ref.read(visitDaysCountProvider.notifier).load();
    _maybeShowStreakBanner();
  }

  /// Shows the streak strip at most once per calendar day, auto-hiding after
  /// ~8 seconds (or when the user taps close).
  Future<void> _maybeShowStreakBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (prefs.getString(_streakBannerDateKey) == todayKey) return;
    await prefs.setString(_streakBannerDateKey, todayKey);
    if (!mounted) return;
    setState(() => _showStreakBanner = true);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 8), _hideStreakBanner);
  }

  void _hideStreakBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _showStreakBanner = false);
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  String? get _userFirstName {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fullName = (metadata?['full_name'] as String?)?.trim();
    if (fullName == null || fullName.isEmpty) return null;
    return fullName.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final firstName = _userFirstName;
    // "Daily streak" here means how many days the user has shown up — the same
    // visit-day counter the rest of the app uses — not the journaling streak.
    final streakCount = ref.watch(visitDaysCountProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    // Only [DailyStreakBanner] (an intentionally distinct fiery-orange
    // celebratory toast, left as-is) still needs the moon/sun flag — every
    // other surface on this screen is fixed pink now.
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          LumaGlassBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: ResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header runs its own greeting → bell cascade first; the
                      // rest of the page then slides up in sequence after it.
                      HomeHeader(firstName: firstName),
                      const SizedBox(height: 18),
                      const AstraEntrance(delayMs: 160, child: MotivationQuoteCarousel()),
                      const SizedBox(height: 16),
                      const AstraEntrance(delayMs: 210, child: HomeStatsRow()),
                      const SizedBox(height: 16),
                      const AstraEntrance(delayMs: 260, child: DreamJournalBanner()),
                      const SizedBox(height: 22),
                      AstraEntrance(
                        delayMs: 310,
                        child: HomeFeatureGrid(
                          items: homeFeatureItems(context, ref, l10n),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Once-a-day streak strip that slides in at the very top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                ignoring: !_showStreakBanner,
                child: AnimatedSlide(
                  offset: _showStreakBanner
                      ? Offset.zero
                      : const Offset(0, -1.4),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _showStreakBanner ? 1 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: DailyStreakBanner(
                        count: streakCount,
                        isDark: isDark,
                        onClose: _hideStreakBanner,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
