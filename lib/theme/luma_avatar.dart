import 'dart:async';

import 'package:flutter/material.dart';

/// Luma's animated star avatar. Two frames — mouth closed and mouth open —
/// are swapped quickly while [speaking] is true to give a simple, lively
/// "talking" mouth-flap. When idle it rests on the closed frame with a gentle
/// breathing bob.
class LumaAvatar extends StatefulWidget {
  const LumaAvatar({
    super.key,
    this.size = 72,
    this.speaking = false,
  });

  final double size;
  final bool speaking;

  @override
  State<LumaAvatar> createState() => _LumaAvatarState();
}

class _LumaAvatarState extends State<LumaAvatar>
    with SingleTickerProviderStateMixin {
  static const _closed = 'assets/images/luma_star_closed.png';
  static const _open = 'assets/images/luma_star_open.png';

  bool _mouthOpen = false;
  Timer? _mouthTimer;

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.speaking) _startTalking();
  }

  @override
  void didUpdateWidget(covariant LumaAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speaking && !oldWidget.speaking) {
      _startTalking();
    } else if (!widget.speaking && oldWidget.speaking) {
      _stopTalking();
    }
  }

  void _startTalking() {
    _mouthTimer?.cancel();
    _mouthTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted) setState(() => _mouthOpen = !_mouthOpen);
    });
  }

  void _stopTalking() {
    _mouthTimer?.cancel();
    _mouthTimer = null;
    if (mounted) setState(() => _mouthOpen = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep both frames warm so the mouth-flap never flickers on first swap.
    precacheImage(const AssetImage(_closed), context);
    precacheImage(const AssetImage(_open), context);
  }

  @override
  void dispose() {
    _mouthTimer?.cancel();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = (widget.speaking && _mouthOpen) ? _open : _closed;
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_idle.value);
        return Transform.translate(
          offset: Offset(0, -2.5 * t),
          child: Transform.scale(scale: 1 + 0.02 * t, child: child),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Image.asset(asset, fit: BoxFit.contain, gaplessPlayback: true),
      ),
    );
  }
}
