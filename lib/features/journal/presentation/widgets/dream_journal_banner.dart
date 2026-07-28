import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/sakura_home_palette.dart';

/// Full-width "Rüya Günlüğü" (Dream Journal) banner, visually distinct from
/// the 3-column feature grid above it — a deep lavender card with a small
/// moon-and-stars illustration, routing to the real Dream Journal screen
/// (PIN-gated via [AppRoutes.dreams] when that section is locked).
class DreamJournalBanner extends StatelessWidget {
  const DreamJournalBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(AppRoutes.dreams),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFA78BDB), Color(0xFFD8A9E0)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: SakuraHomePalette.branchMauve.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
                    Text(
                      l10n.homeDreamJournalTitle,
                      style: AppTheme.displayFont(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.homeDreamJournalDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyFont(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
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
