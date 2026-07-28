/// The four possible phases of one breathing cycle, in the order they
/// occur. A phase with [BreathingPattern] duration [Duration.zero] simply
/// never occupies any time in the cycle, so it's naturally skipped.
enum BreathingPhaseKind { inhale, holdAfterInhale, exhale, holdAfterExhale }

/// Timing for one guided-breathing technique: how long to inhale, an
/// optional hold at the top of the breath, how long to exhale, and an
/// optional hold at the bottom — looped continuously. Holds default to
/// zero (skipped) so patterns that don't use a particular phase (e.g.
/// coherent breathing, which has no holds at all) don't need to mention it.
class BreathingPattern {
  const BreathingPattern({
    required this.inhale,
    this.holdAfterInhale = Duration.zero,
    required this.exhale,
    this.holdAfterExhale = Duration.zero,
  });

  final Duration inhale;
  final Duration holdAfterInhale;
  final Duration exhale;
  final Duration holdAfterExhale;

  /// Full length of one inhale-hold-exhale-hold cycle.
  Duration get total =>
      inhale + holdAfterInhale + exhale + holdAfterExhale;

  /// Which phase of the cycle [progress] (0.0-1.0 through [total]) falls
  /// into.
  BreathingPhaseKind phaseAt(double progress) {
    final totalMs = total.inMilliseconds;
    final elapsedMs = progress * totalMs;
    final inhaleEnd = inhale.inMilliseconds;
    final holdHighEnd = inhaleEnd + holdAfterInhale.inMilliseconds;
    final exhaleEnd = holdHighEnd + exhale.inMilliseconds;

    if (elapsedMs < inhaleEnd) return BreathingPhaseKind.inhale;
    if (elapsedMs < holdHighEnd) return BreathingPhaseKind.holdAfterInhale;
    if (elapsedMs < exhaleEnd) return BreathingPhaseKind.exhale;
    return BreathingPhaseKind.holdAfterExhale;
  }
}

/// A guided-breathing technique mapped to a specific emotional need, each
/// backed by a real, established breathing pattern.
enum BreathingMode { calmAnger, easeAnxiety, relaxUnwind, boostEnergy }

extension BreathingModePattern on BreathingMode {
  /// The breathing pattern this mode guides the user through.
  BreathingPattern get pattern {
    switch (this) {
      case BreathingMode.calmAnger:
        // Box breathing: an even, structured rhythm that down-regulates a
        // heightened nervous system.
        return const BreathingPattern(
          inhale: Duration(seconds: 4),
          holdAfterInhale: Duration(seconds: 4),
          exhale: Duration(seconds: 4),
          holdAfterExhale: Duration(seconds: 4),
        );
      case BreathingMode.easeAnxiety:
        // 4-7-8 technique: an extended exhale relative to inhale is
        // calming; no pause between cycles.
        return const BreathingPattern(
          inhale: Duration(seconds: 4),
          holdAfterInhale: Duration(seconds: 7),
          exhale: Duration(seconds: 8),
        );
      case BreathingMode.relaxUnwind:
        // Coherent breathing: a gentle, steady rhythm with no holds.
        return const BreathingPattern(
          inhale: Duration(seconds: 5),
          exhale: Duration(seconds: 5),
        );
      case BreathingMode.boostEnergy:
        // Energizing breath: a shorter, quicker exhale relative to inhale
        // at a slightly brisker pace — invigorating but still gentle.
        return const BreathingPattern(
          inhale: Duration(seconds: 4),
          exhale: Duration(seconds: 2),
        );
    }
  }
}
