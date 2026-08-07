import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../theme/lumora_palette.dart';

/// Night-sky gradient wash with a faint moon glow and scattered stars.
/// Shared decorative backdrop for Lumora's auth screens (login, sign up).
class NightSkyBackdrop extends StatelessWidget {
  const NightSkyBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: LumoraPalette.backgroundGradient,
          stops: [0.0, 0.42, 0.72, 1.0],
        ),
      ),
      child: const MoonAndStarsLayer(),
    );
  }
}

/// The moon glow + scattered starfield on its own, independent of any
/// particular background gradient — reused by [NightSkyBackdrop] and by
/// mood-driven backgrounds so the motif stays constant while the gradient
/// underneath it changes.
class MoonAndStarsLayer extends StatelessWidget {
  const MoonAndStarsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarfieldPainter(), size: Size.infinite);
  }
}

class _Star {
  const _Star(this.dx, this.dy, this.radius, this.opacity);
  final double dx;
  final double dy;
  final double radius;
  final double opacity;
}

final List<_Star> _stars = List.generate(46, (i) {
  final rnd = Random(i * 97 + 13);
  return _Star(
    rnd.nextDouble(),
    rnd.nextDouble() * 0.8,
    rnd.nextDouble() * 1.3 + 0.4,
    rnd.nextDouble() * 0.5 + 0.25,
  );
});

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final moonCenter = Offset(size.width * 0.76, size.height * 0.09);
    final moonPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          LumoraPalette.warmCream.withValues(alpha: 0.35),
          LumoraPalette.warmCream.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: moonCenter, radius: 70))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(moonCenter, 70, moonPaint);

    final moonCorePaint = Paint()
      ..color = LumoraPalette.warmCream.withValues(alpha: 0.85);
    canvas.drawCircle(moonCenter, 16, moonCorePaint);

    final starPaint = Paint()..color = Colors.white;
    for (final star in _stars) {
      starPaint.color = Colors.white.withValues(alpha: star.opacity);
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * size.height),
        star.radius,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Thin sakura branch with a few blossoms, tucked into a top corner.
class SakuraCorner extends StatelessWidget {
  const SakuraCorner({super.key, this.mirrored = false});

  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final branch = SizedBox(
      width: 150,
      height: 130,
      child: CustomPaint(painter: _SakuraBranchPainter()),
    );
    return mirrored ? Transform.flip(flipX: true, child: branch) : branch;
  }
}

class _SakuraBranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final branchPaint = Paint()
      ..color = LumoraPalette.lightPurple.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, 4)
      ..cubicTo(38, 2, 46, 34, 78, 40)
      ..cubicTo(102, 44, 108, 62, 132, 78);
    canvas.drawPath(path, branchPaint);

    final twig = Path()
      ..moveTo(46, 20)
      ..quadraticBezierTo(58, 8, 74, 10);
    canvas.drawPath(twig, branchPaint);

    _blossom(canvas, const Offset(18, 10), 5, 0.55);
    _blossom(canvas, const Offset(58, 14), 4, 0.45);
    _blossom(canvas, const Offset(80, 42), 6, 0.5);
    _blossom(canvas, const Offset(110, 58), 4.5, 0.4);
    _blossom(canvas, const Offset(130, 80), 5, 0.5);
  }

  void _blossom(Canvas canvas, Offset center, double petalRadius, double opacity) {
    final petalPaint = Paint()
      ..color = LumoraPalette.softPink.withValues(alpha: opacity);
    for (var i = 0; i < 5; i++) {
      final angle = (pi * 2 / 5) * i;
      final petalCenter = Offset(
        center.dx + cos(angle) * petalRadius,
        center.dy + sin(angle) * petalRadius,
      );
      canvas.drawCircle(petalCenter, petalRadius * 0.62, petalPaint);
    }
    canvas.drawCircle(
      center,
      petalRadius * 0.4,
      Paint()..color = LumoraPalette.warmCream.withValues(alpha: opacity + 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A drifting layer of falling sakura petals, used in two instances (one
/// behind, one in front of [WalkingFigure]) so the petals read as passing
/// both in front of and behind the figure for a sense of depth.
///
/// Each layer is seeded independently ([seed]) so the two instances scatter
/// different petals rather than mirroring each other.
class FallingPetalsLayer extends StatefulWidget {
  const FallingPetalsLayer({
    super.key,
    required this.seed,
    this.petalCount = 10,
    this.layerOpacity = 1.0,
  });

  final int seed;
  final int petalCount;
  final double layerOpacity;

  @override
  State<FallingPetalsLayer> createState() => _FallingPetalsLayerState();
}

class _FallingPetalsLayerState extends State<FallingPetalsLayer>
    with SingleTickerProviderStateMixin {
  // A long, slow loop — petals drift calmly rather than snowing down.
  late final AnimationController _controller;

  late final List<_FallingPetal> _petals;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
    _petals = List.generate(widget.petalCount, (i) {
      final rnd = Random(widget.seed * 1000 + i);
      return _FallingPetal(
        dx: rnd.nextDouble(),
        phase: rnd.nextDouble(),
        speed: 0.65 + rnd.nextDouble() * 0.5,
        swayAmplitude: 10 + rnd.nextDouble() * 18,
        swayFrequency: 0.6 + rnd.nextDouble() * 0.8,
        size: 5 + rnd.nextDouble() * 5,
        spin: (rnd.nextBool() ? 1 : -1) * (0.3 + rnd.nextDouble() * 0.6),
        opacity: 0.3 + rnd.nextDouble() * 0.35,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _FallingPetalsPainter(
              petals: _petals,
              t: _controller.value,
              layerOpacity: widget.layerOpacity,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _FallingPetal {
  const _FallingPetal({
    required this.dx,
    required this.phase,
    required this.speed,
    required this.swayAmplitude,
    required this.swayFrequency,
    required this.size,
    required this.spin,
    required this.opacity,
  });

  final double dx;
  final double phase;
  final double speed;
  final double swayAmplitude;
  final double swayFrequency;
  final double size;
  final double spin;
  final double opacity;
}

class _FallingPetalsPainter extends CustomPainter {
  _FallingPetalsPainter({
    required this.petals,
    required this.t,
    required this.layerOpacity,
  });

  final List<_FallingPetal> petals;
  final double t;
  final double layerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final petal in petals) {
      final progress = (t * petal.speed + petal.phase) % 1.0;
      final y = (-0.12 + progress * 1.24) * size.height;
      final sway =
          sin(progress * 2 * pi * petal.swayFrequency) * petal.swayAmplitude;
      final x = petal.dx * size.width + sway;
      final rotation = progress * 2 * pi * petal.spin;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final paint = Paint()
        ..color = LumoraPalette.softPink.withValues(
          alpha: petal.opacity * layerOpacity,
        );
      canvas.drawPath(_petalPath(petal.size), paint);
      canvas.restore();
    }
  }

  Path _petalPath(double petalSize) {
    return Path()
      ..moveTo(0, -petalSize)
      ..quadraticBezierTo(petalSize * 0.85, -petalSize * 0.3, 0, petalSize)
      ..quadraticBezierTo(-petalSize * 0.85, -petalSize * 0.3, 0, -petalSize)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _FallingPetalsPainter oldDelegate) => true;
}

/// A small, slow-walking silhouette that paces the lower third of the
/// login background — a subtle background detail, layered between the
/// two [FallingPetalsLayer] instances so petals pass both behind and in
/// front of it.
class WalkingFigure extends StatefulWidget {
  const WalkingFigure({super.key, this.height = 62, this.opacity = 0.5});

  final double height;
  final double opacity;

  @override
  State<WalkingFigure> createState() => _WalkingFigureState();
}

class _WalkingFigureState extends State<WalkingFigure>
    with TickerProviderStateMixin {
  late final AnimationController _cycleController;
  late final AnimationController _paceController;

  @override
  void initState() {
    super.initState();
    _cycleController = AnimationController(
      vsync: this,
    );
    _paceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  void _onCompositionLoaded(LottieComposition composition) {
    // The authored walk cycle is a brisk 2s; roughly triple it so the pace
    // reads as calm and unhurried, consistent with the rest of the scene.
    _cycleController
      ..duration = composition.duration * 3
      ..repeat();
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _paceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.height * (100 / 160);
    return AnimatedBuilder(
      animation: _paceController,
      builder: (context, child) {
        final pace = Curves.easeInOut.transform(_paceController.value);
        final alignX = -0.82 + 1.64 * pace;
        final movingRight = _paceController.status == AnimationStatus.forward;
        return Align(
          alignment: Alignment(alignX, 0.72),
          child: Transform.flip(flipX: !movingRight, child: child),
        );
      },
      child: Opacity(
        opacity: widget.opacity,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            LumoraPalette.lightPurple.withValues(alpha: 0.9),
            BlendMode.srcIn,
          ),
          child: SizedBox(
            height: widget.height,
            width: width,
            child: Lottie.asset(
              'assets/animations/walking_person.json',
              controller: _cycleController,
              repeat: true,
              onLoaded: _onCompositionLoaded,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small, delicate butterfly accent near the brand mark.
class Butterfly extends StatelessWidget {
  const Butterfly({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.18,
      child: SizedBox(
        width: 34,
        height: 28,
        child: CustomPaint(painter: _ButterflyPainter()),
      ),
    );
  }
}

class _ButterflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wingFill = Paint()
      ..color = LumoraPalette.softPink.withValues(alpha: 0.55);
    final wingStroke = Paint()
      ..color = LumoraPalette.lightPurple.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    final upperLeft = Path()
      ..moveTo(center.dx, center.dy - 2)
      ..cubicTo(
        center.dx - 16,
        center.dy - 18,
        center.dx - 20,
        center.dy + 2,
        center.dx,
        center.dy,
      )
      ..close();
    final upperRight = Path()
      ..moveTo(center.dx, center.dy - 2)
      ..cubicTo(
        center.dx + 16,
        center.dy - 18,
        center.dx + 20,
        center.dy + 2,
        center.dx,
        center.dy,
      )
      ..close();
    final lowerLeft = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(
        center.dx - 12,
        center.dy + 4,
        center.dx - 10,
        center.dy + 16,
        center.dx,
        center.dy + 4,
      )
      ..close();
    final lowerRight = Path()
      ..moveTo(center.dx, center.dy)
      ..cubicTo(
        center.dx + 12,
        center.dy + 4,
        center.dx + 10,
        center.dy + 16,
        center.dx,
        center.dy + 4,
      )
      ..close();

    for (final wing in [upperLeft, upperRight, lowerLeft, lowerRight]) {
      canvas.drawPath(wing, wingFill);
      canvas.drawPath(wing, wingStroke);
    }

    final bodyPaint = Paint()
      ..color = LumoraPalette.primaryPurple.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
