import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// ============================================================================
/// EFFECT 3 — Physics-Based Spring/Elastic Micro-Interactions & Sliders
/// ============================================================================
///
/// THEORETICAL & MATHEMATICAL FRAMEWORK
/// ----------------------------------------------------------------------------
/// A damped spring's motion is governed by the second-order ODE:
///
///     m·x″ + c·x′ + k·x = 0
///
/// where m = mass, c = damping, k = stiffness, x = displacement from rest.
/// Flutter's `SpringSimulation` solves this exactly given a
/// `SpringDescription(mass, stiffness, damping)`, a start position, an end
/// position, and an initial velocity — precisely the numbers available the
/// instant a drag gesture ends (`DragEndDetails.velocity`).
///
/// The damping ratio ζ = c / (2·√(m·k)) determines the character of the
/// motion:
///
///     ζ < 1   underdamped   — oscillates, overshoots, settles with a
///                              visible bounce ("tactile")
///     ζ = 1   critically damped — fastest approach, zero overshoot
///     ζ > 1   overdamped    — slow, no oscillation
///
/// This kit defines two tuned profiles:
///
///     kSnappySpring: mass 1, stiffness 500, damping 22  → ζ ≈ 0.49
///       Used for the mood slider's snap-to-stop: quick settle, one small,
///       controlled overshoot — decisive, not wobbly.
///
///     kBouncySpring: mass 1, stiffness 260, damping 14  → ζ ≈ 0.43
///       Used for button-press release: slightly looser and slower, reads
///       as "squishy" rather than "snappy".
///
/// SQUASH & STRETCH
/// ----------------------------------------------------------------------------
/// While the slider thumb is dragged, it stretches along the drag axis in
/// proportion to recent drag speed, and inversely squashes the perpendicular
/// axis (classic animation-principle volume preservation):
///
///     scaleX(t) = 1 + k·|v(t)|,   scaleY(t) = 1 / scaleX(t)
///
/// clamped to a sane range (1.0–1.35×) so it reads as "stretchy elastic",
/// never "visually broken". The same stretch also applies during the
/// post-release spring settle, driven by `AnimationController.velocity` —
/// so the overshoot bounce visibly squashes too, not just the drag itself.
/// ============================================================================

/// A snappy profile for discrete snap-to-stop motion (sliders, page dots).
const SpringDescription kSnappySpring =
    SpringDescription(mass: 1, stiffness: 500, damping: 22);

/// A looser, "squishier" profile for button-press release bounces.
const SpringDescription kBouncySpring =
    SpringDescription(mass: 1, stiffness: 260, damping: 14);

/// One stop on a [SpringMoodSlider] — a label, icon and color.
class MoodStop {
  const MoodStop({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;
}

/// A horizontal mood-picker slider whose thumb is driven by real spring
/// physics: it tracks the finger 1:1 while dragging (with a velocity-based
/// squash/stretch), then — on release — flies to the nearest stop via a
/// [SpringSimulation] seeded with the release velocity, so a fast flick
/// visibly overshoots and settles rather than just snapping.
class SpringMoodSlider extends StatefulWidget {
  const SpringMoodSlider({
    super.key,
    required this.stops,
    required this.value,
    required this.onChanged,
    this.trackHeight = 64,
    this.thumbSize = 52,
  });

  final List<MoodStop> stops;
  final int value;
  final ValueChanged<int> onChanged;
  final double trackHeight;
  final double thumbSize;

  @override
  State<SpringMoodSlider> createState() => _SpringMoodSliderState();
}

class _SpringMoodSliderState extends State<SpringMoodSlider>
    with SingleTickerProviderStateMixin {
  // Unbounded: `.value` is the thumb's fractional position in "stop index"
  // units (0..stops.length-1) and can transiently exceed that range while a
  // release spring overshoots.
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.value.toDouble(),
  );

  double _dragVelocity = 0; // smoothed, in stops/frame — for squash/stretch only
  double _trackWidth = 0;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant SpringMoodSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      final simulation = SpringSimulation(
        kSnappySpring,
        _position.value,
        widget.value.toDouble(),
        _position.velocity,
      );
      _position.animateWith(simulation);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  double get _stopSpacing =>
      widget.stops.length > 1 ? _trackWidth / (widget.stops.length - 1) : _trackWidth;

  void _onPanStart(DragStartDetails details) {
    _dragging = true;
    _dragVelocity = 0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final spacing = _stopSpacing;
    if (spacing == 0) return;
    final deltaStops = details.delta.dx / spacing;
    _position.value =
        (_position.value + deltaStops).clamp(0.0, (widget.stops.length - 1).toDouble());
    // Exponential moving average so the stretch reacts to direction changes
    // immediately without jittering on tiny per-frame deltas.
    _dragVelocity = _dragVelocity * 0.6 + deltaStops.abs() * 0.4;
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    _dragging = false;
    final target = _position.value.round().clamp(0, widget.stops.length - 1);
    final pixelsPerStop = _stopSpacing == 0 ? 1.0 : _stopSpacing;
    final velocityInStops = details.velocity.pixelsPerSecond.dx / pixelsPerStop;

    final simulation = SpringSimulation(
      kSnappySpring,
      _position.value,
      target.toDouble(),
      velocityInStops,
    );
    _position.animateWith(simulation);
    _dragVelocity = 0;
    widget.onChanged(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _trackWidth = constraints.maxWidth;
        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            height: widget.trackHeight,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _position,
              builder: (context, _) {
                final maxIndex = (widget.stops.length - 1).toDouble();
                final t = _position.value.clamp(0.0, maxIndex);
                final activeIndex = t.round().clamp(0, widget.stops.length - 1);
                final color = _lerpStopColor(t);
                final dx = _stopSpacing * t;

                // Stretch is driven by drag speed while dragging, and by the
                // spring's own instantaneous velocity once released — so the
                // overshoot bounce visibly squashes/stretches too.
                final velocityMag =
                    _dragging ? _dragVelocity.abs() : (_position.velocity.abs() / 12);
                final stretch = (1 + velocityMag * 0.5).clamp(1.0, 1.35);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    _Track(stops: widget.stops, height: widget.trackHeight),
                    Positioned(
                      left: dx - widget.thumbSize / 2,
                      top: (widget.trackHeight - widget.thumbSize) / 2,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(stretch, 1 / stretch),
                        child: _Thumb(
                          size: widget.thumbSize,
                          color: color,
                          icon: widget.stops[activeIndex].icon,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _lerpStopColor(double t) {
    final lower = t.floor().clamp(0, widget.stops.length - 1);
    final upper = t.ceil().clamp(0, widget.stops.length - 1);
    final frac = t - lower;
    return Color.lerp(widget.stops[lower].color, widget.stops[upper].color, frac) ??
        widget.stops[lower].color;
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.stops, required this.height});

  final List<MoodStop> stops;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * 0.28,
      margin: EdgeInsets.symmetric(horizontal: height / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        gradient: LinearGradient(
          colors: stops.map((s) => s.color.withValues(alpha: 0.35)).toList(),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.size, required this.color, required this.icon});

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

/// A tap target that squashes on press and springs back with an
/// underdamped bounce on release — the button-press half of Effect 3.
/// Standalone (no dependency on any design-kit widget) so it can be dropped
/// into any project as-is.
class SpringBouncyButton extends StatefulWidget {
  const SpringBouncyButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.92,
    this.spring = kBouncySpring,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final SpringDescription spring;
  final bool haptic;

  @override
  State<SpringBouncyButton> createState() => _SpringBouncyButtonState();
}

class _SpringBouncyButtonState extends State<SpringBouncyButton>
    with SingleTickerProviderStateMixin {
  // 0 = resting, 1 = fully pressed. Unbounded so the release spring can
  // overshoot below 0 — a slight grow-past-100% bounce on release.
  late final AnimationController _controller = AnimationController.unbounded(vsync: this, value: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    _controller.animateTo(1, duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  void _release() {
    final simulation = SpringSimulation(widget.spring, _controller.value, 0, _controller.velocity);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _press() : null,
      onTapCancel: enabled ? _release : null,
      onTapUp: enabled
          ? (_) {
              _release();
              widget.onTap!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value.clamp(-0.6, 1.4);
          final scale = 1 - (1 - widget.pressedScale) * t;
          return Transform.scale(scale: scale, child: child);
        },
      ),
    );
  }
}
