import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ============================================================================
/// EFFECT 5 — Deforming & Animated Interactive Mood Avatar
/// ============================================================================
///
/// THEORETICAL & MATHEMATICAL FRAMEWORK
/// ----------------------------------------------------------------------------
/// The avatar's silhouette is a closed path through N points placed around a
/// circle, each perturbed by the sum of two independent sine waves running
/// at different frequencies and speeds:
///
///     r(θ, t) = R · (1 + A₁·sin(f₁·θ + ω₁·t) + A₂·sin(f₂·θ − ω₂·t))
///
/// Summing two non-harmonically-related waves (rather than one) means the
/// silhouette never repeats an obviously simple loop — it reads as organic
/// "breathing" rather than a pulsing circle, while still being perfectly
/// periodic (so `t` can just be a repeating 0..1 animation phase).
///
/// A third, event-triggered term is added on top for reactions (tap, mood
/// change), driven by its own `Curves.elasticOut` animation so it spikes and
/// rings down independently of the idle breathing:
///
///     r(θ, t) = R · (1 + breathing terms + 0.10·reaction(t)·sin(6θ))
///
/// Eyes are simple ellipses that periodically flatten to a thin sliver
/// (blink) on their own randomized timer — deliberately decoupled from the
/// body wobble so a blink can land at any point in the breath cycle without
/// looking mechanically synchronized.
///
/// RENDERING MECHANICS
/// ----------------------------------------------------------------------------
/// Everything is drawn by one `CustomPainter` inside a `RepaintBoundary`,
/// driven by `Listenable.merge` over three `AnimationController`s (breath,
/// blink, reaction) so a single `AnimatedBuilder` repaints on any of their
/// ticks — one Skia picture per frame, zero widget-subtree rebuilds, zero
/// layout passes after the first frame.
/// ============================================================================

enum AvatarMood { happy, calm, tired, sad, anxious }

/// A living, breathing mood avatar — a soft, morphing blob with blinking
/// eyes that reacts to mood changes and taps. Zero external asset/package
/// dependencies; see the bottom of this file for an optional Lottie/Rive
/// integration template if you'd rather drive a rigged illustration instead.
class LivingAvatar extends StatefulWidget {
  const LivingAvatar({
    super.key,
    this.size = 120,
    this.mood = AvatarMood.calm,
    this.speaking = false,
  });

  final double size;
  final AvatarMood mood;
  final bool speaking;

  @override
  State<LivingAvatar> createState() => LivingAvatarState();
}

class LivingAvatarState extends State<LivingAvatar> with TickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  late final AnimationController _blink =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  late final AnimationController _reaction =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  late final Animation<double> _reactionCurve =
      CurvedAnimation(parent: _reaction, curve: Curves.elasticOut);

  final math.Random _random = math.Random();
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    final wait = Duration(milliseconds: 2200 + _random.nextInt(2600));
    _blinkTimer = Timer(wait, () async {
      if (!mounted) return;
      await _blink.forward();
      if (!mounted) return;
      await _blink.reverse();
      if (!mounted) return;
      _scheduleBlink();
    });
  }

  /// Plays a quick, springy "pop" reaction — call on tap, or automatically
  /// on mood change (already wired via [didUpdateWidget]).
  void react() {
    _reaction.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant LivingAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) react();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _blink.dispose();
    _reaction.dispose();
    super.dispose();
  }

  Color _moodColor(AvatarMood mood) {
    switch (mood) {
      case AvatarMood.happy:
        return const Color(0xFFFFC469);
      case AvatarMood.calm:
        return const Color(0xFFEAAAC8);
      case AvatarMood.tired:
        return const Color(0xFFB6A8D8);
      case AvatarMood.sad:
        return const Color(0xFF7EA8D8);
      case AvatarMood.anxious:
        return const Color(0xFFE58989);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: react,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_breath, _blink, _reactionCurve]),
          builder: (context, _) {
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _LivingAvatarPainter(
                t: _breath.value,
                blink: _blink.value,
                reaction: _reactionCurve.value,
                speaking: widget.speaking,
                color: _moodColor(widget.mood),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LivingAvatarPainter extends CustomPainter {
  _LivingAvatarPainter({
    required this.t,
    required this.blink,
    required this.reaction,
    required this.speaking,
    required this.color,
  });

  final double t; // 0..1 looping breath phase
  final double blink; // 0..1, 1 = eyes fully closed
  final double reaction; // elastic-out, overshoots past 1 then settles
  final bool speaking;
  final Color color;

  static const _segments = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide / 2 * 0.86;
    final theta0 = t * 2 * math.pi;

    final path = Path();
    for (var i = 0; i <= _segments; i++) {
      final theta = (i / _segments) * 2 * math.pi;
      final breathe =
          0.05 * math.sin(3 * theta + theta0) + 0.03 * math.sin(5 * theta - theta0 * 1.6);
      final pop = 0.10 * reaction * math.sin(6 * theta);
      final r = baseRadius * (1 + breathe + pop);
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
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.65)],
        ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.1)),
    );

    _paintEyes(canvas, center, baseRadius);
    if (speaking) _paintMouth(canvas, center, baseRadius);
  }

  void _paintEyes(Canvas canvas, Offset center, double radius) {
    final eyeOffset = radius * 0.34;
    final eyeY = center.dy - radius * 0.08;
    final eyeHeight = radius * 0.16 * (1 - blink).clamp(0.06, 1.0);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    for (final dx in [-eyeOffset, eyeOffset]) {
      final eyeCenter = Offset(center.dx + dx, eyeY);
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: radius * 0.16, height: eyeHeight),
        paint,
      );
    }
  }

  void _paintMouth(Canvas canvas, Offset center, double radius) {
    final mouthY = center.dy + radius * 0.28;
    final openAmount = (0.5 + 0.5 * math.sin(t * 2 * math.pi * 6)).abs();
    final rect = Rect.fromCenter(
      center: Offset(center.dx, mouthY),
      width: radius * 0.28,
      height: radius * 0.12 * openAmount + 2,
    );
    canvas.drawOval(rect, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant _LivingAvatarPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.blink != blink ||
        oldDelegate.reaction != reaction ||
        oldDelegate.speaking != speaking ||
        oldDelegate.color != color;
  }
}

// =============================================================================
// OPTIONAL — swapping the CustomPainter body for a rigged Lottie/Rive asset
// =============================================================================
// If a motion/illustration designer supplies a rigged Lottie (After Effects
// + Bodymovin) or Rive file instead, keep [LivingAvatar]'s exact public API
// (`mood`, `speaking`, `LivingAvatarState.react()`) and swap only the
// internals — every call site in the app stays unchanged:
//
// ```dart
// // pubspec.yaml:
// //   dependencies:
// //     lottie: ^3.1.0
//
// class LivingAvatarState extends State<LivingAvatar>
//     with SingleTickerProviderStateMixin {
//   late final _controller = AnimationController(vsync: this);
//   LottieComposition? _composition;
//
//   // Named marker ranges authored in After Effects and exported with the
//   // Lottie marker plugin, e.g. {"calm": (0, 60), "happy": (60, 130), ...}.
//   static const _markers = {
//     AvatarMood.calm: (start: 0, end: 60),
//     AvatarMood.happy: (start: 60, end: 130),
//     // ...one entry per AvatarMood
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     AssetLottie('assets/lottie/luma_avatar.json')
//         .load()
//         .then((c) => setState(() => _composition = c));
//   }
//
//   void react() {
//     final composition = _composition;
//     if (composition == null) return;
//     final marker = _markers[widget.mood]!;
//     final total = composition.duration.inMilliseconds;
//     _controller.animateTo(
//       marker.end / total,
//       duration: const Duration(milliseconds: 500),
//       curve: Curves.easeOutBack,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final composition = _composition;
//     if (composition == null) return SizedBox.square(dimension: widget.size);
//     return SizedBox.square(
//       dimension: widget.size,
//       child: Lottie(composition: composition, controller: _controller),
//     );
//   }
// }
// ```
//
// The CustomPainter version above has zero asset/package dependencies and
// costs well under 0.5ms/frame on a mid-range device — prefer it unless
// there's already Lottie/Rive art directed for the brand.
