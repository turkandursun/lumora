import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/journal/domain/journal_tone_analysis.dart';

void main() {
  test('parses every supported tone wire value', () {
    const cases = {
      'positive': JournalTone.positive,
      'neutral': JournalTone.neutral,
      'mixed': JournalTone.mixed,
      'low_mood': JournalTone.lowMood,
    };

    for (final entry in cases.entries) {
      final result = JournalToneAnalysis.fromJson({
        'tone': entry.key,
        'confidence': 0.75,
        'message': 'A short, safe feedback message.',
        'show_wellness_suggestions': false,
        'suggestions': <String>[],
      });
      expect(result.tone, entry.value);
    }
  });

  test('non-low tone forcibly clears wellness suggestions', () {
    final result = JournalToneAnalysis.fromJson({
      'tone': 'mixed',
      'confidence': 0.99,
      'message': 'There are both difficult and lighter moments in the writing.',
      'show_wellness_suggestions': true,
      'suggestions': ['breathing', 'calm'],
    });

    expect(result.showWellnessSuggestions, isFalse);
    expect(result.suggestions, isEmpty);
  });

  test('low mood below 0.80 forcibly clears wellness suggestions', () {
    final result = JournalToneAnalysis.fromJson({
      'tone': 'low_mood',
      'confidence': 0.79,
      'message': 'There is some heaviness in today’s writing.',
      'show_wellness_suggestions': true,
      'suggestions': ['breathing'],
    });

    expect(result.showWellnessSuggestions, isFalse);
    expect(result.suggestions, isEmpty);
  });

  test('eligible low mood removes duplicate suggestions', () {
    final result = JournalToneAnalysis.fromJson({
      'tone': 'low_mood',
      'confidence': 0.80,
      'message': 'There is sustained tiredness in today’s writing.',
      'show_wellness_suggestions': true,
      'suggestions': ['breathing', 'breathing', 'meditation', 'calm'],
    });

    expect(result.showWellnessSuggestions, isTrue);
    expect(
      result.suggestions,
      [
        JournalWellnessSuggestion.breathing,
        JournalWellnessSuggestion.meditation,
        JournalWellnessSuggestion.calm,
      ],
    );
  });

  test('unknown tone and suggestion values throw controlled parse errors', () {
    expect(
      () => JournalToneAnalysis.fromJson({
        'tone': 'sad',
        'confidence': 0.5,
        'message': 'A short message.',
        'show_wellness_suggestions': false,
        'suggestions': <String>[],
      }),
      throwsFormatException,
    );
    expect(
      () => JournalToneAnalysis.fromJson({
        'tone': 'low_mood',
        'confidence': 0.9,
        'message': 'A short message.',
        'show_wellness_suggestions': true,
        'suggestions': ['therapy'],
      }),
      throwsFormatException,
    );
  });

  test('invalid confidence and message are rejected', () {
    expect(
      () => JournalToneAnalysis.fromJson({
        'tone': 'neutral',
        'confidence': 1.1,
        'message': 'A short message.',
        'show_wellness_suggestions': false,
        'suggestions': <String>[],
      }),
      throwsFormatException,
    );
    expect(
      () => JournalToneAnalysis.fromJson({
        'tone': 'neutral',
        'confidence': 0.5,
        'message': '   ',
        'show_wellness_suggestions': false,
        'suggestions': <String>[],
      }),
      throwsFormatException,
    );
  });
}
