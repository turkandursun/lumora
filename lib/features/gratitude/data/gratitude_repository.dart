import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One day's gratitude entry: a date and up to a few things the user was
/// grateful for.
class GratitudeEntry {
  const GratitudeEntry({required this.date, required this.items, this.mood});

  final DateTime date;
  final List<String> items;

  /// Optional emoji/mood the user tagged this day's gratitude with.
  final String? mood;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'items': items,
        if (mood != null) 'mood': mood,
      };

  factory GratitudeEntry.fromJson(Map<String, dynamic> json) => GratitudeEntry(
        date: DateTime.parse(json['date'] as String),
        items: (json['items'] as List).map((e) => e.toString()).toList(),
        mood: json['mood'] as String?,
      );
}

const _gratitudeKey = 'gratitude_v1';

/// On-device store for gratitude entries (one per day), kept as a list of
/// JSON strings in SharedPreferences.
class GratitudeRepository {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<GratitudeEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_gratitudeKey) ?? const [];
    final entries = <GratitudeEntry>[];
    for (final item in raw) {
      try {
        entries.add(
          GratitudeEntry.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (_) {
        // Skip any malformed record rather than losing the whole list.
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> save(List<GratitudeEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_gratitudeKey, raw);
  }
}
