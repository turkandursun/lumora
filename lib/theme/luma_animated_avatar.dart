import 'dart:async';

import 'package:flutter/material.dart';

enum LumaAnimationMode {
  ambient,
  speaking,
}

/// Frame-based LUMA animation shared by the pre-home authentication journey.
///
/// Ambient mode plays wave, blink and happy beats with quiet pauses between
/// them. Speaking mode loops only the mouth animation, so greeting text is not
/// interrupted by unrelated reactions.
class LumaAnimatedAvatar extends StatefulWidget {
  const LumaAnimatedAvatar({
    super.key,
    this.size = 100,
    this.mode = LumaAnimationMode.ambient,
  });

  final double size;
  final LumaAnimationMode mode;

  static const String fallbackAsset = 'assets/images/luma_star_closed.png';

  static const List<String> waveFrames = <String>[
    'assets/images/luma/wave/wave_1.png',
    'assets/images/luma/wave/wave_2.png',
    'assets/images/luma/wave/wave_3.png',
    'assets/images/luma/wave/wave_4.png',
    'assets/images/luma/wave/wave_5.png',
  ];

  static const List<String> blinkFrames = <String>[
    'assets/images/luma/blink/blink_1.png',
    'assets/images/luma/blink/blink_2.png',
    'assets/images/luma/blink/blink_3.png',
    'assets/images/luma/blink/blink_4.png',
    'assets/images/luma/blink/blink_5.png',
  ];

  static const List<String> happyFrames = <String>[
    'assets/images/luma/happy/happy_1.png',
    'assets/images/luma/happy/happy_2.png',
    'assets/images/luma/happy/happy_3.png',
    'assets/images/luma/happy/happy_4.png',
    'assets/images/luma/happy/happy_5.png',
  ];

  static const List<String> speakFrames = <String>[
    'assets/images/luma/speak/speak_1.png',
    'assets/images/luma/speak/speak_2.png',
    'assets/images/luma/speak/speak_3.png',
    'assets/images/luma/speak/speak_4.png',
    'assets/images/luma/speak/speak_5.png',
  ];

  static const List<int> waveOrder = <int>[0, 1, 2, 3, 4, 3, 2, 1, 0];
  // Hold the fully closed frame briefly so the blink remains readable on
  // smaller authentication-screen avatars.
  static const List<int> blinkOrder = <int>[0, 1, 2, 2, 2, 3, 4];
  static const List<int> happyOrder = <int>[0, 1, 2, 3, 4, 3, 2, 1, 0];
  static const List<int> speakOrder = <int>[0, 1, 2, 3, 4, 3, 2, 1];

  static const Duration waveFrameDuration = Duration(milliseconds: 120);
  static const Duration blinkFrameDuration = Duration(milliseconds: 100);
  static const Duration happyFrameDuration = Duration(milliseconds: 120);
  static const Duration speakFrameDuration = Duration(milliseconds: 130);
  static const Duration initialAmbientDelay = Duration(milliseconds: 420);
  static const Duration speakingBeatPause = Duration(milliseconds: 180);
  static const List<Duration> ambientPauses = <Duration>[
    Duration(milliseconds: 2600),
    Duration(milliseconds: 2500),
    Duration(milliseconds: 4000),
  ];

  @override
  State<LumaAnimatedAvatar> createState() => _LumaAnimatedAvatarState();
}

class _LumaAnimatedAvatarState extends State<LumaAnimatedAvatar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _floatController;
  late final Animation<double> _floatOffset;

  Timer? _frameTimer;
  Timer? _pauseTimer;
  late String _assetPath;
  int _sequenceIndex = 0;
  int _ambientStep = 0;
  int _speakingStep = 0;
  int _precacheGeneration = 0;
  bool _precacheStarted = false;
  bool _ready = false;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _assetPath = _baseAssetFor(widget.mode);
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
    unawaited(_prepareMode(widget.mode));
  }

  @override
  void didUpdateWidget(covariant LumaAnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) return;
    _cancelPlayback();
    _ready = false;
    _assetPath = _baseAssetFor(widget.mode);
    unawaited(_prepareMode(widget.mode));
  }

  String _baseAssetFor(LumaAnimationMode mode) =>
      mode == LumaAnimationMode.speaking
          ? LumaAnimatedAvatar.waveFrames.first
          : LumaAnimatedAvatar.waveFrames.first;

  List<String> _assetsFor(LumaAnimationMode mode) {
    if (mode == LumaAnimationMode.speaking) {
      return <String>[
        ...LumaAnimatedAvatar.waveFrames,
        ...LumaAnimatedAvatar.speakFrames,
      ];
    }
    return <String>[
      ...LumaAnimatedAvatar.waveFrames,
      ...LumaAnimatedAvatar.blinkFrames,
      ...LumaAnimatedAvatar.happyFrames,
    ];
  }

  Future<void> _prepareMode(LumaAnimationMode mode) async {
    final generation = ++_precacheGeneration;
    final assets = <String>{
      ..._assetsFor(mode),
      LumaAnimatedAvatar.fallbackAsset,
    };
    await Future.wait<void>(
      assets.map(
        (path) => precacheImage(
          AssetImage(path),
          context,
          onError: (_, __) {},
        ),
      ),
    );
    if (!mounted || generation != _precacheGeneration || widget.mode != mode) {
      return;
    }
    _ready = true;
    if (_isForeground) _startCurrentMode();
  }

  void _startCurrentMode() {
    _cancelPlayback();
    if (!_ready || !_isForeground) return;
    if (widget.mode == LumaAnimationMode.speaking) {
      _speakingStep = 0;
      _playSpeakingStep();
    } else {
      _ambientStep = 0;
      _setAsset(LumaAnimatedAvatar.waveFrames.first);
      _scheduleAmbientStep(LumaAnimatedAvatar.initialAmbientDelay);
    }
  }

  void _playSpeakingStep() {
    if (!_canAnimate || widget.mode != LumaAnimationMode.speaking) return;
    if (_speakingStep == 0) {
      _playSequence(
        frames: LumaAnimatedAvatar.waveFrames,
        order: LumaAnimatedAvatar.waveOrder,
        frameDuration: LumaAnimatedAvatar.waveFrameDuration,
        expectedMode: LumaAnimationMode.speaking,
        onCompleted: _completeSpeakingStep,
      );
    } else {
      _playSequence(
        frames: LumaAnimatedAvatar.speakFrames,
        order: LumaAnimatedAvatar.speakOrder,
        frameDuration: LumaAnimatedAvatar.speakFrameDuration,
        expectedMode: LumaAnimationMode.speaking,
        onCompleted: _completeSpeakingStep,
      );
    }
  }

  void _completeSpeakingStep() {
    if (!_canAnimate || widget.mode != LumaAnimationMode.speaking) return;
    _speakingStep = (_speakingStep + 1) % 2;
    _pauseTimer?.cancel();
    _pauseTimer = Timer(
      LumaAnimatedAvatar.speakingBeatPause,
      _playSpeakingStep,
    );
  }

  void _scheduleAmbientStep(Duration delay) {
    _pauseTimer?.cancel();
    _pauseTimer = Timer(delay, _playAmbientStep);
  }

  void _playAmbientStep() {
    if (!_canAnimate || widget.mode != LumaAnimationMode.ambient) return;
    switch (_ambientStep) {
      case 0:
        _playSequence(
          frames: LumaAnimatedAvatar.waveFrames,
          order: LumaAnimatedAvatar.waveOrder,
          frameDuration: LumaAnimatedAvatar.waveFrameDuration,
          expectedMode: LumaAnimationMode.ambient,
          onCompleted: _completeAmbientStep,
        );
        break;
      case 1:
        _playSequence(
          frames: LumaAnimatedAvatar.blinkFrames,
          order: LumaAnimatedAvatar.blinkOrder,
          frameDuration: LumaAnimatedAvatar.blinkFrameDuration,
          expectedMode: LumaAnimationMode.ambient,
          onCompleted: _completeAmbientStep,
        );
        break;
      case 2:
        _playSequence(
          frames: LumaAnimatedAvatar.happyFrames,
          order: LumaAnimatedAvatar.happyOrder,
          frameDuration: LumaAnimatedAvatar.happyFrameDuration,
          expectedMode: LumaAnimationMode.ambient,
          onCompleted: _completeAmbientStep,
        );
        break;
    }
  }

  void _playSequence({
    required List<String> frames,
    required List<int> order,
    required Duration frameDuration,
    required LumaAnimationMode expectedMode,
    required VoidCallback onCompleted,
  }) {
    _sequenceIndex = 0;
    _setAsset(frames[order.first]);
    _frameTimer = Timer.periodic(frameDuration, (timer) {
      if (!_canAnimate || widget.mode != expectedMode) {
        timer.cancel();
        return;
      }
      _sequenceIndex += 1;
      if (_sequenceIndex >= order.length) {
        timer.cancel();
        _frameTimer = null;
        onCompleted();
        return;
      }
      _setAsset(frames[order[_sequenceIndex]]);
    });
  }

  void _completeAmbientStep() {
    if (!_canAnimate || widget.mode != LumaAnimationMode.ambient) return;
    _setAsset(LumaAnimatedAvatar.waveFrames.first);
    final completedStep = _ambientStep;
    _ambientStep = (_ambientStep + 1) % 3;
    _scheduleAmbientStep(LumaAnimatedAvatar.ambientPauses[completedStep]);
  }

  bool get _canAnimate => mounted && _isForeground && _ready;

  void _setAsset(String path) {
    if (!mounted || _assetPath == path) return;
    setState(() => _assetPath = path);
  }

  void _cancelPlayback() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _pauseTimer?.cancel();
    _pauseTimer = null;
  }

  void _pauseAnimations() {
    _isForeground = false;
    _cancelPlayback();
    _floatController.stop();
    _setAsset(_baseAssetFor(widget.mode));
  }

  void _resumeAnimations() {
    if (!mounted) return;
    _isForeground = true;
    _floatController.repeat();
    _startCurrentMode();
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
    _precacheGeneration += 1;
    _cancelPlayback();
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
            _assetPath,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              LumaAnimatedAvatar.fallbackAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}
