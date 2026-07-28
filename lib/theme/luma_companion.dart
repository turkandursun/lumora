import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/app_lock/domain/app_section.dart';
import '../features/app_lock/presentation/widgets/section_lock_gate.dart';
import '../l10n/generated/app_localizations.dart';
import 'luma_chat_sheet.dart';
import 'lumora_palette.dart';
import 'mood_gradients.dart';
import 'mood_theme_provider.dart';

/// Test-only seam: when set, [_LumaCompanionState] uses this instead of
/// constructing a real [AudioPlayer], so widget tests can inject a fake
/// player and assert on play/pause call patterns without touching actual
/// platform audio channels. Left `null` (real player) in production.
@visibleForTesting
AudioPlayer Function()? debugRainPlayerFactory;

/// Luma — a small glowing moon-butterfly spirit that keeps the user
/// company on the home screen. Self-contained: owns its own idle
/// animations, its own speech bubble (greeting on load, then a
/// mood-acknowledging line once a mood is picked), and its own ambient
/// particle system — all driven off the same [moodThemeProvider] that
/// drives the background gradient, so every mood-reactive surface reads
/// from one source of truth.
///
/// Expects to be given the full available space (e.g. as the `child` of
/// [MoodGradientBackground], mirroring that widget's own child-slot
/// pattern) so its particle layer can drift across the whole screen
/// while Luma itself sits near the top-left; [child] is painted above
/// everything else.
class LumaCompanion extends ConsumerStatefulWidget {
  const LumaCompanion({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<LumaCompanion> createState() => _LumaCompanionState();
}

class _LumaCompanionState extends ConsumerState<LumaCompanion>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _flutterController;
  late final AnimationController _glowController;
  late final AnimationController _particleController;

  late int _greetingIndex;
  AppMood? _ackMood;

  static const _defaultBobPeriod = Duration(milliseconds: 3000);
  static const _defaultFlutterPeriod = Duration(milliseconds: 2400);

  // --- Ambient rain sound (sad mood only) ---------------------------------
  static const _rainAssetPath = 'audio/rain_loop.mp3';
  static const _rainTargetVolume = 0.3;
  static const _rainFadeDuration = Duration(milliseconds: 900);
  static const _soundMutedPrefKey = 'luma_ambient_sound_muted';

  late final AudioPlayer _rainPlayer;
  late final AnimationController _rainFadeController;

  /// Whether the loop is currently playing/resumed at the platform level —
  /// tracked so mood flicker (sad -> other -> sad) only ever crossfades the
  /// same running loop instead of issuing overlapping `play()` calls.
  bool _rainStarted = false;
  bool _rainSoundMuted = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _greetingIndex = Random().nextInt(5);

    _bobController = AnimationController(vsync: this, duration: _defaultBobPeriod)
      ..repeat(reverse: true);
    _flutterController =
        AnimationController(vsync: this, duration: _defaultFlutterPeriod)
          ..repeat(reverse: true);
    _glowController = AnimationController(
      vsync: this,
      duration: _MoodLumaStyle.of(null).glowPeriod,
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rainPlayer = (debugRainPlayerFactory ?? AudioPlayer.new)();
    _safeAudioCall(() => _rainPlayer.setReleaseMode(ReleaseMode.loop));
    _rainFadeController = AnimationController(vsync: this, duration: _rainFadeDuration)
      ..addListener(() {
        _safeAudioCall(
          () => _rainPlayer.setVolume(_rainFadeController.value * _rainTargetVolume),
        );
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && _rainStarted) {
          _rainStarted = false;
          _safeAudioCall(() => _rainPlayer.pause());
        }
      });
    _loadSoundPreference();
  }

  @override
  void dispose() {
    _bobController.dispose();
    _flutterController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _rainFadeController.dispose();
    // Stops playback outright (no fade) — the screen itself is going away,
    // so there is nothing left to smoothly transition to.
    _safeAudioCall(() => _rainPlayer.dispose());
    super.dispose();
  }

  void _safeAudioCall(Future<void> Function() call) {
    // Ambient sound is a nice-to-have, not core functionality: swallow
    // platform/plugin errors (e.g. missing audio backend, disposed player
    // races) rather than letting them surface as uncaught exceptions.
    call().catchError((Object _) {});
  }

  Future<void> _loadSoundPreference() async {
    bool muted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      muted = prefs.getBool(_soundMutedPrefKey) ?? false;
    } catch (_) {
      // Fall back to unmuted if local prefs are unavailable.
    }
    if (!mounted) return;
    setState(() {
      _rainSoundMuted = muted;
      _prefsLoaded = true;
    });
    _syncRainSound(ref.read(moodThemeProvider));
  }

  Future<void> _toggleSoundMuted() async {
    final next = !_rainSoundMuted;
    setState(() => _rainSoundMuted = next);
    _syncRainSound(ref.read(moodThemeProvider));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundMutedPrefKey, next);
    } catch (_) {
      // Preference just won't persist across launches; playback state is
      // already correct either way.
    }
  }

  /// Starts/crossfades or fades out the looping rain sound so it plays
  /// only while "sad" is the active mood and the user hasn't muted it.
  /// Only ever touches the single [_rainPlayer] instance — never creates a
  /// second one — so repeated sad/not-sad toggling can't stack audio.
  void _syncRainSound(AppMood? mood) {
    if (!_prefsLoaded) return;
    final shouldPlay = mood == AppMood.sad && !_rainSoundMuted;
    if (shouldPlay) {
      if (!_rainStarted) {
        _rainStarted = true;
        _safeAudioCall(() => _rainPlayer.play(AssetSource(_rainAssetPath), volume: 0));
      }
      _rainFadeController.forward();
    } else {
      _rainFadeController.reverse();
    }
  }

  void _applyMoodPacing(AppMood? mood) {
    final style = _MoodLumaStyle.of(mood);
    _glowController.repeat(reverse: true, period: style.glowPeriod);
    _bobController.repeat(reverse: true, period: style.bobPeriod);
    _flutterController.repeat(reverse: true, period: style.flutterPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mood = ref.watch(moodThemeProvider);

    ref.listen<AppMood?>(moodThemeProvider, (previous, next) {
      if (next == previous) return;
      if (next != null) {
        setState(() => _ackMood = next);
        _applyMoodPacing(next);
      }
      _syncRainSound(next);
    });

    final style = _MoodLumaStyle.of(mood);
    final bubbleText = _ackMood != null
        ? _moodAckText(l10n, _ackMood!)
        : _greetingText(l10n, _greetingIndex);

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: _MoodParticlesPainter(controller: _particleController, mood: mood),
            size: Size.infinite,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _LumaGlyph(
                    bobController: _bobController,
                    flutterController: _flutterController,
                    glowController: _glowController,
                    style: style,
                  ),
                  _SoundToggleButton(
                    muted: _rainSoundMuted,
                    onTap: _toggleSoundMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SpeechBubble(
                      text: bubbleText,
                      onTap: () => _openChat(mood),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }

  String _greetingText(AppLocalizations l10n, int index) {
    switch (index) {
      case 0:
        return l10n.lumaGreeting1;
      case 1:
        return l10n.lumaGreeting2;
      case 2:
        return l10n.lumaGreeting3;
      case 3:
        return l10n.lumaGreeting4;
      default:
        return l10n.lumaGreeting5;
    }
  }

  Future<void> _openChat(AppMood? mood) async {
    final unlocked = await ensureSectionUnlocked(context, ref, AppSection.aiChat);
    if (!unlocked || !mounted) return;
    LumaChatSheet.show(
      context,
      moodContext: mood == null ? null : 'Current selected mood: ${mood.name}',
    );
  }

  String _moodAckText(AppLocalizations l10n, AppMood mood) {
    switch (mood) {
      case AppMood.happy:
        return l10n.lumaMoodAckHappy;
      case AppMood.calm:
        return l10n.lumaMoodAckCalm;
      case AppMood.tired:
        return l10n.lumaMoodAckTired;
      case AppMood.sad:
        return l10n.lumaMoodAckSad;
      case AppMood.anxious:
        return l10n.lumaMoodAckAnxious;
    }
  }
}

/// Per-mood visual pacing/color for Luma's glow and idle animations —
/// intentionally kept private to this widget (Luma owns its own mood
/// mapping, independent of [MoodGradients]'s background mapping).
class _MoodLumaStyle {
  const _MoodLumaStyle({
    required this.glowColor,
    required this.baseAlpha,
    required this.pulseAmplitude,
    required this.glowPeriod,
    required this.bobPeriod,
    required this.flutterPeriod,
  });

  final Color glowColor;
  final double baseAlpha;
  final double pulseAmplitude;
  final Duration glowPeriod;
  final Duration bobPeriod;
  final Duration flutterPeriod;

  static const _bobDefault = Duration(milliseconds: 3000);
  static const _flutterDefault = Duration(milliseconds: 2400);

  static _MoodLumaStyle of(AppMood? mood) {
    switch (mood) {
      case AppMood.happy:
        return _MoodLumaStyle(
          glowColor: Color.lerp(LumoraPalette.lightPurple, LumoraPalette.accentPink, 0.55)!,
          baseAlpha: 0.55,
          pulseAmplitude: 0.08,
          glowPeriod: const Duration(milliseconds: 2600),
          bobPeriod: _bobDefault,
          flutterPeriod: _flutterDefault,
        );
      case AppMood.tired:
        return _MoodLumaStyle(
          glowColor: Color.lerp(LumoraPalette.lightPurple, const Color(0xFF3D3560), 0.4)!,
          baseAlpha: 0.26,
          pulseAmplitude: 0.05,
          glowPeriod: const Duration(milliseconds: 4500),
          bobPeriod: Duration(milliseconds: (_bobDefault.inMilliseconds * 1.6).round()),
          flutterPeriod: Duration(milliseconds: (_flutterDefault.inMilliseconds * 1.6).round()),
        );
      case AppMood.sad:
        return _MoodLumaStyle(
          glowColor: Color.lerp(LumoraPalette.lightPurple, const Color(0xFF4A4E8A), 0.35)!,
          baseAlpha: 0.30,
          pulseAmplitude: 0.05,
          glowPeriod: const Duration(milliseconds: 3200),
          bobPeriod: _bobDefault,
          flutterPeriod: _flutterDefault,
        );
      case AppMood.anxious:
        return _MoodLumaStyle(
          glowColor: Color.lerp(LumoraPalette.lightPurple, const Color(0xFF4C4568), 0.3)!,
          baseAlpha: 0.35,
          pulseAmplitude: 0.20,
          // Half-cycle of 2s -> full pulse (up+down) every ~4s.
          glowPeriod: const Duration(milliseconds: 2000),
          bobPeriod: _bobDefault,
          flutterPeriod: _flutterDefault,
        );
      case AppMood.calm:
      case null:
        return const _MoodLumaStyle(
          glowColor: LumoraPalette.lightPurple,
          baseAlpha: 0.40,
          pulseAmplitude: 0.08,
          glowPeriod: Duration(milliseconds: 2800),
          bobPeriod: _bobDefault,
          flutterPeriod: _flutterDefault,
        );
    }
  }
}

/// The moon-butterfly glyph itself: a floating, fluttering, glowing
/// small presence roughly 70-80px across.
class _LumaGlyph extends StatelessWidget {
  const _LumaGlyph({
    required this.bobController,
    required this.flutterController,
    required this.glowController,
    required this.style,
  });

  final AnimationController bobController;
  final AnimationController flutterController;
  final AnimationController glowController;
  final _MoodLumaStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bobController,
      builder: (context, child) {
        final bob = (Curves.easeInOut.transform(bobController.value) - 0.5) * 10;
        return Transform.translate(offset: Offset(0, bob), child: child);
      },
      child: SizedBox(
        width: 78,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(78, 50),
              painter: _LumaWingsPainter(
                controller: flutterController,
                color: style.glowColor,
              ),
            ),
            AnimatedBuilder(
              animation: glowController,
              builder: (context, _) {
                final pulse = Curves.easeInOut.transform(glowController.value);
                final alpha = (style.baseAlpha + (pulse - 0.5) * 2 * style.pulseAmplitude)
                    .clamp(0.05, 0.95);
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      colors: [
                        Color.lerp(LumoraPalette.warmCream, style.glowColor, 0.35)!
                            .withValues(alpha: 0.95),
                        style.glowColor.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: style.glowColor.withValues(alpha: alpha),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Two thin, translucent wings that gently open/close and tilt in a
/// slow, serene loop — driven by [controller] without ever rebuilding
/// the widget tree (repaints the canvas directly).
class _LumaWingsPainter extends CustomPainter {
  _LumaWingsPainter({required this.controller, required this.color})
      : super(repaint: controller);

  final AnimationController controller;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(controller.value);
    final wingScale = 0.86 + 0.14 * t;
    final tilt = (t - 0.5) * 0.18;
    final center = Offset(size.width / 2, size.height / 2);

    _drawWing(canvas, center, isLeft: true, scale: wingScale, tilt: -tilt);
    _drawWing(canvas, center, isLeft: false, scale: wingScale, tilt: tilt);
  }

  void _drawWing(
    Canvas canvas,
    Offset center, {
    required bool isLeft,
    required double scale,
    required double tilt,
  }) {
    final sign = isLeft ? -1.0 : 1.0;
    final fill = Paint()..color = color.withValues(alpha: 0.28);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.scale(1, scale);

    final wing = Path()
      ..moveTo(0, -2)
      ..cubicTo(sign * 20, -22, sign * 26, 4, 0, 6)
      ..cubicTo(sign * 14, 12, sign * 12, 24, 0, 18)
      ..close();

    canvas.drawPath(wing, fill);
    canvas.drawPath(wing, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LumaWingsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Small, unobtrusive speaker icon next to Luma that lets the user mute
/// ambient sound (currently just the "sad" mood's rain loop) entirely,
/// independent of whichever mood is active.
class _SoundToggleButton extends StatelessWidget {
  const _SoundToggleButton({required this.muted, required this.onTap});

  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = muted ? l10n.lumaSoundOffTooltip : l10n.lumaSoundOnTooltip;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft, rounded speech bubble showing Luma's current line, crossfading
/// smoothly whenever the text changes. Tapping it (or the small chat icon
/// on its trailing edge) opens Luma's chat panel — see [LumaChatSheet].
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.lumaChatTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      text,
                      key: ValueKey(text),
                      style: LumoraPalette.bodyStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One reusable slot in the ambient particle pool: randomized once and
/// reused across moods with different counts/formulas, so the pool never
/// needs to grow/shrink at runtime.
class _ParticleSlot {
  const _ParticleSlot(this.dx, this.dy, this.phase, this.sizeFactor, this.colorIndex);

  final double dx;
  final double dy;
  final double phase;
  final double sizeFactor;
  final int colorIndex;
}

final List<_ParticleSlot> _particleSlots = List.generate(32, (i) {
  final rnd = Random(i * 131 + 7);
  return _ParticleSlot(
    rnd.nextDouble(),
    rnd.nextDouble(),
    rnd.nextDouble(),
    0.7 + rnd.nextDouble() * 0.6,
    i % 2,
  );
});

/// Lightweight ambient particle system: a capped pool of ~10-15 particles
/// whose position/opacity is a pure function of elapsed time, recomputed
/// each frame directly in [paint] (no per-frame state mutation, no
/// rebuilds) — repaints are driven purely by [controller] via the
/// [CustomPainter.repaint] listenable.
class _MoodParticlesPainter extends CustomPainter {
  _MoodParticlesPainter({required this.controller, required this.mood})
      : super(repaint: controller);

  final AnimationController controller;
  final AppMood? mood;

  @override
  void paint(Canvas canvas, Size size) {
    final raw = controller.value;
    switch (mood ?? AppMood.calm) {
      case AppMood.happy:
        _paintHappy(canvas, size, raw);
        break;
      case AppMood.calm:
        _paintCalm(canvas, size, raw);
        break;
      case AppMood.tired:
        _paintTired(canvas, size, raw);
        break;
      case AppMood.sad:
        _paintSad(canvas, size, raw);
        break;
      case AppMood.anxious:
        _paintAnxious(canvas, size, raw);
        break;
    }
  }

  double _loop(double raw, double speed, double phase) => (raw * speed + phase) % 1.0;

  void _paintHappy(Canvas canvas, Size size, double raw) {
    const colors = [LumoraPalette.softPink, LumoraPalette.warmCream];
    for (final slot in _particleSlots.take(24)) {
      final t = _loop(raw, 1.3, slot.phase);
      final op = (sin(pi * t) * 0.85).clamp(0.0, 1.0);
      if (op <= 0.01) continue;
      final edgeDx = slot.dx < 0.5 ? slot.dx * 0.28 : 1 - (1 - slot.dx) * 0.28;
      final y = (0.25 + slot.dy * 0.65 - t * 0.14) * size.height;
      final x = edgeDx * size.width;
      final color = colors[slot.colorIndex];
      final radius = 5.6 * slot.sizeFactor;

      canvas.drawCircle(
        Offset(x, y),
        radius * 1.8,
        Paint()
          ..color = color.withValues(alpha: op * 0.55)
          ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
      canvas.drawCircle(Offset(x, y), radius * 0.65, Paint()..color = color.withValues(alpha: op));
    }
  }

  void _paintCalm(Canvas canvas, Size size, double raw) {
    for (final slot in _particleSlots.take(18)) {
      final t = _loop(raw, 0.6, slot.phase);
      var op = 1.0;
      if (t < 0.1) {
        op = t / 0.1;
      } else if (t > 0.9) {
        op = (1 - t) / 0.1;
      }
      op *= 0.6;
      final x = (slot.dx + sin(t * 2 * pi * 2 + slot.phase * 10) * 0.02) * size.width;
      final y = t * size.height;
      final radius = 4.2 * slot.sizeFactor;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = LumoraPalette.lightPurple.withValues(alpha: op)
          ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 3),
      );
    }
  }

  void _paintTired(Canvas canvas, Size size, double raw) {
    for (final slot in _particleSlots.take(20)) {
      final wander = _loop(raw, 0.35, slot.phase);
      final x = (slot.dx + sin(wander * 2 * pi + slot.phase * 7) * 0.03) * size.width;
      final y = (slot.dy + cos(wander * 2 * pi * 0.7 + slot.phase * 5) * 0.03) * size.height;
      final op = (0.5 + 0.5 * sin(raw * 2 * pi * 4 + slot.phase * 6)) * 0.55;
      final radius = 4.0 * slot.sizeFactor;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = LumoraPalette.softPink.withValues(alpha: op)
          ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 3),
      );
    }
  }

  void _paintSad(Canvas canvas, Size size, double raw) {
    // Rain must stay clearly visible without moving faster — count,
    // opacity, and streak length are all boosted, but the fall speed
    // (0.7) is untouched so the mood keeps reading as calm/slow.
    //
    // Each drop is a thin tapered teardrop/streak — a wider rounded head
    // (leading, direction of fall) narrowing to a fine point at the tail —
    // rather than a flat uniform line, with a linear gradient fading from
    // opaque at the head to transparent at the tail for a soft
    // motion-blur feel. A slight lean off vertical keeps it reading as
    // gentle falling motion rather than static hatching.
    const streakLenFrac = 0.15;
    const tilt = 0.065;
    const dropColor = Color(0xFF8B5CF6);

    for (final slot in _particleSlots.take(28)) {
      final t = _loop(raw, 0.7, slot.phase);
      var op = 0.46;
      if (t < 0.08) {
        op *= t / 0.08;
      } else if (t > 0.92) {
        op *= (1 - t) / 0.08;
      }
      if (op <= 0.01) continue;

      final length = streakLenFrac * size.height * (0.8 + 0.4 * slot.sizeFactor);
      final headX = slot.dx * size.width;
      final headY = t * size.height;
      final tailOffsetX = length * tilt;
      final tail = Offset(headX - tailOffsetX, headY - length);

      final dx = tail.dx - headX;
      final dy = tail.dy - headY;
      final segLen = sqrt(dx * dx + dy * dy);
      if (segLen <= 0) continue;
      final nx = -dy / segLen;
      final ny = dx / segLen;

      final headWidth = 1.5 * slot.sizeFactor;
      final headLeft = Offset(headX + nx * headWidth / 2, headY + ny * headWidth / 2);
      final headRight = Offset(headX - nx * headWidth / 2, headY - ny * headWidth / 2);

      // Bulge control points sit close to the head so the width falls off
      // quickly, then the streak narrows to a fine point at the tail.
      const bulge = 0.28;
      final ctrlLeft = Offset(headLeft.dx + dx * bulge, headLeft.dy + dy * bulge);
      final ctrlRight = Offset(headRight.dx + dx * bulge, headRight.dy + dy * bulge);

      final path = Path()
        ..moveTo(tail.dx, tail.dy)
        ..quadraticBezierTo(ctrlLeft.dx, ctrlLeft.dy, headLeft.dx, headLeft.dy)
        ..lineTo(headRight.dx, headRight.dy)
        ..quadraticBezierTo(ctrlRight.dx, ctrlRight.dy, tail.dx, tail.dy)
        ..close();

      final shader = ui.Gradient.linear(
        Offset(headX, headY),
        tail,
        [dropColor.withValues(alpha: op), dropColor.withValues(alpha: 0.0)],
      );

      canvas.drawPath(path, Paint()..shader = shader);
    }
  }

  void _paintAnxious(Canvas canvas, Size size, double raw) {
    const leafColor = Color(0xFFB8A9D9);
    for (final slot in _particleSlots.take(22)) {
      final s = _loop(raw, 0.5, slot.phase);
      var op = 1.0;
      if (s < 0.15) {
        op = s / 0.15;
      } else if (s > 0.8) {
        op = (1 - s) / 0.2;
      }
      op *= 0.58;
      if (op <= 0.01) continue;

      final angle = s * 2 * pi * 1.5 + slot.phase * 10;
      final radius = (0.05 + 0.03 * sin(s * pi)) * size.width;
      final cx = slot.dx * size.width;
      final cy = s * size.height;
      final x = cx + cos(angle) * radius;
      final y = cy + sin(angle) * radius * 0.6;
      final leafSize = 8.4 * slot.sizeFactor;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: leafSize, height: leafSize * 0.5),
        Paint()..color = leafColor.withValues(alpha: op),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MoodParticlesPainter oldDelegate) => oldDelegate.mood != mood;
}
