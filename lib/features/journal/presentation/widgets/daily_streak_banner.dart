import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/astra_screen_kit.dart';

/// A slim top strip that celebrates the user's daily streak with a living
/// flame + count and a Mon–Sun week row (past & current days lit, future days
/// dimmed). Theme-aware: a warm ember card on the sun theme, a deep-plum card
/// with a fiery glow on the moon theme. Shown once per day on Home for a few
/// seconds; see `HomeScreen` for the show-once / auto-dismiss logic.
class DailyStreakBanner extends StatelessWidget {
  const DailyStreakBanner({
    super.key,
    required this.count,
    required this.isDark,
    required this.onClose,
  });

  final int count;
  final bool isDark;
  final VoidCallback onClose;

  static const List<Color> _dayColors = [
    Color(0xFFF6971F), // Mon
    Color(0xFFF7C948), // Tue
    Color(0xFF2FB9A6), // Wed
    Color(0xFF57C971), // Thu
    Color(0xFF8B7BD8), // Fri
    Color(0xFF5B9BD5), // Sat
    Color(0xFFE87BA6), // Sun
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));
    DateFormat fmt;
    try {
      fmt = DateFormat('E', locale);
    } catch (_) {
      fmt = DateFormat('E');
    }

    // Follows the selected palette (no more moon/sun split): a light card in
    // the theme colour with a glow in the theme accent.
    final p = AstraKit.active;
    final accent = p?.primary ?? const Color(0xFFCE7CA6);
    final onColor = const Color(0xFF34121F);
    final inactiveDot = const Color(0xFFCBB9D8);
    final bgGradient = [
      p?.gradientTop ?? const Color(0xFFFCE8EE),
      p?.iconContainer ?? const Color(0xFFF6D6E3),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            // Soft glow in the theme accent.
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _FlameBadge(count: count),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 15, color: accent),
                      const SizedBox(width: 5),
                      Text(
                        l10n.homeStreakBannerTitle.toUpperCase(),
                        style: AppTheme.bodyFont(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: onColor,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 7; i++)
                        _DayDot(
                          label: fmt.format(monday.add(Duration(days: i))),
                          color: _dayColors[i],
                          inactiveColor: inactiveDot,
                          textColor: onColor,
                          active: (i + 1) <= now.weekday,
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
              icon: Icon(Icons.close_rounded,
                  size: 18, color: onColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A softly pulsing flame badge with the streak count in the centre.
class _FlameBadge extends StatefulWidget {
  const _FlameBadge({required this.count});

  final int count;

  @override
  State<_FlameBadge> createState() => _FlameBadgeState();
}

class _FlameBadgeState extends State<_FlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
        final p = AstraKit.active;
        final badgeGradient = [
          p?.buttonPrimary ?? const Color(0xFFEAAAC8),
          p?.primary ?? const Color(0xFFCE7CA6),
          p?.secondary ?? const Color(0xFFB35C82),
        ];
        final glow = p?.primary ?? const Color(0xFFCE7CA6);
        return Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: badgeGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.35 + 0.30 * t),
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
              size: 42, color: Colors.white.withValues(alpha: 0.30)),
          Text('${widget.count}',
              style: AppTheme.bodyFont(
                  fontSize: 18,
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
    required this.color,
    required this.inactiveColor,
    required this.textColor,
    required this.active,
    required this.isToday,
  });

  final String label;
  final Color color;
  final Color inactiveColor;
  final Color textColor;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : inactiveColor.withValues(alpha: 0.5),
            border: isToday
                ? Border.all(
                    color: AstraKit.active?.primary ?? const Color(0xFFCE7CA6),
                    width: 2)
                : null,
            boxShadow: active
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 0.5)
                  ]
                : null,
          ),
          child: active
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodyFont(
            fontSize: 9.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            color: textColor.withValues(alpha: active ? 0.95 : 0.55),
          ),
        ),
      ],
    );
  }
}
