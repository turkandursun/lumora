import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/luma_chat_sheet.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../app_lock/domain/app_section.dart';
import '../../../app_lock/presentation/widgets/section_lock_gate.dart';
import '../../../reminders/presentation/providers/reminders_providers.dart';
import '../../../shell/presentation/widgets/feature_coming_soon_screen.dart';

/// One tappable card in the Home feature grid.
class HomeFeatureItem {
  const HomeFeatureItem({
    required this.title,
    required this.description,
    required this.primaryIcon,
    this.accentIcon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String title;
  final String description;
  final IconData primaryIcon;
  final IconData? accentIcon;
  final VoidCallback onTap;
  final int badgeCount;
}

/// The eleven feature shortcuts shown directly on Home, in display order.
List<HomeFeatureItem> homeFeatureItems(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
  void openComingSoon(IconData icon, String title) {
    context.push(
      AppRoutes.featureComingSoon,
      extra: FeatureComingSoonArgs(icon: icon, title: title),
    );
  }

  final reminders = ref.watch(remindersStreamProvider).maybeWhen(
        data: (rows) => rows.where((r) => r.enabled).length,
        orElse: () => 0,
      );

  final isTr = Localizations.localeOf(context).languageCode == 'tr';

  return [
    HomeFeatureItem(
      title: isTr ? 'Takvim' : 'Calendar',
      description: isTr ? 'Günlük & regl takibi' : 'Daily & period tracking',
      primaryIcon: Icons.calendar_month_rounded,
      accentIcon: Icons.water_drop_rounded,
      onTap: () => context.push(AppRoutes.calendar),
    ),
    HomeFeatureItem(
      title: isTr ? 'Etkinliklerim' : 'My activities',
      description: isTr ? 'Fotoğraflı günlük' : 'Log with photos',
      primaryIcon: Icons.photo_camera_back_rounded,
      accentIcon: Icons.groups_rounded,
      onTap: () => context.push(AppRoutes.activities),
    ),
    HomeFeatureItem(
      title: isTr ? 'Başarılarım' : 'Achievements',
      description: isTr ? 'Yıldız & rozetler' : 'Star & badges',
      primaryIcon: Icons.star_rounded,
      accentIcon: Icons.emoji_events_rounded,
      onTap: () => context.push(AppRoutes.rewards),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureJournalTitle,
      description: l10n.homeFeatureJournalDesc,
      primaryIcon: Icons.menu_book_rounded,
      accentIcon: Icons.edit_rounded,
      onTap: () => context.push(AppRoutes.journalEntry),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureAiQuestionsTitle,
      description: l10n.homeFeatureAiQuestionsDesc,
      primaryIcon: Icons.psychology_alt_rounded,
      accentIcon: Icons.question_mark_rounded,
      onTap: () => context.push(AppRoutes.aiQuestions),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureMeditationTitle,
      description: l10n.homeFeatureMeditationDesc,
      primaryIcon: Icons.self_improvement_rounded,
      onTap: () => context.push(AppRoutes.meditation),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureBreathingTitle,
      description: l10n.homeFeatureBreathingDesc,
      primaryIcon: Icons.air_rounded,
      onTap: () => context.push(AppRoutes.breathing),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureAiChatTitle,
      description: l10n.homeFeatureAiChatDesc,
      primaryIcon: Icons.chat_bubble_rounded,
      accentIcon: Icons.auto_awesome_rounded,
      onTap: () async {
        final unlocked = await ensureSectionUnlocked(context, ref, AppSection.aiChat);
        if (!unlocked || !context.mounted) return;
        LumaChatSheet.show(context);
      },
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureGoalsTitle,
      description: l10n.homeFeatureGoalsDesc,
      primaryIcon: Icons.track_changes_rounded,
      onTap: () => context.push(AppRoutes.goals),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureRemindersTitle,
      description: l10n.homeFeatureRemindersDesc,
      primaryIcon: Icons.notifications_rounded,
      badgeCount: reminders,
      onTap: () => context.push(AppRoutes.reminders),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureGratitudeTitle,
      description: l10n.homeFeatureGratitudeDesc,
      primaryIcon: Icons.volunteer_activism_rounded,
      onTap: () => context.push(AppRoutes.gratitude),
    ),
    HomeFeatureItem(
      title: l10n.homeFeatureLetterTitle,
      description: l10n.homeFeatureLetterDesc,
      primaryIcon: Icons.mail_rounded,
      accentIcon: Icons.favorite_rounded,
      onTap: () => context.push(AppRoutes.letters),
    ),
    HomeFeatureItem(
      title: l10n.exploreFeatureDailyQuestion,
      description: l10n.homeFeatureDailyQuestionDesc,
      primaryIcon: Icons.help_outline_rounded,
      accentIcon: Icons.auto_awesome_rounded,
      onTap: () => context.push(AppRoutes.dailyQuestion),
    ),
    HomeFeatureItem(
      title: l10n.exploreFeatureCommunity,
      description: l10n.homeFeatureCommunityDesc,
      primaryIcon: Icons.diversity_3_rounded,
      accentIcon: Icons.favorite_rounded,
      onTap: () => context.push(AppRoutes.community),
    ),
  ];
}

/// Alternating soft pastel duotone backgrounds for the icon badges, so
/// neighboring cards read as gentle variety rather than a repeated tile.
const _iconGradients = [
  [SakuraHomePalette.blossomPink, SakuraHomePalette.petalPink],
  [Color(0xFFC4B5FD), Color(0xFFE9D8FD)],
  [Color(0xFFFBCFE8), Color(0xFFFFE4F1)],
];

/// A responsive 3-column grid of soft pastel illustrated feature cards.
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
      itemBuilder: (context, index) => _FeatureCard(
        item: items[index],
        gradient: _iconGradients[index % _iconGradients.length],
      ),
    );
  }
}

/// A large, image-style feature card: a soft gradient panel with a big
/// ghosted icon and the title + description overlaid at the bottom.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item, required this.gradient});

  final HomeFeatureItem item;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Stack(
            children: [
              // Large ghosted feature icon as the card's "artwork".
              Positioned(
                right: -14,
                top: -8,
                child: Icon(
                  item.primaryIcon,
                  size: 104,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              if (item.accentIcon != null)
                Positioned(
                  left: 14,
                  top: 14,
                  child: Icon(
                    item.accentIcon,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              if (item.badgeCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
              Positioned(
                left: 14,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.displayFont(
                        fontSize: 16,
                        color: SakuraHomePalette.textDeep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: SakuraHomePalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A primary filled icon on a soft pastel duotone circle, with a small
/// accent glyph tucked in its corner and an optional numeric badge.
class _FeatureIconBadge extends StatelessWidget {
  const _FeatureIconBadge({required this.item, required this.gradient});

  final HomeFeatureItem item;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(item.primaryIcon, color: Colors.white, size: 18),
          ),
          if (item.accentIcon != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: SakuraHomePalette.cardWhite,
                ),
                child: Icon(item.accentIcon, color: gradient.first, size: 10),
              ),
            ),
          if (item.badgeCount > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: SakuraHomePalette.cardWhite, width: 1.5),
                ),
                child: Text(
                  item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
