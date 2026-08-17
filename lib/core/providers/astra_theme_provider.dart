import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/data/astra_theme_repository.dart';

/// Represents the active theme chosen by the user
enum AstraThemeMode {
  dark,
  light,
}

typedef AstraThemePreferencesLoader = Future<SharedPreferences> Function();

const String astraThemePrefsKeyPrefix = 'astra_bg_theme_';

String astraThemePrefsKeyForUser(String userId) =>
    '$astraThemePrefsKeyPrefix$userId';

class AstraThemeNotifier extends StateNotifier<AstraThemeMode> {
  AstraThemeNotifier({
    required AstraThemeRepository repository,
    AstraThemePreferencesLoader? preferencesLoader,
    @visibleForTesting bool autoLoad = true,
  })  : _repository = repository,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        super(AstraThemeMode.light) {
    if (autoLoad) unawaited(reloadForCurrentUser());
  }

  final AstraThemeRepository _repository;
  final AstraThemePreferencesLoader _preferencesLoader;
  int _requestGeneration = 0;
  int _selectionVersion = 0;
  bool _disposed = false;
  Future<void> _saveQueue = Future<void>.value();

  @visibleForTesting
  Future<void> get pendingPersistence => _saveQueue;

  /// `sakura` was a palette identity in the legacy model. Palette identity is
  /// now stored in `palette_id`, so it safely maps to light appearance here.
  @visibleForTesting
  static AstraThemeMode modeFromPreference(Object? value) {
    return switch (value) {
      'light' => AstraThemeMode.light,
      'dark' => AstraThemeMode.dark,
      'sakura' => AstraThemeMode.light,
      _ => AstraThemeMode.light,
    };
  }

  static String preferenceForMode(AstraThemeMode mode) => mode.name;

  bool _isCurrentRequest({
    required String userId,
    required int generation,
    required int selectionVersion,
  }) {
    return !_disposed &&
        _requestGeneration == generation &&
        _selectionVersion == selectionVersion &&
        _repository.currentUserId == userId;
  }

  /// Applies the current account's local value first, then validates it
  /// against `profiles.theme_preference`. Pre-auth always stays light.
  @visibleForTesting
  Future<void> reloadForCurrentUser() async {
    final generation = ++_requestGeneration;
    final selectionVersion = _selectionVersion;
    final userId = _repository.currentUserId;
    if (!_disposed) state = AstraThemeMode.light;

    if (userId == null) return;

    try {
      final prefs = await _preferencesLoader();
      final localMode = modeFromPreference(
        prefs.getString(astraThemePrefsKeyForUser(userId)),
      );

      if (_isCurrentRequest(
        userId: userId,
        generation: generation,
        selectionVersion: selectionVersion,
      )) {
        state = localMode;
      }

      try {
        final cloudRaw = await _repository.fetchThemePreference(userId);
        final cloudMode = modeFromPreference(cloudRaw);
        if (!_isCurrentRequest(
          userId: userId,
          generation: generation,
          selectionVersion: selectionVersion,
        )) {
          return;
        }
        if (state != cloudMode) state = cloudMode;
        await prefs.setString(
          astraThemePrefsKeyForUser(userId),
          preferenceForMode(cloudMode),
        );
      } on AstraThemeAccountChangedException {
        // Expected when the authenticated account changes during the request.
      } catch (error) {
        debugPrint('[AstraTheme] Cloud theme load failed: $error');
      }
    } catch (error) {
      debugPrint('[AstraTheme] Local theme load failed: $error');
    }
  }

  Future<void> setTheme(AstraThemeMode mode) {
    final userId = _repository.currentUserId;
    _selectionVersion++;

    // Account-independent appearance must never leak into pre-auth UI.
    if (userId == null) {
      state = AstraThemeMode.light;
      return Future<void>.value();
    }

    state = mode;
    _saveQueue = _saveQueue.then(
      (_) => _persistTheme(userId: userId, mode: mode),
    );
    unawaited(_saveQueue);
    return Future<void>.value();
  }

  Future<void> setDarkMode(bool enabled) => setTheme(
        enabled ? AstraThemeMode.dark : AstraThemeMode.light,
      );

  Future<void> _persistTheme({
    required String userId,
    required AstraThemeMode mode,
  }) async {
    final value = preferenceForMode(mode);

    try {
      final prefs = await _preferencesLoader();
      await prefs.setString(astraThemePrefsKeyForUser(userId), value);
    } catch (error) {
      debugPrint('[AstraTheme] Local theme save failed: $error');
    }

    if (_disposed || _repository.currentUserId != userId) return;

    try {
      await _repository.updateThemePreference(userId, value);
    } on AstraThemeAccountChangedException {
      // The captured account changed; never write its choice as another user.
    } catch (error) {
      debugPrint('[AstraTheme] Cloud theme save failed: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    super.dispose();
  }
}

final astraThemeRepositoryProvider = Provider<AstraThemeRepository>(
  (ref) => SupabaseAstraThemeRepository(),
);

final astraThemeProvider =
    StateNotifierProvider<AstraThemeNotifier, AstraThemeMode>((ref) {
  return AstraThemeNotifier(
    repository: ref.watch(astraThemeRepositoryProvider),
  );
});
