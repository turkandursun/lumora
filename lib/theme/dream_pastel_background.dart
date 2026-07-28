import 'package:flutter/material.dart';

import '../features/auth/presentation/widgets/lumora_auth_decor.dart';
import 'lumora_palette.dart';

/// A soft, pastel "dream sky" background shared across the dream-journal
/// screens.
///
/// Unlike MoodGradientBackground, this does NOT react to the selected
/// mood — the dream section keeps one calm, dreamy identity: a pastel
/// lavender twilight wash with the moon, stars and sakura motifs, plus a
/// gentle pink dream-glow. The gradient is deliberately kept medium-dark
/// (a "pastel dusk" rather than a light pastel) so the white text and the
/// translucent frosted cards layered on top stay readable.
class DreamPastelBackground extends StatelessWidget {
  const DreamPastelBackground({super.key, this.child});

  /// Optional foreground content painted above the gradient and motifs.
  final Widget? child;

  /// Pastel dusk → lavender gradient. Soft, dreamy hues, but each stop is
  /// kept dark enough that white text and the 0.06-alpha white cards above
  /// keep their contrast.
  static const List<Color> _dreamGradient = [
    Color(0xFF2B2548), // deep soft indigo
    Color(0xFF4B3F6E), // muted lavender
    Color(0xFF6E5E97), // dusty lavender
    Color(0xFF9C88C0), // soft pastel lavender
  ];

  static const List<double> _stops = [0.0, 0.42, 0.72, 1.0];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _dreamGradient,
          stops: _stops,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MoonAndStarsLayer(),
          const _DreamGlow(),
          const Positioned(top: 0, left: 0, child: SakuraCorner()),
          const Positioned(top: 0, right: 0, child: SakuraCorner(mirrored: true)),
          const Positioned(top: 118, right: 46, child: Butterfly()),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// A soft pink radial glow that gives the dream sky its dreamy, pastel
/// lift — offset to the upper-left so it reads as ambient light rather
/// than a spotlight, and low-alpha so it never washes out the text.
class _DreamGlow extends StatelessWidget {
  const _DreamGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.2,
          colors: [
            LumoraPalette.softPink.withValues(alpha: 0.28),
            LumoraPalette.accentPink.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
