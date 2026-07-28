import 'package:flutter/material.dart';

/// A single full-bleed image with a slow Ken Burns zoom/pan applied via
/// externally-owned [scale]/[alignment] animations. Kept stateless and
/// presentation-only so callers (a mood crossfade, a static photo backdrop,
/// ...) own the driving [AnimationController] and its lifecycle.
class KenBurnsPhoto extends StatelessWidget {
  const KenBurnsPhoto({
    super.key,
    required this.asset,
    required this.scale,
    required this.alignment,
    this.imageAlignment = Alignment.center,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final Animation<double> scale;
  final Animation<Alignment> alignment;

  /// Where [fit] anchors the image when its aspect ratio doesn't match the
  /// viewport. Defaults to centered; pass e.g. [Alignment.topCenter] to keep
  /// the top of a tall scene (sky, distant mountains) in frame instead of
  /// cropping/letterboxing it evenly off both edges.
  final Alignment imageAlignment;

  /// How the image fills the viewport. Defaults to [BoxFit.cover] (fills the
  /// box, cropping any overflow) — pass [BoxFit.contain] for scenes that
  /// need to stay fully visible with no cropping (letterboxed instead).
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scale,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          alignment: alignment.value,
          child: child,
        );
      },
      child: Image.asset(
        asset,
        fit: fit,
        alignment: imageAlignment,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

/// Soft readability scrim laid over a busy photo background so foreground
/// text/inputs stay legible. Same vertical gradient treatment shared across
/// Lumora's photo backgrounds.
class PhotoReadabilityScrim extends StatelessWidget {
  const PhotoReadabilityScrim({
    super.key,
    this.colors = const [
      Color(0x4D000000),
      Color(0x1A000000),
      Color(0x52000000),
    ],
    this.stops = const [0.0, 0.45, 1.0],
  });

  final List<Color> colors;
  final List<double> stops;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ),
      ),
    );
  }
}
