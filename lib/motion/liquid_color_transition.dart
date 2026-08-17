import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================================
/// EFFECT 2 — Liquid/Fluid Dynamic Background Color Interpolation
/// ============================================================================
///
/// THEORETICAL & MATHEMATICAL FRAMEWORK
/// ----------------------------------------------------------------------------
/// A plain cross-fade interpolates every pixel's color simultaneously — it
/// reads as a "dissolve", not a propagating liquid. To get the ink-drop feel,
/// the new color is instead painted only *inside* an expanding, organically
/// wobbling blob, over a static base layer already showing the new color's
/// eventual resting state underneath (so nothing pops when the animation
/// finishes):
///
///   radius(t)   = curve(t) · maxRadius
///   maxRadius   = max distance from the origin point to any screen corner
///                 (guarantees full coverage regardless of where the touch
///                 landed)
///
/// The blob boundary is not a perfect circle — it's sampled at N points
/// around the origin, each perturbed by a decaying sine wave:
///
///   r(θ, t) = radius(t) + A(t) · sin(k·θ + φ(t))
///
///   A(t) = A₀ · (1 − t) · min(1, 6t)     — ramps up fast, then decays to 0
///                                          as t → 1, so the blob resolves
///                                          into a perfectly clean, seamless
///                                          full-screen fill with no visible
///                                          artifact at completion.
///   φ(t) = 2.4π · t                       — the wobble also *rotates* as it
///                                          grows, avoiding a static "gear"
///                                          look.
///   k    = wave count (7 by default)      — number of lobes around the blob.
///
/// `curve(t)` is `Curves.easeOutQuint` — an aggressive ease-out, so the
/// "ink" surges outward quickly then decelerates hard, matching how a fluid
/// actually behaves when it hits the edges of a container (here: the
/// screen).
///
/// RENDERING MECHANICS
/// ----------------------------------------------------------------------------
/// - A single `CustomPainter` draws the blob as one `Path` (72 line segments
///   — enough to look smooth at any screen size, cheap enough to rebuild
///   every frame) filled with a solid `Paint`. No shaders, no per-pixel
///   blending — this stays entirely on the raster thread's vector path-fill
///   fast path.
/// - The whole painter sits inside a `RepaintBoundary` so the animation
///   never triggers a layout pass on the (potentially large) `child` subtree
///   beneath it — only that one compositor layer repaints.
/// - State machine: `LiquidColorController` holds `baseColor` (the
///   already-committed color) and, only while animating, a `targetColor` +
///   `origin`. When the driving `AnimationController` completes,
///   `baseColor` is promoted to `targetColor` and the overlay painter is
///   dropped entirely — so once settled, this is just a flat `ColoredBox`,
///   as cheap as a normal solid background.
/// ============================================================================

/// Holds the current background color and, transiently, an in-flight liquid
/// transition to a new one. Create one per screen/app-region that should
/// share a single liquid-colored background, and pass it to
/// [LiquidColorBackground].
class LiquidColorController extends ChangeNotifier {
  LiquidColorController({required Color initialColor}) : _baseColor = initialColor;

  Color _baseColor;
  Color? _targetColor;
  Offset _origin = Offset.zero;

  /// The fully-committed color once no transition is in flight.
  Color get baseColor => _baseColor;

  /// The color currently being animated *to*, or `null` if idle.
  Color? get targetColor => _targetColor;

  /// Where the liquid wave originates from (e.g. the tap position).
  Offset get origin => _origin;

  /// Starts a liquid transition to [target], expanding outward from
  /// [origin] — pass the tap's global position for a touch-driven change,
  /// or the screen center for a programmatic one (e.g. a mood/theme switch
  /// triggered from a menu rather than a direct tap).
  void begin(Color target, Offset origin) {
    if (target == _baseColor && _targetColor == null) return;
    _targetColor = target;
    _origin = origin;
    notifyListeners();
  }

  void _complete() {
    if (_targetColor != null) {
      _baseColor = _targetColor!;
      _targetColor = null;
    }
  }
}

/// Wraps [child] with a liquid-animated background driven by [controller].
/// Put this near the root of a screen (or the whole app) in place of a plain
/// `ColoredBox`/`Container(color: ...)`.
class LiquidColorBackground extends StatefulWidget {
  const LiquidColorBackground({
    super.key,
    required this.controller,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.waveCount = 7,
    this.waveAmplitude = 22,
  });

  final LiquidColorController controller;
  final Widget child;
  final Duration duration;
  final int waveCount;
  final double waveAmplitude;

  @override
  State<LiquidColorBackground> createState() => _LiquidColorBackgroundState();
}

class _LiquidColorBackgroundState extends State<LiquidColorBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuint);

  Color? _lastTarget;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    final target = widget.controller.targetColor;
    if (target != null && target != _lastTarget) {
      _lastTarget = target;
      _animController.forward(from: 0).whenComplete(() {
        widget.controller._complete();
        _lastTarget = null;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final target = widget.controller.targetColor;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: widget.controller.baseColor),
            if (target != null)
              RepaintBoundary(
                child: CustomPaint(
                  painter: _LiquidBlobPainter(
                    progress: _curve.value,
                    color: target,
                    center: widget.controller.origin,
                    waveCount: widget.waveCount,
                    baseAmplitude: widget.waveAmplitude,
                  ),
                  size: Size.infinite,
                ),
              ),
            if (child != null) child,
          ],
        );
      },
    );
  }
}

class _LiquidBlobPainter extends CustomPainter {
  _LiquidBlobPainter({
    required this.progress,
    required this.color,
    required this.center,
    required this.waveCount,
    required this.baseAmplitude,
  });

  /// Already-curved 0..1 progress.
  final double progress;
  final Color color;
  final Offset center;
  final int waveCount;
  final double baseAmplitude;

  static const _segments = 72;

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = _maxRadiusFrom(center, size);
    final radius = progress * maxRadius;

    // Wobble ramps up fast then decays to zero as progress -> 1, so the
    // blob resolves into a seamless full-bleed fill with no visible edge.
    final amplitude = baseAmplitude * (1 - progress) * math.min(1.0, progress * 6);
    final phase = progress * math.pi * 2.4;

    final path = Path();
    for (var i = 0; i <= _segments; i++) {
      final theta = (i / _segments) * 2 * math.pi;
      final wobble = amplitude * math.sin(waveCount * theta + phase);
      final r = math.max(0.0, radius + wobble);
      final point = center + Offset(math.cos(theta), math.sin(theta)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  double _maxRadiusFrom(Offset c, Size size) {
    final corners = <Offset>[
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    var farthest = 0.0;
    for (final corner in corners) {
      farthest = math.max(farthest, (corner - c).distance);
    }
    return farthest;
  }

  @override
  bool shouldRepaint(covariant _LiquidBlobPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.center != center;
  }
}
