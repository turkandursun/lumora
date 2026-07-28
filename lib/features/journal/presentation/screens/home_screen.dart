import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../providers/journal_streak_provider.dart';
import '../widgets/dream_journal_banner.dart';
import '../widgets/home_feature_grid.dart';
import '../widgets/home_header.dart';
import '../../../../theme/app_background.dart';
import '../widgets/home_stats_row.dart';
import '../widgets/motivation_quote_carousel.dart';

/// Home — a light, pastel "spring morning" screen: a personalized greeting
/// + mock weather, a rotating motivational quote, a compact stats row
/// (streak / mood / goal / self-care), a 3-column feature shortcut grid,
/// and a Dream Journal banner. Journal writing itself lives on its own
/// dedicated, individually PIN-gateable screen (see [JournalEntryScreen]),
/// reached via the feature grid's "Journal Writing" card.
///
/// Deliberately does not use [MoodGradientBackground]/[LumaCompanion] the
/// way every other screen does — Home gets its own [HomeMoodBackground]:
/// a mood-matched photo backdrop instead of the app's usual night-sky world.
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

    return Scaffold(
      backgroundColor: SakuraHomePalette.cream,
      body: AppBackground(
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
                  const SizedBox(height: 22),
                  HomeFeatureGrid(
                    items: homeFeatureItems(context, ref, l10n),
                  ),
                  const SizedBox(height: 16),
                  const DreamJournalBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
