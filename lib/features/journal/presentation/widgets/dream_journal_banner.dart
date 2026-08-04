import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';

const _gold = Color(0xFFE9C98C);

/// Full-width "Rüya Günlüğü" (Dream Journal) banner, visually distinct from
/// the 3-column feature grid above it — a dark glass card with a small
/// moon-and-stars illustration, routing to the real Dream Journal screen.
class DreamJournalBanner extends StatelessWidget {
  const DreamJournalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AstraGlassCard(
      isDark: true,
      primaryColor: _gold,
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push(AppRoutes.dreams),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const SizedBox(
                  width: 52,
                  height: 52,
                  child: CustomPaint(painter: _MoonStarsPainter()),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.homeDreamJournalTitle, style: AstraKit.heading2(true, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(
                        l10n.homeDreamJournalDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AstraKit.mutedText(true, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: _gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoonStarsPainter extends CustomPainter {
  const _MoonStarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final moonPaint = Paint()..color = const Color(0xFFFFF4D6).withValues(alpha: 0.95);
    final moonCenter = Offset(size.width * 0.42, size.height * 0.48);
    canvas.drawCircle(moonCenter, size.width * 0.32, moonPaint);

    // Crescent bite.
    final bitePaint = Paint()..blendMode = BlendMode.dstOut;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawCircle(moonCenter, size.width * 0.32, moonPaint);
    canvas.drawCircle(
      Offset(moonCenter.dx + size.width * 0.14, moonCenter.dy - size.height * 0.08),
      size.width * 0.28,
      bitePaint,
    );
    canvas.restore();

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    _star(canvas, Offset(size.width * 0.82, size.height * 0.22), 3.2, starPaint);
    _star(canvas, Offset(size.width * 0.9, size.height * 0.55), 2.2, starPaint);
    _star(canvas, Offset(size.width * 0.68, size.height * 0.85), 2.6, starPaint);
  }

  void _star(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final angle = (pi / 2) * i;
      final tip = center + Offset(cos(angle), sin(angle)) * radius;
      final mid1 = center + Offset(cos(angle + pi / 4), sin(angle + pi / 4)) * (radius * 0.32);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
