import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A letter the user writes to their future self, sealed until [openAt].
class Letter {
  const Letter({
    required this.id,
    required this.createdAt,
    required this.openAt,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime createdAt;
  final DateTime openAt;
  final String title;
  final String body;

  /// Readable once the open date has arrived.
  bool get isUnlocked => !DateTime.now().isBefore(openAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'openAt': openAt.toIso8601String(),
        'title': title,
        'body': body,
      };

  factory Letter.fromJson(Map<String, dynamic> json) => Letter(
        id: json['id'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        openAt: DateTime.parse(json['openAt'] as String),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

const _lettersKey = 'letters_v1';

/// On-device store for future-self letters (list of JSON strings).
class LetterRepository {
  Future<List<Letter>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_lettersKey) ?? const [];
    final letters = <Letter>[];
    for (final item in raw) {
      try {
        letters.add(Letter.fromJson(jsonDecode(item) as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed records.
      }
    }
    letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return letters;
  }

  Future<void> save(List<Letter> letters) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = letters.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_lettersKey, raw);
  }
}
