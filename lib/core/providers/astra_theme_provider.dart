import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/theme_choice/presentation/screens/theme_choice_screen.dart';

/// Represents the active theme chosen by the user
enum AstraThemeMode {
  dark,  // Moon / Ay Teması (Mor alttonlu)
  light, // Sun / Güneş Teması (Sarı alttonlu)
}

class AstraThemeNotifier extends StateNotifier<AstraThemeMode> {
  AstraThemeNotifier(this._client)
      : _userId = _client.auth.currentUser?.id,
        super(AstraThemeMode.light) {
    // The app moved to the 7-family light pastel palette system. Light/dark
    // mode is deprecated; the whole app is now light so screen colours stay
    // readable on the pastel backgrounds. We no longer read the saved mode.
    // (setTheme is kept for compatibility but is unused by the UI.)
  }

  final SupabaseClient _client;
  final String? _userId;
  int _selectionVersion = 0;
  bool _disposed = false;
  Future<void> _saveQueue = Future<void>.value();

  String get _storageKey => '${astraThemeKey}_${_userId ?? 'guest'}';

  static AstraThemeMode? _modeFromString(Object? value) {
    return switch (value) {
      'light' => AstraThemeMode.light,
      'dark' => AstraThemeMode.dark,
      _ => null,
    };
  }

  static String _modeToString(AstraThemeMode mode) => mode.name;

  Future<void> _loadTheme() async {
    final loadVersion = _selectionVersion;
    try {
      final prefs = await SharedPreferences.getInstance();
      final localMode = _modeFromString(prefs.getString(_storageKey)) ??
          AstraThemeMode.dark;

      // Local-first: paint the saved theme immediately without waiting for
      // the network. Do not overwrite a choice made while prefs were loading.
      if (!_disposed && _selectionVersion == loadVersion) {
        state = localMode;
      }

      // Guest sessions intentionally remain local-only. Auth changes recreate
      // this notifier, so the captured user id never crosses account borders.
      if (!_disposed && _userId != null) {
        unawaited(_syncFromCloud(
          prefs: prefs,
          localMode: localMode,
          loadVersion: loadVersion,
        ));
      }
    } catch (error) {
      debugPrint('[AstraTheme] Local theme load failed: $error');
    }
  }

  Future<void> _syncFromCloud({
    required SharedPreferences prefs,
    required AstraThemeMode localMode,
    required int loadVersion,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final profile = await _client
          .from('profiles')
          .select('theme_preference')
          .eq('id', userId)
          .maybeSingle();
      final cloudMode = _modeFromString(profile?['theme_preference']);
      if (cloudMode == null || cloudMode == localMode) return;

      // A manual selection made after this request started always wins over
      // an older cloud response; setTheme is already syncing that new choice.
      if (_disposed || _selectionVersion != loadVersion) return;

      state = cloudMode;
      await prefs.setString(_storageKey, _modeToString(cloudMode));
    } catch (error) {
      // Offline/cloud failures must never block startup or change local state.
      debugPrint('[AstraTheme] Cloud theme sync failed: $error');
    }
  }

  Future<void> setTheme(AstraThemeMode mode) {
    _selectionVersion++;
    state = mode;
    _saveQueue = _saveQueue.then((_) => _persistTheme(mode));
    unawaited(_saveQueue);
    return Future<void>.value();
  }

  Future<void> _persistTheme(AstraThemeMode mode) async {
    final value = _modeToString(mode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, value);
    } catch (error) {
      debugPrint('[AstraTheme] Local theme save failed: $error');
    }

    final userId = _userId;
    if (userId == null) return;

    try {
      await _client
          .from('profiles')
          .update({'theme_preference': value}).eq('id', userId);
    } catch (error) {
      // The UI has already reacted locally; cloud sync can retry next launch.
      debugPrint('[AstraTheme] Cloud theme save failed: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final astraThemeProvider = StateNotifierProvider<AstraThemeNotifier, AstraThemeMode>((ref) {
  return AstraThemeNotifier(Supabase.instance.client);
});
