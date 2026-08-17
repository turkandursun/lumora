import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_glass_theme.dart';
import '../../../activities/presentation/screens/activities_screen.dart';
import '../../../ai_questions/presentation/screens/ai_questions_screen.dart';
import '../../../breathing/presentation/screens/breathing_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../dilemma/presentation/screens/dilemma_swipe_screen.dart';
import '../../../letters/presentation/screens/letters_screen.dart';
import '../../../meditation/presentation/screens/meditation_screen.dart';

/// One tappable card in the Home feature grid. [screenBuilder] is the
/// destination the card morphs open into (container transform).
class HomeFeatureItem {
  const HomeFeatureItem({
    required this.title,
    required this.description,
    required this.primaryIcon,
    this.accentIcon,
    required this.screenBuilder,
    this.badgeCount = 0,
  });

  final String title;
  final String description;
  final IconData primaryIcon;
  final IconData? accentIcon;
  final WidgetBuilder screenBuilder;
  final int badgeCount;
}

/// The feature shortcuts shown directly on Home, in display order.
List<HomeFeatureItem> homeFeatureItems(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  final isTr = Localizations.localeOf(context).languageCode == 'tr';

  return [
    HomeFeatureItem(
      title: isTr ? 'Takvim' : 'Calendar',
      description: isTr ? 'Günlük & ruh hali' : 'Journal & moods',
      primaryIcon: Icons.calendar_month_rounded,
      accentIcon: Icons.wb_sunny_rounded,
      screenBuilder: (_) => const CalendarScreen(),
    ),
    HomeFeatureItem(
      title: isTr ? 'Etkinliklerim' : 'My activities',
      description: isTr ? 'Fotoğraflı günlük' : 'Log with photos',
      primaryIcon: Icons.photo_camera_back_rounded,
      accentIcon: Icons.groups_rounded,
      screenBuilder: (_) => const ActivitiesScreen(),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureAiQuestionsTitle,
      description: l10n.homeFeatureAiQuestionsDesc,
      primaryIcon: Icons.psychology_alt_rounded,
      accentIcon: Icons.question_mark_rounded,
      screenBuilder: (_) => const AiQuestionsScreen(),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureMeditationTitle,
      description: l10n.homeFeatureMeditationDesc,
      primaryIcon: Icons.self_improvement_rounded,
      screenBuilder: (_) => const MeditationScreen(),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureBreathingTitle,
      description: l10n.homeFeatureBreathingDesc,
      primaryIcon: Icons.air_rounded,
      screenBuilder: (_) => const BreathingScreen(),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureLetterTitle,
      description: l10n.homeFeatureLetterDesc,
      primaryIcon: Icons.mail_rounded,
      accentIcon: Icons.favorite_rounded,
      screenBuilder: (_) => const LettersScreen(),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureDilemmaTitle,
      description: l10n.homeFeatureDilemmaDesc,
      primaryIcon: Icons.swipe_rounded,
      accentIcon: Icons.balance_rounded,
      screenBuilder: (_) => const DilemmaSwipeScreen(),
    ),
    HomeFeatureItem(
      title: l10n.exploreFeatureCommunity,
      description: l10n.homeFeatureCommunityDesc,
      primaryIcon: Icons.diversity_3_rounded,
      accentIcon: Icons.favorite_rounded,
      screenBuilder: (_) => const CommunityScreen(),
    ),
  ];
}

/// A responsive 2-column grid of frosted pink glass feature cards — restyled
/// (Aug 2026) onto [LumaGlassCard] so the whole Home page reads as one
/// cohesive pink surface; layout/content is otherwise the original grid.
class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key, required this.items});

  final List<HomeFeatureItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) => _FeatureCard(item: items[index]),
    );
  }
}

/// A feature shortcut card: the shared frosted pink glass card with an
/// outlined accent icon in the top-right corner and the title + description
/// at the bottom — identical fill, border, blur and text colours to the
/// other Home cards.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item});

  final HomeFeatureItem item;

  @override
  Widget build(BuildContext context) {
    return AstraMorphContainer(
      borderRadius: 20,
      openBuilder: item.screenBuilder,
      closedBuilder: (context, open) => BouncyTap(
      onTap: open,
      child: LumaGlassCard(
      padding: EdgeInsets.zero,
      radius: 20,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: null,
          splashColor: LumaGlass.sparkle.withValues(alpha: 0.14),
          child: Stack(
            children: [
              // Outlined accent icon circle in the top-right corner.
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LumaGlass.sparkle.withValues(alpha: 0.14),
                    border: Border.all(
                        color: LumaGlass.sparkle.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Icon(item.primaryIcon, size: 20, color: LumaGlass.sparkle),
                ),
              ),
              if (item.badgeCount > 0)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Title + description + a small sparkle divider, at the bottom.
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LumaGlass.sans(fontSize: 16.5, fontWeight: FontWeight.w700, color: LumaGlass.cardTitle),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LumaGlass.sans(fontSize: 11.5, color: LumaGlass.subtitle),
                    ),
                    const SizedBox(height: 9),
                    const _SparkleDivider(),
                  ],
                ),
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

/// A hairline divider with a small diamond sparkle in the middle, echoing
/// the ornamental line under each card's title.
class _SparkleDivider extends StatelessWidget {
  const _SparkleDivider();

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
          height: 1,
          color: LumaGlass.sparkle.withValues(alpha: 0.35),
        );
    return Row(
      children: [
        Expanded(child: line()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 5, height: 5, color: LumaGlass.sparkle),
          ),
        ),
        Expanded(child: line()),
      ],
    );
  }
}
