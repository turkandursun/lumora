/// Lightweight, on-device text analysis of journal entries — entry/word
/// counts and the most-used meaningful words. No AI, nothing leaves the
/// device.
class JournalTextStats {
  const JournalTextStats({
    required this.entryCount,
    required this.totalWords,
    required this.avgWords,
    required this.topWords,
  });

  final int entryCount;
  final int totalWords;
  final double avgWords;

  /// Most frequent words, most-common first: (word, count).
  final List<(String, int)> topWords;

  bool get isEmpty => entryCount == 0;
}

/// Common Turkish + English filler words to ignore when ranking words.
const Set<String> _stopWords = {
  // Turkish
  'bir', 've', 'bu', 'şu', 'çok', 'daha', 'ama', 'için', 'gibi', 'ile',
  'ben', 'sen', 'biz', 'siz', 'onlar', 'ise', 'ki', 'de', 'da', 'mi',
  'mı', 'mu', 'mü', 'ne', 'her', 'hep', 'çünkü', 'kadar', 'sonra', 'önce',
  'şey', 'oldu', 'olarak', 'diye', 'yok', 'var', 'böyle', 'şöyle',
  'kendi', 'bana', 'beni', 'benim', 'sana', 'seni', 'ona', 'onu', 'bende',
  // English
  'the', 'and', 'that', 'have', 'for', 'not', 'with', 'you', 'this', 'but',
  'his', 'she', 'him', 'they', 'was', 'are', 'were', 'has', 'had',
  'from', 'about', 'just', 'like', 'what', 'when', 'been', 'them', 'then',
  'there', 'their', 'would', 'could', 'because', 'really', 'very', 'some',
};

final _tokenizer = RegExp(r'[^a-zçğıöşü0-9]+');

JournalTextStats computeJournalTextStats(List<String> contents) {
  var totalWords = 0;
  final counts = <String, int>{};

  for (final raw in contents) {
    final words = raw
        .toLowerCase()
        .split(_tokenizer)
        .where((w) => w.isNotEmpty)
        .toList();
    totalWords += words.length;
    for (final w in words) {
      if (w.length < 3) continue;
      if (_stopWords.contains(w)) continue;
      if (int.tryParse(w) != null) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topWords = sorted.take(12).map((e) => (e.key, e.value)).toList();

  final entryCount = contents.length;
  return JournalTextStats(
    entryCount: entryCount,
    totalWords: totalWords,
    avgWords: entryCount == 0 ? 0 : totalWords / entryCount,
    topWords: topWords,
  );
}
