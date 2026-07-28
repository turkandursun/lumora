import 'package:flutter/material.dart';

import '../../../../theme/photo_ken_burns.dart';

/// Onboarding's full-bleed photo backdrop: one pastel ocean/sky scene per
/// page, crossfading smoothly as the user moves between beats, with the
/// same slow Ken Burns zoom/drift and readability scrim used by
/// [HomeMoodBackground] and [AuthPhotoBackground] elsewhere in the app.
class OnboardingPhotoBackground extends StatefulWidget {
  const OnboardingPhotoBackground({super.key, required this.pageIndex});

  /// Settled (rounded) page index — crossfades in over [_crossfadeDuration]
  /// whenever this changes, independent of how fast the underlying swipe
  /// gesture moved.
  final int pageIndex;

  static const List<String> assets = [
    'assets/images/onboarding_bg_1.png',
    'assets/images/onboarding_bg_2.png',
    'assets/images/onboarding_bg_3.png',
    'assets/images/onboarding_bg_4.png',
  ];

  @override
  State<OnboardingPhotoBackground> createState() =>
      _OnboardingPhotoBackgroundState();
}

class _OnboardingPhotoBackgroundState extends State<OnboardingPhotoBackground>
    with SingleTickerProviderStateMixin {
  static const _crossfadeDuration = Duration(milliseconds: 700);
  static const _kenBurnsDuration = Duration(seconds: 22);

  late final AnimationController _kenBurnsController;
  late final Animation<double> _scale;
  late final Animation<Alignment> _alignment;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _kenBurnsController =
        AnimationController(vsync: this, duration: _kenBurnsDuration)
          ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final path in OnboardingPhotoBackground.assets) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _kenBurnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = OnboardingPhotoBackground.assets[widget.pageIndex];

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: _crossfadeDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: KenBurnsPhoto(
            key: ValueKey(asset),
            asset: asset,
            scale: _scale,
            alignment: _alignment,
            imageAlignment: Alignment.topCenter,
          ),
        ),
        // Much lighter than the shared default scrim: onboarding's photos
        // are the whole point of the screen, so most of the frame should
        // stay at near-full visibility. Only two soft patches survive —
        // one behind the title/subtitle around the vertical middle, one
        // behind the dots/CTA button at the bottom — everything else
        // (including the top, where the pastel sky lives) is left clear.
        const PhotoReadabilityScrim(
          colors: [
            Color(0x00000000),
            Color(0x14000000),
            Color(0x26000000),
            Color(0x00000000),
            Color(0x40000000),
          ],
          stops: [0.0, 0.35, 0.55, 0.75, 1.0],
        ),
      ],
    );
  }
}
