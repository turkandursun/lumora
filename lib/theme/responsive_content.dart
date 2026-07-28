import 'package:flutter/material.dart';

/// Caps foreground content (text, buttons, forms, cards) at a comfortable
/// reading width and centers it, while leaving whatever full-bleed
/// background (photo/gradient) sits behind it untouched — the background
/// keeps filling the entire window edge-to-edge at any size.
///
/// On a phone-width screen this has no visible effect, since the available
/// width is already narrower than [maxWidth]. On a wide desktop browser
/// window it keeps [child] from stretching edge-to-edge, so the screen
/// doesn't read as a broken narrow app blown up too wide.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
