import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../goals/domain/goal_template.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../domain/breathing_pattern.dart';

const _lastModePrefKey = 'breathing_last_mode';

/// Icon and localized label for each [BreathingMode] — kept in the
/// presentation layer since [BreathingMode] itself (and its
/// [BreathingPattern] timing) is a plain domain concern.
extension _BreathingModeDisplay on BreathingMode {
  IconData get icon {
    switch (this) {
      case BreathingMode.calmAnger:
        return Icons.local_fire_department_outlined;
      case BreathingMode.easeAnxiety:
        return Icons.cloud_outlined;
      case BreathingMode.relaxUnwind:
        return Icons.nightlight_round;
      case BreathingMode.boostEnergy:
        return Icons.wb_sunny_outlined;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case BreathingMode.calmAnger:
        return l10n.breathingModeCalmAnger;
      case BreathingMode.easeAnxiety:
        return l10n.breathingModeEaseAnxiety;
      case BreathingMode.relaxUnwind:
        return l10n.breathingModeRelaxUnwind;
      case BreathingMode.boostEnergy:
        return l10n.breathingModeBoostEnergy;
    }
  }
}

/// Which part of the flow the screen is currently showing.
enum _SessionStage { selectingMode, selectingDuration, running, completed }

/// Guided breathing exercise — pick the technique that matches what you
/// need right now, pick a duration, follow an expanding and contracting
/// orb through that technique's inhale/hold/exhale cycle, and land on a
/// gentle completion message once the chosen time is up.
class BreathingScreen extends ConsumerStatefulWidget {
  const BreathingScreen({super.key});

  @override
  ConsumerState<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _durationOptionsMinutes = [2, 4, 6];

  late final AnimationController _breathController;

  Timer? _countdownTimer;
  BreathingMode _selectedMode = BreathingMode.calmAnger;
  int _selectedMinutes = _durationOptionsMinutes[1];
  int _remainingSeconds = 0;
  _SessionStage _stage = _SessionStage.selectingMode;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    _breathController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _loadLastMode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_lastModePrefKey);
      for (final mode in BreathingMode.values) {
        if (mode.name == saved) {
          if (mounted) setState(() => _selectedMode = mode);
          break;
        }
      }
    } catch (_) {
      // Fall back to the default mode if local prefs are unavailable.
    }
  }

  Future<void> _selectMode(BreathingMode mode) async {
    setState(() => _selectedMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastModePrefKey, mode.name);
    } catch (_) {
      // Preference just won't persist across launches/sessions.
    }
  }

  void _confirmMode() {
    setState(() => _stage = _SessionStage.selectingDuration);
  }

  void _start() {
    setState(() {
      _completionHandled = false;
      _stage = _SessionStage.running;
      _remainingSeconds = _selectedMinutes * 60;
    });
    _breathController
      ..duration = _selectedMode.pattern.total
      ..reset()
      ..repeat();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        unawaited(_finish());
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _stop() {
    _countdownTimer?.cancel();
    _breathController.stop();
    setState(() => _stage = _SessionStage.selectingMode);
  }

  Future<void> _finish() async {
    if (_completionHandled) return;
    _completionHandled = true;
    _countdownTimer?.cancel();
    _breathController.stop();
    setState(() => _stage = _SessionStage.completed);
    // Auto-advance the "breathing" goal by the minutes just completed.
    await ref.read(goalsRepositoryProvider).incrementByTemplateKey(
          GoalTemplateKeys.breathing,
          _selectedMinutes,
        );
    await ref.read(goalStreakProvider.notifier).refresh();
  }

  void _backToModeSelector() {
    setState(() => _stage = _SessionStage.selectingMode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(l10n.breathingTitle,
                            style: AstraKit.heading1(isDark, fontSize: 22)),
                      ),
                    ],
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: switch (_stage) {
                        _SessionStage.selectingMode => _ModeSelectorView(
                            key: const ValueKey(_SessionStage.selectingMode),
                            selectedMode: _selectedMode,
                            isDark: isDark,
                            primary: primary,
                            onSelected: _selectMode,
                            onNext: _confirmMode,
                          ),
                        _SessionStage.selectingDuration =>
                          _DurationSelectorView(
                            key:
                                const ValueKey(_SessionStage.selectingDuration),
                            selectedMinutes: _selectedMinutes,
                            options: _durationOptionsMinutes,
                            isDark: isDark,
                            primary: primary,
                            onSelected: (minutes) =>
                                setState(() => _selectedMinutes = minutes),
                            onStart: _start,
                          ),
                        _SessionStage.running => _RunningView(
                            key: const ValueKey(_SessionStage.running),
                            breathController: _breathController,
                            pattern: _selectedMode.pattern,
                            remainingSeconds: _remainingSeconds,
                            isDark: isDark,
                            primary: primary,
                            onStop: _stop,
                          ),
                        _SessionStage.completed => _CompletedView(
                            key: const ValueKey(_SessionStage.completed),
                            isDark: isDark,
                            primary: primary,
                            onContinue: _backToModeSelector,
                          ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// First step: "What do you need right now?" — a 2x2 grid of selectable
/// mode cards, each mapped to a real breathing technique, plus a button
/// to confirm the choice and move on to the duration selector.
class _ModeSelectorView extends StatelessWidget {
  const _ModeSelectorView({
    super.key,
    required this.selectedMode,
    required this.isDark,
    required this.primary,
    required this.onSelected,
    required this.onNext,
  });

  final BreathingMode selectedMode;
  final bool isDark;
  final Color primary;
  final ValueChanged<BreathingMode> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.breathingModePrompt,
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(isDark,
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: [
            for (final mode in BreathingMode.values)
              _ModeCard(
                mode: mode,
                isSelected: mode == selectedMode,
                isDark: isDark,
                primary: primary,
                onTap: () => onSelected(mode),
              ),
          ],
        ),
        const SizedBox(height: 40),
        AstraGoldButton(
            isDark: isDark, label: l10n.onboardingNext, onTap: onNext),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final BreathingMode mode;
  final bool isSelected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = mode.label(l10n);
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 140,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected
                  ? primary.withValues(alpha: 0.22)
                  : (isDark
                      ? const Color(0x33231845)
                      : const Color(0x55FFF8EE)),
              border: Border.all(
                color: isSelected ? primary : primary.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon, size: 28, color: primary),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AstraKit.body(isDark,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Second step: duration pills and the start button.
class _DurationSelectorView extends StatelessWidget {
  const _DurationSelectorView({
    super.key,
    required this.selectedMinutes,
    required this.options,
    required this.isDark,
    required this.primary,
    required this.onSelected,
    required this.onStart,
  });

  final int selectedMinutes;
  final List<int> options;
  final bool isDark;
  final Color primary;
  final ValueChanged<int> onSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BreathingOrbPreview(primary: primary),
        const SizedBox(height: 36),
        Text(
          l10n.breathingDurationPrompt,
          style: AstraKit.mutedText(isDark,
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final minutes in options)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _DurationPill(
                  label: l10n.breathingDurationOption(minutes),
                  isSelected: minutes == selectedMinutes,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => onSelected(minutes),
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
        AstraGoldButton(
            isDark: isDark,
            label: l10n.breathingStartButton,
            onTap: onStart,
            expand: false),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(999),
              color: isSelected
                  ? primary.withValues(alpha: 0.22)
                  : (isDark
                      ? const Color(0x33231845)
                      : const Color(0x55FFF8EE)),
              border: Border.all(
                color: isSelected ? primary : primary.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: AstraKit.body(isDark,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined pill used for the "Stop" action during an active session —
/// quieter than the gold CTA since ending early isn't the primary path.
class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton(
      {required this.label,
      required this.isDark,
      required this.primary,
      required this.onTap});

  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primary.withValues(alpha: 0.45)),
          ),
          child: Text(label,
              style: AstraKit.body(isDark,
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// Static, resting-state orb shown behind the duration selector, before a
/// session starts — same look as the animated orb at its mid-point.
class _BreathingOrbPreview extends StatelessWidget {
  const _BreathingOrbPreview({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return _BreathingOrb(scale: 0.8, primary: primary);
  }
}

/// Active-session view: the animated orb, the current phase label, the
/// remaining-time countdown, and the stop button. The orb's timing and the
/// set of phases it cycles through are entirely driven by [pattern].
class _RunningView extends StatefulWidget {
  const _RunningView({
    super.key,
    required this.breathController,
    required this.pattern,
    required this.remainingSeconds,
    required this.isDark,
    required this.primary,
    required this.onStop,
  });

  final AnimationController breathController;
  final BreathingPattern pattern;
  final int remainingSeconds;
  final bool isDark;
  final Color primary;
  final VoidCallback onStop;

  @override
  State<_RunningView> createState() => _RunningViewState();
}

class _RunningViewState extends State<_RunningView> {
  static const _minScale = 0.6;
  static const _maxScale = 1.0;

  double _scaleFor(double t) {
    final pattern = widget.pattern;
    final totalMs = pattern.total.inMilliseconds;
    if (totalMs == 0) return _maxScale;
    final elapsedMs = t * totalMs;
    final inhaleEnd = pattern.inhale.inMilliseconds;
    final holdHighEnd = inhaleEnd + pattern.holdAfterInhale.inMilliseconds;
    final exhaleEnd = holdHighEnd + pattern.exhale.inMilliseconds;

    if (elapsedMs < inhaleEnd) {
      final progress = inhaleEnd == 0 ? 1.0 : elapsedMs / inhaleEnd;
      return _minScale +
          (_maxScale - _minScale) * Curves.easeInOut.transform(progress);
    }
    if (elapsedMs < holdHighEnd) {
      return _maxScale;
    }
    if (elapsedMs < exhaleEnd) {
      final span = exhaleEnd - holdHighEnd;
      final progress = span == 0 ? 1.0 : (elapsedMs - holdHighEnd) / span;
      return _maxScale -
          (_maxScale - _minScale) * Curves.easeInOut.transform(progress);
    }
    return _minScale;
  }

  String _phaseLabel(AppLocalizations l10n, BreathingPhaseKind phase) {
    switch (phase) {
      case BreathingPhaseKind.inhale:
        return l10n.breathingPhaseIn;
      case BreathingPhaseKind.holdAfterInhale:
      case BreathingPhaseKind.holdAfterExhale:
        return l10n.breathingPhaseHold;
      case BreathingPhaseKind.exhale:
        return l10n.breathingPhaseOut;
    }
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: widget.breathController,
          builder: (context, _) {
            final t = widget.breathController.value;
            final phase = widget.pattern.phaseAt(t);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BreathingOrb(scale: _scaleFor(t), primary: widget.primary),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _phaseLabel(l10n, phase),
                    key: ValueKey(phase),
                    style: AstraKit.heading1(widget.isDark, fontSize: 22),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          _formatCountdown(widget.remainingSeconds),
          style: AstraKit.mutedText(widget.isDark,
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 40),
        _OutlinePillButton(
          label: l10n.breathingStopButton,
          isDark: widget.isDark,
          primary: widget.primary,
          onTap: widget.onStop,
        ),
      ],
    );
  }
}

/// Gentle fade-in completion message shown once the chosen duration is up.
class _CompletedView extends StatelessWidget {
  const _CompletedView(
      {super.key,
      required this.isDark,
      required this.primary,
      required this.onContinue});

  final bool isDark;
  final Color primary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BreathingOrb(scale: 0.85, primary: primary),
        const SizedBox(height: 32),
        Text(
          l10n.breathingCompletionMessage,
          textAlign: TextAlign.center,
          style: AstraKit.heading1(isDark, fontSize: 22),
        ),
        const SizedBox(height: 40),
        AstraGoldButton(
          isDark: isDark,
          label: l10n.breathingCompletionContinue,
          onTap: onContinue,
          expand: false,
        ),
      ],
    );
  }
}

/// The soft glowing orb itself — a gold radial gradient with a wide,
/// blurred glow, scaled by [scale] to read as expanding/contracting breath.
/// Built from layered shadows + an off-center highlight/shading pass so it
/// reads as a lit sphere rather than a flat tinted circle.
class _BreathingOrb extends StatelessWidget {
  const _BreathingOrb({required this.scale, required this.primary});

  final double scale;
  final Color primary;
  static const _size = 200.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size * 1.5,
      height: _size * 1.5,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Wide, soft outer bloom.
              Container(
                width: _size * 1.35,
                height: _size * 1.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: primary.withValues(alpha: 0.5),
                        blurRadius: 90,
                        spreadRadius: 6),
                  ],
                ),
              ),
              // The sphere itself: white core fading through primary to a
              // darker shade at the rim, lit from the upper-left.
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.45),
                    radius: 1.0,
                    colors: [
                      Colors.white,
                      Color.lerp(Colors.white, primary, 0.55)!,
                      primary,
                      Color.lerp(primary, Colors.black, 0.4)!,
                    ],
                    stops: const [0.0, 0.28, 0.68, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withValues(alpha: 0.7),
                        blurRadius: 34,
                        spreadRadius: 0),
                  ],
                ),
              ),
              // Tight specular highlight — the "glassy" glint that sells the
              // 3D read.
              Positioned(
                top: _size * 0.16,
                left: _size * 0.20,
                child: Container(
                  width: _size * 0.26,
                  height: _size * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Faint rim shading at the lower-right to ground the sphere.
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(0.55, 0.6),
                    radius: 0.75,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
