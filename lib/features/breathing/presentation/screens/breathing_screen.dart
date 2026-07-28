import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/sakura_home_palette.dart';
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
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const _durationOptionsMinutes = [2, 4, 6];

  late final AnimationController _breathController;

  Timer? _countdownTimer;
  BreathingMode _selectedMode = BreathingMode.calmAnger;
  int _selectedMinutes = _durationOptionsMinutes[1];
  int _remainingSeconds = 0;
  _SessionStage _stage = _SessionStage.selectingMode;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
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
      _stage = _SessionStage.running;
      _remainingSeconds = _selectedMinutes * 60;
    });
    _breathController
      ..duration = _selectedMode.pattern.total
      ..reset()
      ..repeat();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _finish();
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

  void _finish() {
    _countdownTimer?.cancel();
    _breathController.stop();
    setState(() => _stage = _SessionStage.completed);
  }

  void _backToModeSelector() {
    setState(() => _stage = _SessionStage.selectingMode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Text(
                    l10n.breathingTitle,
                    style: AppTheme.displayFont(
                        fontSize: 24, color: SakuraHomePalette.textDeep),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: switch (_stage) {
                        _SessionStage.selectingMode => _ModeSelectorView(
                            key: const ValueKey(_SessionStage.selectingMode),
                            selectedMode: _selectedMode,
                            onSelected: _selectMode,
                            onNext: _confirmMode,
                          ),
                        _SessionStage.selectingDuration => _DurationSelectorView(
                            key: const ValueKey(_SessionStage.selectingDuration),
                            selectedMinutes: _selectedMinutes,
                            options: _durationOptionsMinutes,
                            onSelected: (minutes) =>
                                setState(() => _selectedMinutes = minutes),
                            onStart: _start,
                          ),
                        _SessionStage.running => _RunningView(
                            key: const ValueKey(_SessionStage.running),
                            breathController: _breathController,
                            pattern: _selectedMode.pattern,
                            remainingSeconds: _remainingSeconds,
                            onStop: _stop,
                          ),
                        _SessionStage.completed => _CompletedView(
                            key: const ValueKey(_SessionStage.completed),
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
    required this.onSelected,
    required this.onNext,
  });

  final BreathingMode selectedMode;
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
          style: AppTheme.bodyFont(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: SakuraHomePalette.textMuted,
          ),
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
                onTap: () => onSelected(mode),
              ),
          ],
        ),
        const SizedBox(height: 40),
        _GradientPillButton(label: l10n.onboardingNext, onTap: onNext),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.isSelected, required this.onTap});

  final BreathingMode mode;
  final bool isSelected;
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
                  ? LumoraPalette.primaryPurple.withValues(alpha: 0.92)
                  : SakuraHomePalette.lavender,
              border: Border.all(
                color: isSelected
                    ? LumoraPalette.lightPurple
                    : SakuraHomePalette.branchMauve.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon,
                    size: 28,
                    color: isSelected
                        ? Colors.white
                        : SakuraHomePalette.blossomPink),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyFont(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : SakuraHomePalette.textDeep,
                  ),
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
    required this.onSelected,
    required this.onStart,
  });

  final int selectedMinutes;
  final List<int> options;
  final ValueChanged<int> onSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BreathingOrbPreview(),
        const SizedBox(height: 36),
        Text(
          l10n.breathingDurationPrompt,
          style: AppTheme.bodyFont(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SakuraHomePalette.textMuted,
          ),
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
                  onTap: () => onSelected(minutes),
                ),
              ),
          ],
        ),
        const SizedBox(height: 40),
        _GradientPillButton(label: l10n.breathingStartButton, onTap: onStart),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
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
                  ? LumoraPalette.primaryPurple.withValues(alpha: 0.92)
                  : SakuraHomePalette.lavender,
              border: Border.all(
                color: isSelected
                    ? LumoraPalette.lightPurple
                    : SakuraHomePalette.branchMauve.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: AppTheme.bodyFont(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : SakuraHomePalette.textDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width gradient CTA pill, matching the login/sign-up button style.
class _GradientPillButton extends StatelessWidget {
  const _GradientPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: LumoraPalette.ctaGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: LumoraPalette.primaryPurple.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: LumoraPalette.bodyStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined pill used for the "Stop" action during an active session —
/// quieter than the gradient CTA since ending early isn't the primary path.
class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({required this.label, required this.onTap});

  final String label;
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
            border: Border.all(
                color: SakuraHomePalette.branchMauve.withValues(alpha: 0.45)),
          ),
          child: Text(
            label,
            style: AppTheme.bodyFont(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textDeep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Static, resting-state orb shown behind the duration selector, before a
/// session starts — same look as the animated orb at its mid-point.
class _BreathingOrbPreview extends StatelessWidget {
  const _BreathingOrbPreview();

  @override
  Widget build(BuildContext context) {
    return const _BreathingOrb(scale: 0.8);
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
    required this.onStop,
  });

  final AnimationController breathController;
  final BreathingPattern pattern;
  final int remainingSeconds;
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
      return _minScale + (_maxScale - _minScale) * Curves.easeInOut.transform(progress);
    }
    if (elapsedMs < holdHighEnd) {
      return _maxScale;
    }
    if (elapsedMs < exhaleEnd) {
      final span = exhaleEnd - holdHighEnd;
      final progress = span == 0 ? 1.0 : (elapsedMs - holdHighEnd) / span;
      return _maxScale - (_maxScale - _minScale) * Curves.easeInOut.transform(progress);
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
                _BreathingOrb(scale: _scaleFor(t)),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _phaseLabel(l10n, phase),
                    key: ValueKey(phase),
                    style: AppTheme.displayFont(
                      fontSize: 22,
                      color: SakuraHomePalette.textDeep,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          _formatCountdown(widget.remainingSeconds),
          style: AppTheme.bodyFont(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: SakuraHomePalette.textMuted,
          ),
        ),
        const SizedBox(height: 40),
        _OutlinePillButton(label: l10n.breathingStopButton, onTap: widget.onStop),
      ],
    );
  }
}

/// Gentle fade-in completion message shown once the chosen duration is up.
class _CompletedView extends StatelessWidget {
  const _CompletedView({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BreathingOrb(scale: 0.85),
        const SizedBox(height: 32),
        Text(
          l10n.breathingCompletionMessage,
          textAlign: TextAlign.center,
          style: AppTheme.displayFont(fontSize: 22, color: SakuraHomePalette.textDeep),
        ),
        const SizedBox(height: 40),
        _OutlinePillButton(
          label: l10n.breathingCompletionContinue,
          onTap: onContinue,
        ),
      ],
    );
  }
}

/// The soft glowing orb itself — a purple radial gradient with a wide,
/// blurred glow, scaled by [scale] to read as expanding/contracting breath.
class _BreathingOrb extends StatelessWidget {
  const _BreathingOrb({required this.scale});

  final double scale;
  static const _size = 200.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: [
                  Color.lerp(
                    LumoraPalette.warmCream,
                    LumoraPalette.primaryPurple,
                    0.35,
                  )!
                      .withValues(alpha: 0.95),
                  LumoraPalette.primaryPurple.withValues(alpha: 0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: LumoraPalette.primaryPurple.withValues(alpha: 0.55),
                  blurRadius: 60,
                  spreadRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
