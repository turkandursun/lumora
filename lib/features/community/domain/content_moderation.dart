/// Result category of a moderation check on user-written community text.
enum ModerationIssue {
  /// Clean — safe to publish.
  none,

  /// Empty / whitespace only.
  empty,

  /// Contains personal contact info (phone, e-mail, link, social handle).
  contact,

  /// Contains hurtful / offensive language.
  harmful,
}

/// Lightweight, on-device content filter for the Safe Space Community.
///
/// It blocks anything that looks like a phone number (with any separators,
/// including "0551*551*5151"), an e-mail, a link or a social handle, and a
/// base list of hurtful words in Turkish and English — including obfuscated
/// forms like "s*lak", "sal4k" or "s.a.l.a.k". It is a first line of defence,
/// not a replacement for the report button and server-side flagging.
class ContentModeration {
  const ContentModeration._();

  static final RegExp _email =
      RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');

  static final RegExp _url = RegExp(
      r'(https?:\/\/|www\.)\S+|\b[A-Za-z0-9\-]+\.(com|net|org|io|co|me|xyz|info|ru|tr|de|es|fr|app|link)\b',
      caseSensitive: false);

  // A social handle like @username (but not an e-mail, handled above).
  static final RegExp _handle = RegExp(r'(^|\s)@[A-Za-z0-9._]{3,}');

  // Words/phrases used to move a chat off-platform / exchange contacts.
  static final List<String> _contactWords = [
    'whatsapp', 'whatsap', 'telegram', 'instagram', 'snapchat',
    'discord', 'numaram', 'telefon numaram', 'beni ara', 'dm at',
    'ozelden yaz',
  ];

  // Offensive/hurtful single words (Turkish + English) + common inflections.
  // Matched with a fuzzy, obfuscation-aware regex (see [_buildFuzzy]).
  static final List<String> _harmfulWords = [
    // Turkish
    'aptal', 'aptalsin', 'salak', 'salaksin', 'gerizekali', 'ahmak',
    'orospu', 'orospusun', 'serefsiz', 'siktir', 'amk', 'amcik', 'yavsak',
    'pezevenk', 'kahpe', 'ibne', 'gavat', 'gebertirim', 'geber',
    'oldururum', 'oldurecegim',
    'sikeyim', 'sikik', 'siktim', 'sikim', 'siktir', 'yarrak', 'yarram',
    'kaltak', 'surtuk', 'pust', 'godos', 'dallama', 'orospucocugu',
    // "göt" is only filtered in its unambiguous vulgar compounds — bare "göt"
    // normalizes to "got", which collides with English "got" and Turkish
    // "götür-" (to carry), so filtering it alone would flag innocent words.
    'gotveren', 'gotos', 'gotlek', 'gotoglani',
    // English
    'idiot', 'stupid', 'moron', 'retard', 'bitch', 'bastard', 'asshole',
    'arsehole', 'fuck', 'fucking', 'fucker', 'motherfucker', 'shit', 'slut',
    'whore', 'cunt', 'faggot', 'kys', 'pussy', 'nigger', 'nigga', 'douche',
    'douchebag', 'wanker', 'twat', 'bollocks', 'bugger', 'dumbass', 'jackass',
  ];

  // Multi-word hurtful phrases, matched as plain substrings on normalized text.
  static final List<String> _harmfulPhrases = [
    'siktir git', 'geri zekali', 'kill yourself',
    'orospu cocugu', 'anani sikeyim', 'gotunu sikeyim', 'anani avradini',
  ];

  // Common letter → look-alike substitutions (leet speak), pre-formatted for
  // use inside a regex character class.
  static const Map<String, String> _leet = {
    'a': '4@',
    'e': '3',
    'i': '1!',
    'o': '0',
    's': r'5\$',
    't': '7',
    'g': '9',
    'b': '8',
    'l': '1',
  };

  // Symbols people slip in to mask a letter (e.g. the "*" in "s*lak").
  static const String _maskChars = r'*._+#%&\-';

  // A fuzzy matcher per harmful word: each letter may be itself, a leet
  // look-alike or a single mask symbol, with optional separators between —
  // so "salak", "s*lak", "sal4k" and "s.a.l.a.k" all match. A leading
  // word-boundary keeps it from firing inside words like "oxymoron", while no
  // trailing boundary lets it catch Turkish suffixes ("salaklığım").
  static final List<RegExp> _harmfulRegexes =
      _harmfulWords.map(_buildFuzzy).toList();

  static RegExp _buildFuzzy(String word) {
    const separator = r'[\s\W_]*';
    final parts = <String>[];
    for (final ch in word.split('')) {
      final buf = StringBuffer('[')
        ..write(ch)
        ..write(_leet[ch] ?? '')
        ..write(_maskChars)
        ..write(']');
      parts.add(buf.toString());
    }
    return RegExp(r'(?<![a-z0-9])' + parts.join(separator),
        caseSensitive: false);
  }

  /// Flags anything that looks like a phone number: a run of 7+ digits joined
  /// only by separators (spaces, dashes, dots, asterisks, slashes, etc.), or a
  /// bare 7+ digit blob.
  static bool _looksLikePhone(String text) {
    final phoneish = RegExp(r'(\+?\d[\d\s().\-*\/_,]{3,}\d)');
    for (final m in phoneish.allMatches(text)) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 7) return true;
    }
    return RegExp(r'\d{7,}').hasMatch(text);
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ç', 'c')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u');

  /// Checks [raw] and returns the first issue found (or [ModerationIssue.none]).
  static ModerationIssue check(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return ModerationIssue.empty;

    if (_email.hasMatch(text) ||
        _url.hasMatch(text) ||
        _handle.hasMatch(text) ||
        _looksLikePhone(text)) {
      return ModerationIssue.contact;
    }

    final norm = _normalize(text);
    final tokens =
        norm.split(RegExp(r'[^a-z0-9]+')).where((t) => t.isNotEmpty).toSet();

    bool hasContact(String word) {
      final w = _normalize(word);
      return w.contains(' ') ? norm.contains(w) : tokens.contains(w);
    }

    for (final w in _contactWords) {
      if (hasContact(w)) return ModerationIssue.contact;
    }
    for (final p in _harmfulPhrases) {
      if (norm.contains(p)) return ModerationIssue.harmful;
    }
    for (final re in _harmfulRegexes) {
      if (re.hasMatch(norm)) return ModerationIssue.harmful;
    }

    return ModerationIssue.none;
  }
}
