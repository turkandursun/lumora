import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../activities/presentation/screens/activities_screen.dart';
import '../../../ai_questions/presentation/screens/ai_questions_screen.dart';
import '../../../breathing/presentation/screens/breathing_screen.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../daily_question/presentation/screens/daily_question_screen.dart';
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
      title: l10n.exploreFeatureDailyQuestion,
      description: l10n.homeFeatureDailyQuestionDesc,
      primaryIcon: Icons.help_outline_rounded,
      accentIcon: Icons.auto_awesome_rounded,
      screenBuilder: (_) => const DailyQuestionScreen(),
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

/// A responsive 2-column grid of frosted glass feature cards — the exact same
/// [AstraGlassCard] look as the Journal Writing and Dream Journal cards above,
/// so the whole Home page reads as one cohesive surface with no visual break.
class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({super.key, required this.items, required this.isDark});

  final List<HomeFeatureItem> items;
  final bool isDark;

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
      itemBuilder: (context, index) => _FeatureCard(
        item: items[index],
        isDark: isDark,
      ),
    );
  }
}

/// A feature shortcut card: the shared frosted glass card with an outlined
/// accent icon in the top-right corner and the title + description at the
/// bottom — identical fill, border, blur and text colours to the other Home
/// cards.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item, required this.isDark});

  final HomeFeatureItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = AstraKit.primary(isDark);
    return AstraMorphContainer(
      borderRadius: 20,
      openBuilder: item.screenBuilder,
      closedBuilder: (context, open) => BouncyTap(
      onTap: open,
      child: AstraGlassCard(
      isDark: isDark,
      primaryColor: accent,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: null,
          splashColor: accent.withValues(alpha: 0.14),
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
                    color: accent.withValues(alpha: 0.14),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Icon(item.primaryIcon, size: 20, color: accent),
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
                      style: AstraKit.heading2(isDark, fontSize: 16.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AstraKit.mutedText(isDark, fontSize: 11.5),
                    ),
                    const SizedBox(height: 9),
                    _SparkleDivider(accent: accent),
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
  const _SparkleDivider({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: Container(height: 1, color: accent.withValues(alpha: 0.35)),
        );
    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 5, height: 5, color: accent),
          ),
        ),
        line(),
      ],
    );
  }
}

