import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../reminders/presentation/providers/reminders_providers.dart';
import '../providers/weather_provider.dart';

String _timeOfDayGreeting(AppLocalizations l10n, DateTime now, String? name) {
  final hour = now.hour;
  if (hour < 12) {
    return name == null ? l10n.homeGreetingMorningNoName : l10n.homeGreetingMorning(name);
  }
  if (hour < 18) {
    return name == null ? l10n.homeGreetingAfternoonNoName : l10n.homeGreetingAfternoon(name);
  }
  return name == null ? l10n.homeGreetingEveningNoName : l10n.homeGreetingEvening(name);
}

/// Home's header: a time-of-day greeting, the date + day name + a mock
/// weather chip, and a notification bell that badges when a reminder is
/// enabled. Theme-aware: white text + lavender accent on the dark/moon scene,
/// dark text + gold accent on the light/sun scene, so it stays legible in both.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = DateFormat('d MMMM yyyy · EEEE', locale).format(now);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final accent = AstraKit.primary(isDark);
    // A soft halo lifts the text off the busy photo — dark on the light scene,
    // light on the dark scene.
    final textShadow = Shadow(
      color: isDark ? const Color(0x99000000) : const Color(0x66FFFFFF),
      blurRadius: 8,
      offset: const Offset(0, 1),
    );
    final weatherAsync = ref.watch(weatherReadingProvider);
    final hasUnreadReminders = ref.watch(remindersStreamProvider).maybeWhen(
          data: (rows) => rows.any((r) => r.enabled),
          orElse: () => false,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The greeting lands first...
        Expanded(
          child: AstraEntrance(
            offset: 16,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _timeOfDayGreeting(l10n, now, firstName),
                      style: AstraKit.heading1(isDark, fontSize: 22).copyWith(shadows: [textShadow]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.auto_awesome, color: accent, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      dateLabel,
                      style: AstraKit.body(isDark, fontSize: 12.5, fontWeight: FontWeight.w600).copyWith(shadows: [textShadow]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  weatherAsync.when(
                    data: (reading) => _WeatherChip(reading: reading, isDark: isDark, accent: accent),
                    loading: () => SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.6, color: accent),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
        const SizedBox(width: 10),
        // ...then the bell.
        AstraEntrance(
          delayMs: 90,
          offset: 16,
          child: _NotificationBell(
          hasUnread: hasUnreadReminders,
          isDark: isDark,
          accent: accent,
          onTap: () => context.push(AppRoutes.reminders),
        ),
        ),
      ],
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.reading, required this.isDark, required this.accent});

  final WeatherReading reading;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x44231845) : const Color(0xCCFCF4E2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reading.condition.icon, size: 13, color: accent),
          const SizedBox(width: 4),
          Text(
            reading.roundedTemperature,
            style: AstraKit.body(isDark, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasUnread, required this.isDark, required this.accent, required this.onTap});

  final bool hasUnread;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.homeNotificationBellLabel,
      child: Material(
        color: isDark ? const Color(0x44231845) : const Color(0xCCFCF4E2),
        shape: CircleBorder(side: BorderSide(color: accent.withValues(alpha: 0.4))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, color: accent, size: 20),
                if (hasUnread)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
