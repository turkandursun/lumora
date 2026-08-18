import 'dart:async';

import 'package:flutter/material.dart';

/// A lightweight frame-by-frame LUMA wave prototype.
///
/// The existing [LumaAvatar] remains the app-wide mascot implementation. This
/// widget is intentionally isolated so the PNG sequence can be evaluated on
/// the login screen without changing any other LUMA surface.
class LumaWaveAvatar extends StatefulWidget {
  const LumaWaveAvatar({
    super.key,
    this.size = 105,
  });

  final double size;

  static const List<String> frameAssets = <String>[
    'assets/images/luma/wave/wave_1.png',
    'assets/images/luma/wave/wave_2.png',
    'assets/images/luma/wave/wave_3.png',
    'assets/images/luma/wave/wave_4.png',
    'assets/images/luma/wave/wave_5.png',
  ];

  static const List<int> waveFrameOrder = <int>[0, 1, 2, 3, 4, 3, 2, 1, 0];
  static const Duration frameDuration = Duration(milliseconds: 120);
  static const Duration initialWaveDelay = Duration(milliseconds: 420);
  static const Duration idleInterval = Duration(milliseconds: 5500);

  @override
  State<LumaWaveAvatar> createState() => _LumaWaveAvatarState();
}

class _LumaWaveAvatarState extends State<LumaWaveAvatar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  Timer? _initialWaveTimer;
  Timer? _frameTimer;
  Timer? _idleTimer;

  int _frameIndex = 0;
  int _sequenceIndex = 0;
  bool _precacheStarted = false;
  bool _precacheComplete = false;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _floatOffset = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -2.5, end: 2.5).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 2.5, end: -2.5).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(_floatController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) return;
    _precacheStarted = true;
    unawaited(_precacheFrames());
  }

  Future<void> _precacheFrames() async {
    await Future.wait<void>(
      LumaWaveAvatar.frameAssets.map(
        (path) => precacheImage(AssetImage(path), context),
      ),
    );
    if (!mounted) return;
    _precacheComplete = true;
    if (_isForeground) _scheduleInitialWave();
  }

  void _scheduleInitialWave() {
    _initialWaveTimer?.cancel();
    _initialWaveTimer = Timer(LumaWaveAvatar.initialWaveDelay, _playWave);
  }

  void _scheduleNextWave() {
    _idleTimer?.cancel();
    if (!_isForeground || !_precacheComplete) return;
    _idleTimer = Timer(LumaWaveAvatar.idleInterval, _playWave);
  }

  void _playWave() {
    if (!mounted || !_isForeground || !_precacheComplete) return;
    if (_frameTimer?.isActive ?? false) return;

    _sequenceIndex = 0;
    if (_frameIndex != LumaWaveAvatar.waveFrameOrder.first) {
      setState(() => _frameIndex = LumaWaveAvatar.waveFrameOrder.first);
    }

    _frameTimer = Timer.periodic(LumaWaveAvatar.frameDuration, (timer) {
      if (!mounted || !_isForeground) {
        timer.cancel();
        return;
      }

      _sequenceIndex += 1;
      setState(() {
        _frameIndex = LumaWaveAvatar.waveFrameOrder[_sequenceIndex];
      });

      if (_sequenceIndex == LumaWaveAvatar.waveFrameOrder.length - 1) {
        timer.cancel();
        _frameTimer = null;
        _scheduleNextWave();
      }
    });
  }

  void _pauseAnimations() {
    _isForeground = false;
    _initialWaveTimer?.cancel();
    _frameTimer?.cancel();
    _frameTimer = null;
    _idleTimer?.cancel();
    _floatController.stop();
    if (mounted && _frameIndex != 0) {
      setState(() => _frameIndex = 0);
    }
  }

  void _resumeAnimations() {
    if (!mounted) return;
    _isForeground = true;
    _floatController.repeat();
    _scheduleNextWave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeAnimations();
    } else {
      _pauseAnimations();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialWaveTimer?.cancel();
    _frameTimer?.cancel();
    _idleTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _floatOffset,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _floatOffset.value),
          child: child,
        ),
        child: SizedBox.square(
          dimension: widget.size,
          child: Image.asset(
            LumaWaveAvatar.frameAssets[_frameIndex],
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
