import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One logged daily activity — what the user did, an optional photo (a local
/// file path), and, if they shared it, the community share id.
class Activity {
  const Activity({
    required this.id,
    required this.createdAt,
    required this.text,
    this.photoPath,
    this.sharedId,
  });

  final int id;
  final DateTime createdAt;
  final String text;
  final String? photoPath;
  final String? sharedId;

  bool get isShared => sharedId != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'text': text,
        'photoPath': photoPath,
        'sharedId': sharedId,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        text: json['text'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
        sharedId: json['sharedId'] as String?,
      );
}

const _activitiesKey = 'activities_v1';

/// On-device store for activity entries (list of JSON strings).
class ActivityRepository {
  Future<List<Activity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_activitiesKey) ?? const [];
    final items = <Activity>[];
    for (final s in raw) {
      try {
        items.add(Activity.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed records.
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> save(List<Activity> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _activitiesKey,
      items.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
