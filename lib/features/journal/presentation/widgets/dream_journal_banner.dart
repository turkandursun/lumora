import 'dart:math';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_glass_theme.dart';
import '../../../dreams/presentation/screens/dream_journal_screen.dart';

/// Full-width "Rüya Günlüğü" (Dream Journal) banner — a frosted pink glass
/// card (restyled Aug 2026 onto [LumaGlass], matching the rest of Home)
/// with a small moon-and-stars illustration.
class DreamJournalBanner extends ConsumerWidget {
  const DreamJournalBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Theme-aware moon colour: the brightness-adjusted palette accent, so the
    // crescent stays a soft, pretty moon in both light and dark themes
    // (previously a fixed bronze that read as an ugly orange blob in the dark).
    final accent = AstraKit.primary(context, false);

    // Container transform: tapping the banner morphs the card itself outward
    // until it fills the whole Dream Journal screen (and back again on pop),
    // instead of a normal page push.
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 460),
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      middleColor: Colors.transparent,
      closedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      openBuilder: (context, _) => const DreamJournalScreen(),
      closedBuilder: (context, openContainer) => BouncyTap(
        onTap: openContainer,
        child: LumaGlassCard(
          padding: const EdgeInsets.all(18),
          radius: 22,
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _MoonStarsPainter(
                    moonColor: accent,
                    starColor: accent.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeDreamJournalTitle,
                      style: LumaGlass.sans(context,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: LumaGlass.cardTitle(context)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.homeDreamJournalDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LumaGlass.sans(context,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: LumaGlass.subtitle(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: LumaGlass.sparkle(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fixed deep-bronze moon + warm stars — tuned for the light pink glass card
/// (the banner no longer switches with the moon/sun app theme, so this no
/// longer takes an `isDark` flag).
class _MoonStarsPainter extends CustomPainter {
  const _MoonStarsPainter({required this.moonColor, required this.starColor});

  final Color moonColor;
  final Color starColor;

  @override
  void paint(Canvas canvas, Size size) {
    final moonPaint = Paint()..color = moonColor;
    final moonCenter = Offset(size.width * 0.42, size.height * 0.48);
    canvas.drawCircle(moonCenter, size.width * 0.32, moonPaint);

    // Crescent bite.
    final bitePaint = Paint()..blendMode = BlendMode.dstOut;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawCircle(moonCenter, size.width * 0.32, moonPaint);
    canvas.drawCircle(
      Offset(moonCenter.dx + size.width * 0.14,
          moonCenter.dy - size.height * 0.08),
      size.width * 0.28,
      bitePaint,
    );
    canvas.restore();

    final starPaint = Paint()..color = starColor;
    _star(
        canvas, Offset(size.width * 0.82, size.height * 0.22), 3.2, starPaint);
    _star(canvas, Offset(size.width * 0.9, size.height * 0.55), 2.2, starPaint);
    _star(
        canvas, Offset(size.width * 0.68, size.height * 0.85), 2.6, starPaint);
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = (pi / 2) * i;
      final tip = center + Offset(cos(angle), sin(angle)) * radius;
      final mid1 = center +
          Offset(cos(angle + pi / 4), sin(angle + pi / 4)) * (radius * 0.32);
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(tip.dx, tip.dy);
      }
      path.lineTo(mid1.dx, mid1.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MoonStarsPainter oldDelegate) =>
      oldDelegate.moonColor != moonColor || oldDelegate.starColor != starColor;
}
