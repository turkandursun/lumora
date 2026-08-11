import 'package:flutter/material.dart';

/// A lightweight entrance animation: the child fades in while sliding up a
/// little. Give each item in a list an increasing [delay] for a soft,
/// staggered reveal. Plays once when first built.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 440),
    this.offsetY = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _anim =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
