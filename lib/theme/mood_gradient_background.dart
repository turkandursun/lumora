import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/widgets/lumora_auth_decor.dart';
import 'lumora_palette.dart';
import 'mood_gradients.dart';
import 'mood_theme_provider.dart';

/// Mood-aware version of Lumora's night-sky background: the gradient
/// smoothly retunes itself to whichever [AppMood] is selected in
/// [moodThemeProvider], while the moon, stars, sakura and butterfly
/// motifs stay put so the screen never stops feeling like Lumora.
class MoodGradientBackground extends ConsumerWidget {
  const MoodGradientBackground({super.key, this.child});

  /// Optional foreground content painted above the gradient and motifs.
  final Widget? child;

  static const _duration = Duration(milliseconds: 700);
  static const _curve = Curves.easeInOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(moodThemeProvider);
    final isHappy = mood == AppMood.happy;

    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: MoodGradients.forMood(mood),
          stops: MoodGradients.stops,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MoonAndStarsLayer(),
          AnimatedOpacity(
            duration: _duration,
            curve: _curve,
            opacity: isHappy ? 0.4 : 0.0,
            child: const _HappyGlow(),
          ),
          const Positioned(top: 0, left: 0, child: SakuraCorner()),
          const Positioned(top: 0, right: 0, child: SakuraCorner(mirrored: true)),
          const Positioned(top: 118, right: 46, child: Butterfly()),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// A soft pink radial glow used to lift the background slightly for the
/// "happy" mood, without touching the moon/stars/sakura motifs.
class _HappyGlow extends StatelessWidget {
  const _HappyGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.4, -0.6),
          radius: 1.1,
          colors: [
            LumoraPalette.softPink.withValues(alpha: 0.5),
            LumoraPalette.accentPink.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
