import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_glass_theme.dart';
import '../../../reminders/presentation/providers/reminders_providers.dart';

String _timeOfDayGreeting(AppLocalizations l10n, DateTime now, String? name) {
  final hour = now.hour;
  if (hour < 12) {
    return name == null
        ? l10n.homeGreetingMorningNoName
        : l10n.homeGreetingMorning(name);
  }
  if (hour < 18) {
    return name == null
        ? l10n.homeGreetingAfternoonNoName
        : l10n.homeGreetingAfternoon(name);
  }
  return name == null
      ? l10n.homeGreetingEveningNoName
      : l10n.homeGreetingEvening(name);
}

/// Home's header: a small date + weather "eyebrow" line above a soft, elegant
/// time-of-day greeting, plus a notification bell that badges when a reminder
/// is enabled. Restyled (Aug 2026) onto the fixed [LumaGlass] pink theme —
/// no photo behind it anymore, so the old moon/sun text shadows are gone;
/// layout/content is otherwise unchanged from the original Home header.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    // Editorial "eyebrow" line — upper-cased and letter-spaced so it reads as a
    // quiet label rather than a heavy second heading.
    final dateLabel =
        DateFormat('d MMMM · EEEE', locale).format(now).toUpperCase();
    final hasUnreadReminders = ref.watch(remindersStreamProvider).maybeWhen(
          data: (rows) => rows.any((r) => r.enabled),
          orElse: () => false,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The greeting lands first...
        Expanded(
          child: AstraEntrance(
            offset: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow: a quiet date label.
                Text(
                  dateLabel,
                  style: LumaGlass.sans(context,
                          fontSize: 11, fontWeight: FontWeight.w600)
                      .copyWith(
                          color: LumaGlass.subtitle(context),
                          letterSpacing: 1.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                // Hero greeting — larger, airier, with a gently glowing sparkle.
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _timeOfDayGreeting(l10n, now, firstName),
                        style: LumaGlass.sans(context,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: LumaGlass.heroInk(context))
                            .copyWith(letterSpacing: 0.2, height: 1.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.auto_awesome,
                      color: LumaGlass.sparkle(context),
                      size: 17,
                      shadows: [
                        Shadow(
                            color: LumaGlass.sparkle(context)
                                .withValues(alpha: 0.55),
                            blurRadius: 12),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ...then the bell.
        AstraEntrance(
          delayMs: 90,
          offset: 16,
          child: _NotificationBell(
            hasUnread: hasUnreadReminders,
            onTap: () => context.push(AppRoutes.reminders),
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.homeNotificationBellLabel,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: LumaGlass.sparkle(context).withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white.withValues(alpha: 0.55),
          shape: CircleBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: LumaGlass.sparkle(context), size: 20),
                  if (hasUnread)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFEF4444)),
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
