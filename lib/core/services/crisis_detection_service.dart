/// Local, offline, instant keyword scan for direct expressions of
/// suicidal intent or self-harm — the client-side safety net behind the
/// crisis support resource sheet. Runs on every journal entry save and
/// every Luma chat message, independent of network/AI availability.
///
/// Deliberately narrow: only clear, direct expressions of intent to end
/// one's life or self-harm are matched, not general sadness/difficult
/// emotions, to avoid over-triggering on normal hard days.
class CrisisDetectionService {
  CrisisDetectionService._();

  static bool containsCrisisLanguage(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return false;
    return _phrases.any(normalized.contains);
  }

  /// Turkish-aware lowercasing (Dart's default `toLowerCase` maps capital
  /// `İ` to a dotted-i with a combining mark rather than plain `i`) plus
  /// whitespace collapsing, so phrase matching stays reliable regardless
  /// of how the user capitalizes or spaces their words.
  static String _normalize(String text) {
    return text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const List<String> _phrases = [
    // --- English ---------------------------------------------------------
    'suicide',
    'suicidal',
    'kill myself',
    'killing myself',
    'want to die',
    'wanna die',
    'wish i was dead',
    'wish i were dead',
    'want to end my life',
    'end my life',
    'ending my life',
    'end it all',
    'better off dead',
    'no reason to live',
    "don't want to live",
    'do not want to live',
    'take my own life',
    'taking my own life',
    'not worth living',
    "isn't worth living",
    'is not worth living',
    'hurt myself',
    'hurting myself',
    'harm myself',
    'harming myself',
    'cut myself',
    'cutting myself',
    'self-harm',
    'self harm',
    // --- Turkish -----------------------------------------------------------
    'intihar',
    'kendimi öldürmek',
    'kendimi öldüreceğim',
    'kendimi öldüreyim',
    'kendimi öldürsem',
    'canıma kıymak',
    'canıma kıyacağım',
    'canıma kıyayım',
    'canıma kıysam',
    'yaşamak istemiyorum',
    'yaşamak istemiyorum artık',
    'artık yaşamak istemiyorum',
    'ölmek istiyorum',
    'ölesim geliyor',
    'keşke ölseydim',
    'kendime zarar',
    'kendimi kesmek',
    'kendimi kesiyorum',
    'hayatıma son vermek',
    'hayatıma son vereceğim',
    'hayatıma son vereyim',
  ];
}
