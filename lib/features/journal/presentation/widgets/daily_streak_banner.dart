import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/astra_design_tokens.dart';

/// A slim top strip that celebrates the user's daily streak: a softly pulsing
/// flame badge with the count, a warm encouraging line, and a Mon–Sun week row
/// (completed & current days filled, future days outlined). Fully theme-aware —
/// it borrows the app's rose/plum palette so it feels native in both light and
/// dark mode instead of a stray orange card. Shown once per day on Home for a
/// few seconds; see `HomeScreen` for the show-once / auto-dismiss logic.
class DailyStreakBanner extends StatelessWidget {
  const DailyStreakBanner({
    super.key,
    required this.count,
    required this.visitedDateKeys,
    required this.isDark,
    required this.onClose,
  });

  final int count;
  final Set<String> visitedDateKeys;
  final bool isDark;
  final VoidCallback onClose;

  /// A short, warm nudge that scales with how long the streak is.
  String _encouragement(bool isTr) {
    if (count <= 1) {
      return isTr
          ? 'Serin başladı — devam et!'
          : 'Your streak has begun — keep going!';
    }
    if (count < 7) {
      return isTr
          ? '$count gün üst üste, harika gidiyorsun!'
          : '$count days in a row — you\'re doing great!';
    }
    if (count < 30) {
      return isTr
          ? '$count günlük seri! Kendinle gurur duy.'
          : '$count-day streak! Be proud of yourself.';
    }
    return isTr
        ? '$count gün! Bu inanılmaz bir alışkanlık.'
        : '$count days! What an incredible habit.';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isTr = locale == 'tr';
    final tokens = AstraThemeTokens.of(context);
    final palette = tokens.palette;
    final accent = palette.activeAccent;
    final deep = palette.secondary;

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    DateFormat fmt;
    try {
      fmt = DateFormat('E', locale);
    } catch (_) {
      fmt = DateFormat('E');
    }

    final onColor = tokens.textPrimary;
    final mutedColor = tokens.textMuted;
    final inactiveDot = mutedColor.withValues(alpha: isDark ? 0.34 : 0.30);

    // Fully-opaque base so the banner never blends with the page behind it
    // (palette.cardBackground is intentionally translucent; surfaceElevated
    // is solid). alpha:1.0 guards against any residual transparency.
    final baseCard = palette.surfaceElevated.withValues(alpha: 1.0);
    final bgGradient = isDark
        ? [
            (Color.lerp(baseCard, accent, 0.16) ?? baseCard)
                .withValues(alpha: 1.0),
            baseCard,
          ]
        : [
            (Color.lerp(baseCard, accent, 0.12) ?? baseCard)
                .withValues(alpha: 1.0),
            baseCard,
          ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.42 : 0.45),
            width: 1.2,
          ),
          boxShadow: [
            // A soft rose glow so the strip feels alive and celebratory.
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.32 : 0.24),
              blurRadius: 24,
              spreadRadius: -3,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _FlameBadge(count: count, accent: accent, deep: deep),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 15, color: accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          l10n.homeStreakBannerTitle.toUpperCase(),
                          style: AppTheme.bodyFont(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: onColor,
                          ).copyWith(letterSpacing: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _encouragement(isTr),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onColor.withValues(alpha: 0.72),
                    ).copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 7; i++)
                        _DayDot(
                          label: fmt.format(monday.add(Duration(days: i))),
                          accent: accent,
                          deep: deep,
                          inactiveColor: inactiveDot,
                          textColor: onColor,
                          active: visitedDateKeys.contains(
                            _localDateKey(monday.add(Duration(days: i))),
                          ),
                          isToday: (i + 1) == now.weekday,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: Icon(Icons.close_rounded,
                  size: 18, color: onColor.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }

  static String _localDateKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

/// A softly pulsing rose flame badge with the streak count in the centre.
class _FlameBadge extends StatefulWidget {
  const _FlameBadge({
    required this.count,
    required this.accent,
    required this.deep,
  });

  final int count;
  final Color accent;
  final Color deep;

  @override
  State<_FlameBadge> createState() => _FlameBadgeState();
}

class _FlameBadgeState extends State<_FlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color.lerp(widget.accent, Colors.white, 0.22) ?? widget.accent,
                widget.accent,
                widget.deep,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.35 + 0.30 * t),
                blurRadius: 14 + 10 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: 44, color: Colors.white.withValues(alpha: 0.28)),
          Text('${widget.count}',
              style: AppTheme.bodyFont(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.accent,
    required this.deep,
    required this.inactiveColor,
    required this.textColor,
    required this.active,
    required this.isToday,
  });

  final String label;
  final Color accent;
  final Color deep;
  final Color inactiveColor;
  final Color textColor;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final double size = isToday ? 25 : 22;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active
                ? LinearGradient(
                    colors: [accent, deep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.transparent,
            border: Border.all(
              color: active
                  ? (isToday ? Colors.white : Colors.transparent)
                  : inactiveColor,
              width: isToday && active ? 2 : 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: isToday ? 0.65 : 0.45),
                      blurRadius: isToday ? 9 : 6,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: active
              ? Icon(Icons.check_rounded,
                  size: isToday ? 15 : 13, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodyFont(
            fontSize: 9.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: textColor.withValues(alpha: active ? 0.95 : 0.5),
          ),
        ),
      ],
    );
  }
}
