import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/breathing/domain/breathing_pattern.dart';

void main() {
  test('box breathing (calm anger) cycles through all four equal phases', () {
    final pattern = BreathingMode.calmAnger.pattern;
    expect(pattern.total, const Duration(seconds: 16));
    expect(pattern.phaseAt(0.2), BreathingPhaseKind.inhale); // ~3.2s
    expect(pattern.phaseAt(0.3), BreathingPhaseKind.holdAfterInhale); // ~4.8s
    expect(pattern.phaseAt(0.55), BreathingPhaseKind.exhale); // ~8.8s
    expect(pattern.phaseAt(0.85), BreathingPhaseKind.holdAfterExhale); // ~13.6s
  });

  test('4-7-8 (ease anxiety) has an extended exhale and no pause after it', () {
    final pattern = BreathingMode.easeAnxiety.pattern;
    expect(pattern.total, const Duration(seconds: 19));
    expect(pattern.holdAfterExhale, Duration.zero);
    expect(pattern.phaseAt(0.99), BreathingPhaseKind.exhale); // ~18.8s
  });

  test('coherent breathing (relax & unwind) has no holds at all', () {
    final pattern = BreathingMode.relaxUnwind.pattern;
    expect(pattern.total, const Duration(seconds: 10));
    expect(pattern.holdAfterInhale, Duration.zero);
    expect(pattern.holdAfterExhale, Duration.zero);
    expect(pattern.phaseAt(0.4), BreathingPhaseKind.inhale); // 4s
    expect(pattern.phaseAt(0.6), BreathingPhaseKind.exhale); // 6s
  });

  test('energizing breath (boost energy) is brisker with a short exhale', () {
    final pattern = BreathingMode.boostEnergy.pattern;
    expect(pattern.total, const Duration(seconds: 6));
    expect(pattern.inhale, const Duration(seconds: 4));
    expect(pattern.exhale, const Duration(seconds: 2));
    expect(pattern.phaseAt(0.5), BreathingPhaseKind.inhale); // 3s
    expect(pattern.phaseAt(0.9), BreathingPhaseKind.exhale); // 5.4s
  });
}
