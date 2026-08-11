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

/// Home's header: a small date + weather "eyebrow" line above a soft, elegant
/// time-of-day greeting, plus a notification bell that badges when a reminder
/// is enabled. Theme-aware: warm light text + lavender accent on the dark/moon
/// scene, deep-ink text + gold accent on the light/sun scene, so it stays
/// legible — and feels premium — in both.
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
    final dateLabel = DateFormat('d MMMM · EEEE', locale).format(now).toUpperCase();
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The greeting lands first...
        Expanded(
          child: AstraEntrance(
            offset: 16,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow: quiet date label + a soft weather chip.
              Row(
                children: [
                  Flexible(
                    child: Text(
                      dateLabel,
                      style: AstraKit.body(isDark, fontSize: 11, fontWeight: FontWeight.w600)
                          .copyWith(
                            color: AstraKit.muted(isDark),
                            letterSpacing: 1.4,
                            shadows: [textShadow],
                          ),
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
              const SizedBox(height: 7),
              // Hero greeting — larger, airier, with a gently glowing sparkle.
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _timeOfDayGreeting(l10n, now, firstName),
                      style: AstraKit.heading1(isDark, fontSize: 26, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.2, height: 1.1, shadows: [textShadow]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.auto_awesome,
                    color: accent,
                    size: 17,
                    shadows: [
                      Shadow(color: accent.withValues(alpha: 0.55), blurRadius: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33231845) : const Color(0xB3FCF4E2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reading.condition.icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            reading.roundedTemperature,
            style: AstraKit.body(isDark, fontSize: 11.5, fontWeight: FontWeight.w700)
                .copyWith(letterSpacing: 0.2),
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
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.22 : 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
        color: isDark ? const Color(0x40231845) : const Color(0xD9FCF4E2),
        shape: CircleBorder(side: BorderSide(color: accent.withValues(alpha: 0.32))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
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
      ),
    );
  }
}
