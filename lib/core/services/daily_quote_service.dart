import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';

/// Generates one fresh, original "quote of the day" via the existing `luma-chat`
/// Edge Function and caches it per calendar day + language, so the daily card
/// can stay endlessly fresh instead of only cycling the bundled famous quotes.
///
/// IMPORTANT — no misattribution: the AI is asked for an ORIGINAL line and it is
/// surfaced signed as "Luma" (the in-app companion), never falsely attributed to
/// a real historical figure. The trustworthy, correctly-attributed classics live
/// in [famousQuotes]; this is an additive, always-optional daily-fresh layer.
///
/// Disabled by default: flip [enabled] to true to switch the daily card over to
/// AI-generated quotes (with the famous rotation as the offline/failure
/// fallback). While disabled, [fetchDailyQuote] always returns null and the card
/// shows the famous quote of the day.
class DailyQuoteService {
  DailyQuoteService({AiService? ai}) : _ai = ai ?? AiService();

  final AiService _ai;

  /// Master switch. false → the daily card uses the famous-quote rotation only.
  /// true → an AI-generated original line is used when online, famous rotation
  /// as fallback.
  static const bool enabled = false;

  static String _dayStamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _cacheKey(String language) =>
      'ai_daily_quote_${language}_${_dayStamp()}';

  /// The AI quote text for today in [language], or null (→ use famous rotation).
  /// One network call per day per language; the rest of the day is served from
  /// the SharedPreferences cache.
  Future<String?> fetchDailyQuote({required String language}) async {
    if (!enabled) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(language);
    final cached = prefs.getString(key);
    if (cached != null && cached.trim().isNotEmpty) return cached;

    try {
      final prompt = language == 'tr'
          ? 'Bugün için tek cümlelik, özgün, sıcak ve motive edici bir ilham '
              'sözü yaz. Kimseye atfetme; tırnak işareti, açıklama, emoji ya da '
              'yazar adı ekleme. Yalnızca cümleyi döndür. En fazla 18 kelime.'
          : 'Write a single original, warm, motivating sentence of inspiration '
              'for today. Do not attribute it to anyone; no quotation marks, no '
              'explanation, no emoji, no author. Return only the sentence. '
              'Maximum 18 words.';
      final reply = await _ai.sendLumaMessage(message: prompt, language: language);
      final cleaned = _clean(reply);
      if (cleaned == null) return null;
      await prefs.setString(key, cleaned);
      return cleaned;
    } catch (error) {
      debugPrint('[DailyQuote] AI daily quote unavailable: ${error.runtimeType}');
      return null;
    }
  }

  /// Keeps only a single clean sentence: first non-empty line, stripped of
  /// wrapping quotes / list bullets, and length-sanity-checked so a stray
  /// conversational reply never lands on the card.
  String? _clean(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    // Strip a leading list marker, then any wrapping quotation marks.
    s = s.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim();
    const wrappers = <String>['"', '“', '”', '‘', '’', "'"];
    while (s.isNotEmpty && wrappers.contains(s[0])) {
      s = s.substring(1).trim();
    }
    while (s.isNotEmpty && wrappers.contains(s[s.length - 1])) {
      s = s.substring(0, s.length - 1).trim();
    }
    if (s.length < 8 || s.length > 180) return null;
    return s;
  }
}
