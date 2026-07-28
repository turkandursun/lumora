import 'package:flutter/material.dart';

import '../../../../theme/photo_ken_burns.dart';

/// Shared full-bleed background for Lumora's auth screens (login, sign up):
/// a static pastel sakura-path photo with a slow Ken Burns zoom/drift and a
/// readability scrim, matching the treatment Home applies to its mood
/// photos — just without Home's mood-driven crossfade, since these screens
/// only ever show one image.
class AuthPhotoBackground extends StatefulWidget {
  const AuthPhotoBackground({super.key});

  static const asset = 'assets/images/signup_background.png';

  @override
  State<AuthPhotoBackground> createState() => _AuthPhotoBackgroundState();
}

class _AuthPhotoBackgroundState extends State<AuthPhotoBackground>
    with SingleTickerProviderStateMixin {
  static const _kenBurnsDuration = Duration(seconds: 28);

  late final AnimationController _kenBurnsController;
  late final Animation<double> _scale;
  late final Animation<Alignment> _alignment;

  @override
  void initState() {
    super.initState();
    _kenBurnsController =
        AnimationController(vsync: this, duration: _kenBurnsDuration)
          ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );
    _alignment =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight)
            .animate(
              CurvedAnimation(
                parent: _kenBurnsController,
                curve: Curves.easeInOut,
              ),
            );
  }

  @override
  void dispose() {
    _kenBurnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        KenBurnsPhoto(
          asset: AuthPhotoBackground.asset,
          scale: _scale,
          alignment: _alignment,
          imageAlignment: Alignment.topCenter,
        ),
        const PhotoReadabilityScrim(),
      ],
    );
  }
}
