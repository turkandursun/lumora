import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'astra_screen_kit.dart';

/// A calm, living background: the theme gradient with a few large, soft organic
/// "liquid" blobs that slowly undulate and drift. No assets — it's all drawn on
/// a [CustomPainter], so it stays crisp at any size and costs nothing to ship.
/// Designed to make otherwise-empty screens feel alive and restful.
class AstraLiquidBackground extends StatefulWidget {
  const AstraLiquidBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;

  /// Scales the blob opacity/blur — lower for busy screens, higher for hero
  /// screens that should feel dreamy.
  final double intensity;

  @override
  State<AstraLiquidBackground> createState() => _AstraLiquidBackgroundState();
}

class _AstraLiquidBackgroundState extends State<AstraLiquidBackground>
    with SingleTickerProviderStateMixin {
  // One slow cycle keeps the motion gentle and unmistakably "breathing".
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AstraKit.palette(context);
    return Stack(
      children: [
        // Base gradient wash.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.gradientTop, palette.gradientBottom],
              ),
            ),
          ),
        ),
        // Undulating liquid blobs.
        Positioned.fill(
          child: RepaintBoundary(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _LiquidPainter(
                    t: _c.value * 2 * pi,
                    intensity: widget.intensity,
                    blobs: [
                      _Blob(const Offset(0.22, 0.26), 0.42, palette.activeAccent, 0.9),
                      _Blob(const Offset(0.82, 0.44), 0.38, palette.secondary, 1.5),
                      _Blob(const Offset(0.40, 0.86), 0.46, palette.buttonPrimary, 2.3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Blob {
  const _Blob(this.center, this.radius, this.color, this.phase);

  /// Base center as a fraction of the canvas.
  final Offset center;

  /// Base radius as a fraction of the shorter side.
  final double radius;
  final Color color;
  final double phase;
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({
    required this.t,
    required this.intensity,
    required this.blobs,
  });

  final double t;
  final double intensity;
  final List<_Blob> blobs;

  @override
  void paint(Canvas canvas, Size size) {
    final minSide = min(size.width, size.height);
    final blur = 44.0 * intensity;
    for (final b in blobs) {
      // Slow drift so the whole form floats.
      final dx = (b.center.dx + 0.035 * sin(t + b.phase)) * size.width;
      final dy = (b.center.dy + 0.045 * cos(t * 0.8 + b.phase)) * size.height;
      final r = b.radius * minSide;

      final paint = Paint()
        ..color = b.color.withValues(alpha: (0.20 * intensity).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
        ..imageFilter = ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5);
      canvas.drawPath(_blobPath(Offset(dx, dy), r, t + b.phase), paint);
    }
  }

  /// A closed, wobbling path — radius modulated by two sine harmonics so the
  /// shape reads as an organic liquid drop rather than a plain circle.
  Path _blobPath(Offset c, double r, double t) {
    const steps = 46;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final a = (i / steps) * 2 * pi;
      final wobble = 1 +
          0.16 * sin(3 * a + t * 1.4) +
          0.10 * cos(2 * a - t * 0.9);
      final rr = r * wobble;
      final x = c.dx + rr * cos(a);
      final y = c.dy + rr * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) =>
      old.t != t || old.intensity != intensity;
}
