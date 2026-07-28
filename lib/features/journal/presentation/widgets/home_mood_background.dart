import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/mood_gradients.dart';
import '../../../../theme/mood_theme_provider.dart';
import '../../../../theme/photo_ken_burns.dart';

/// Mood-aware Home background: crossfades between five mood photographs
/// (calm/happy/tired/sad/anxious) as [moodThemeProvider] changes, with a
/// slow Ken Burns zoom/pan on whichever image is currently showing and a
/// dark readability scrim so foreground content stays legible on top.
class HomeMoodBackground extends ConsumerStatefulWidget {
  const HomeMoodBackground({super.key, this.child});

  final Widget? child;

  static const Map<AppMood, String> assets = {
    AppMood.calm: 'assets/images/home_bg_calm.png',
    AppMood.happy: 'assets/images/home_bg_happy.png',
    AppMood.tired: 'assets/images/home_bg_tired.png',
    AppMood.sad: 'assets/images/home_bg_sad.png',
    AppMood.anxious: 'assets/images/home_bg_anxious.png',
  };

  static String assetFor(AppMood? mood) => assets[mood ?? AppMood.calm]!;

  @override
  ConsumerState<HomeMoodBackground> createState() => _HomeMoodBackgroundState();
}

class _HomeMoodBackgroundState extends ConsumerState<HomeMoodBackground>
    with SingleTickerProviderStateMixin {
  static const _crossfadeDuration = Duration(milliseconds: 700);
  static const _kenBurnsDuration = Duration(seconds: 18);

  late final AnimationController _kenBurnsController;
  late final Animation<double> _scale;
  late final Animation<Alignment> _alignment;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _kenBurnsController = AnimationController(vsync: this, duration: _kenBurnsDuration)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );
    _alignment = AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight).animate(
      CurvedAnimation(parent: _kenBurnsController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    for (final path in HomeMoodBackground.assets.values) {
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
    final mood = ref.watch(moodThemeProvider);
    final asset = HomeMoodBackground.assetFor(mood);

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: _crossfadeDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [...previousChildren, if (currentChild != null) currentChild],
          ),
          child: KenBurnsPhoto(
            key: ValueKey(asset),
            asset: asset,
            scale: _scale,
            alignment: _alignment,
          ),
        ),
        const PhotoReadabilityScrim(),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
