enum JournalTone { positive, neutral, mixed, lowMood }

enum JournalWellnessSuggestion { breathing, meditation, calm }

/// Typed, defensive representation of the `journal-tone` Edge Function
/// response. This is intentionally independent from AppMood: an AI reading of
/// text must never overwrite the user's manually selected mood.
class JournalToneAnalysis {
  const JournalToneAnalysis({
    required this.tone,
    required this.confidence,
    required this.message,
    required this.showWellnessSuggestions,
    required this.suggestions,
  });

  static const double wellnessConfidenceThreshold = 0.80;
  static const int maximumMessageLength = 280;

  final JournalTone tone;
  final double confidence;
  final String message;
  final bool showWellnessSuggestions;
  final List<JournalWellnessSuggestion> suggestions;

  factory JournalToneAnalysis.fromJson(Map<String, dynamic> json) {
    final tone = _parseTone(json['tone']);
    final confidence = _parseConfidence(json['confidence']);
    final message = _parseMessage(json['message']);
    final requestedWellness = json['show_wellness_suggestions'];
    if (requestedWellness is! bool) {
      throw const FormatException(
        'Invalid journal tone wellness visibility value.',
      );
    }

    final suggestions = _parseSuggestions(json['suggestions']);
    final wellnessEligible = tone == JournalTone.lowMood &&
        confidence >= wellnessConfidenceThreshold &&
        requestedWellness &&
        suggestions.isNotEmpty;

    return JournalToneAnalysis(
      tone: tone,
      confidence: confidence,
      message: message,
      showWellnessSuggestions: wellnessEligible,
      suggestions: List.unmodifiable(
        wellnessEligible ? suggestions : const <JournalWellnessSuggestion>[],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'tone': _toneWireValue(tone),
        'confidence': confidence,
        'message': message,
        'show_wellness_suggestions': showWellnessSuggestions,
        'suggestions': suggestions.map(_suggestionWireValue).toList(),
      };

  static JournalTone _parseTone(Object? value) => switch (value) {
        'positive' => JournalTone.positive,
        'neutral' => JournalTone.neutral,
        'mixed' => JournalTone.mixed,
        'low_mood' => JournalTone.lowMood,
        _ => throw const FormatException('Unknown journal tone.'),
      };

  static double _parseConfidence(Object? value) {
    if (value is! num) {
      throw const FormatException('Invalid journal tone confidence.');
    }
    final confidence = value.toDouble();
    if (!confidence.isFinite || confidence < 0 || confidence > 1) {
      throw const FormatException('Journal tone confidence is out of range.');
    }
    return confidence;
  }

  static String _parseMessage(Object? value) {
    if (value is! String) {
      throw const FormatException('Invalid journal tone message.');
    }
    final message = value.trim();
    if (message.isEmpty || message.runes.length > maximumMessageLength) {
      throw const FormatException(
          'Journal tone message has an invalid length.');
    }
    return message;
  }

  static List<JournalWellnessSuggestion> _parseSuggestions(Object? value) {
    if (value is! List) {
      throw const FormatException('Invalid journal wellness suggestions.');
    }
    final parsed = <JournalWellnessSuggestion>[];
    for (final item in value) {
      final suggestion = switch (item) {
        'breathing' => JournalWellnessSuggestion.breathing,
        'meditation' => JournalWellnessSuggestion.meditation,
        'calm' => JournalWellnessSuggestion.calm,
        _ => throw const FormatException(
            'Unknown journal wellness suggestion.',
          ),
      };
      if (!parsed.contains(suggestion)) parsed.add(suggestion);
    }
    return parsed;
  }

  static String _toneWireValue(JournalTone tone) => switch (tone) {
        JournalTone.positive => 'positive',
        JournalTone.neutral => 'neutral',
        JournalTone.mixed => 'mixed',
        JournalTone.lowMood => 'low_mood',
      };

  static String _suggestionWireValue(JournalWellnessSuggestion suggestion) =>
      switch (suggestion) {
        JournalWellnessSuggestion.breathing => 'breathing',
        JournalWellnessSuggestion.meditation => 'meditation',
        JournalWellnessSuggestion.calm => 'calm',
      };
}
