import 'package:flutter/material.dart';

/// The app's shared soft pastel background — a light lavender-to-pink wash
/// used across screens for a calm, consistent look. Content on top should
/// use dark text (SakuraHomePalette.textDeep / textMuted).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  static const List<Color> gradient = [
    Color(0xFFF3EBFB), // light lavender
    Color(0xFFFBEBF3), // light pink
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: child,
    );
  }
}
