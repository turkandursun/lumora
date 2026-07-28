/// Canonical symbol keys the local detector recognizes. Presentation code
/// (labels, gentle associations) is keyed off these — see
/// `dreamSymbolCopy` in `dream_journal_screen.dart`.
class DreamSymbolKeys {
  DreamSymbolKeys._();

  static const water = 'water';
  static const flying = 'flying';
  static const falling = 'falling';
  static const house = 'house';
  static const teeth = 'teeth';
  static const running = 'running';
  static const lost = 'lost';
  static const snake = 'snake';
  static const death = 'death';
  static const baby = 'baby';
  static const exam = 'exam';
  static const ocean = 'ocean';
  static const car = 'car';
  static const stairs = 'stairs';
  static const mirror = 'mirror';
  static const door = 'door';
  static const light = 'light';
}

/// Turkish/English keyword forms searched for in dream text, keyed by
/// [DreamSymbolKeys]. Deliberately locale-independent — a dream can be
/// written in either language regardless of the app's current locale.
const Map<String, List<String>> dreamSymbolKeywords = {
  DreamSymbolKeys.water: ['su', 'water'],
  DreamSymbolKeys.flying: ['uçmak', 'uçtu', 'uçuyor', 'uçarken', 'uçtuğ', 'flying', 'fly'],
  DreamSymbolKeys.falling: ['düşmek', 'düştü', 'düşüyor', 'düştüğ', 'falling', 'fell'],
  DreamSymbolKeys.house: ['ev', 'house', 'home'],
  DreamSymbolKeys.teeth: ['diş', 'dis', 'teeth', 'tooth'],
  DreamSymbolKeys.running: ['koşmak', 'koştu', 'koşuyor', 'koştuğ', 'running', 'ran'],
  DreamSymbolKeys.lost: ['kaybolmak', 'kayboldu', 'kayboldum', 'kayıp', 'lost'],
  DreamSymbolKeys.snake: ['yılan', 'yilan', 'snake'],
  DreamSymbolKeys.death: ['ölüm', 'oldu', 'öldü', 'öldüm', 'death', 'died', 'dying'],
  DreamSymbolKeys.baby: ['bebek', 'baby'],
  DreamSymbolKeys.exam: ['sınav', 'sinav', 'exam', 'test'],
  DreamSymbolKeys.ocean: ['deniz', 'ocean', 'sea'],
  DreamSymbolKeys.car: ['araba', 'car'],
  DreamSymbolKeys.stairs: ['merdiven', 'stairs', 'staircase'],
  DreamSymbolKeys.mirror: ['ayna', 'mirror'],
  DreamSymbolKeys.door: ['kapı', 'kapi', 'door'],
  DreamSymbolKeys.light: ['ışık', 'isik', 'light'],
};

/// How many extra trailing characters a word may have past a keyword and
/// still count as a match — covers short Turkish suffixes (e.g. "evde"
/// past "ev") without letting a short keyword match deep inside an
/// unrelated longer word (e.g. "ev" inside "everywhere").
const _maxSuffixSlack = 3;

/// Scans [text] for any of [dreamSymbolKeywords]' keyword forms and returns
/// the set of canonical symbol keys found. Matching is a simple
/// case-insensitive word-prefix check bounded by [_maxSuffixSlack] — gentle
/// and local, not meant to be exhaustive.
Set<String> detectDreamSymbols(String text) {
  final words = text
      .toLowerCase()
      .split(RegExp(r'[^\p{L}]+', unicode: true))
      .where((word) => word.isNotEmpty);

  final matched = <String>{};
  for (final word in words) {
    for (final entry in dreamSymbolKeywords.entries) {
      if (matched.contains(entry.key)) continue;
      final isMatch = entry.value.any(
        (keyword) => word.startsWith(keyword) && word.length - keyword.length <= _maxSuffixSlack,
      );
      if (isMatch) matched.add(entry.key);
    }
  }
  return matched;
}
