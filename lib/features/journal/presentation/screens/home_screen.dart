import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../../profile/presentation/providers/visit_tracker_providers.dart';
import '../providers/journal_entries_provider.dart';
import '../providers/journal_streak_provider.dart';
import '../widgets/dream_journal_banner.dart';
import '../widgets/home_feature_grid.dart';
import '../widgets/home_header.dart';
import '../widgets/home_stats_row.dart';
import '../widgets/motivation_quote_carousel.dart';

/// Home — a personalized greeting + mock weather, a rotating motivational
/// quote, a compact stats row (streak / mood / goal / self-care), a
/// 2-column feature shortcut grid, and a Dream Journal banner, all over the
/// same ASTRA moon/sun scene every other screen uses. Journal writing
/// itself lives on its own dedicated, individually PIN-gateable screen (see
/// [JournalEntryScreen]), reached via the feature grid's "Journal Writing"
/// card.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _didInitialStreakLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialStreakLoad) return;
    _didInitialStreakLoad = true;
    ref.read(journalStreakProvider.notifier).refresh();
    ref.read(journalEntriesRepositoryProvider).fetchAndSyncFromSupabase();
    ref.read(visitDaysCountProvider.notifier).recordAndLoad();
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
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(firstName: firstName),
                  const SizedBox(height: 18),
                  const MotivationQuoteCarousel(),
                  const SizedBox(height: 16),
                  const HomeStatsRow(),
                  const SizedBox(height: 16),
                  const DreamJournalBanner(),
                  const SizedBox(height: 22),
                  HomeFeatureGrid(
                    items: homeFeatureItems(context, ref, l10n),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
