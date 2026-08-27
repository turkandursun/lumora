import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../create_page/domain/page_config.dart';

/// Holds the paper the user designed for journal writing, persisted so their
/// chosen ruling / colour / binding / background survives across sessions.
class JournalPageConfigNotifier extends StateNotifier<PageConfig> {
  JournalPageConfigNotifier() : super(_defaultPaper) {
    _load();
  }

  static const _key = 'journal_page_config_v1';

  // A blank white sheet is the starting point.
  static const PageConfig _defaultPaper = PageConfig(paperStyle: PaperStyle.blank);

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null) return;
      state = PageConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Keep the blank default on any failure.
    }
  }

  Future<void> update(PageConfig config) async {
    state = config;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(config.toJson()));
    } catch (_) {}
  }
}

final journalPageConfigProvider =
    StateNotifierProvider<JournalPageConfigNotifier, PageConfig>(
  (ref) => JournalPageConfigNotifier(),
);
