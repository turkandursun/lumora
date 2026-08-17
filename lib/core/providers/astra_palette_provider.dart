import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/data/astra_palette_repository.dart';
import '../../theme/astra_design_tokens.dart';

typedef AstraPalettePreferencesLoader = Future<SharedPreferences> Function();

const String astraLegacyPalettePrefsKey = 'astra_palette_id_v1';
const String astraPalettePrefsKeyPrefix = 'astra_palette_id_v2_';
const AstraThemeId defaultAstraPaletteId = AstraThemeId.softLilacMist;

String astraPalettePrefsKeyForUser(String userId) =>
    '$astraPalettePrefsKeyPrefix$userId';

/// Holds the user's selected [AstraThemeId]. Changing it re-skins the whole
/// app, because the shared UI kit and every screen background read their
/// colours from [activePaletteProvider], which derives from this.
class AstraPaletteNotifier extends StateNotifier<AstraThemeId> {
  AstraPaletteNotifier({
    required AstraPaletteRepository repository,
    AstraPalettePreferencesLoader? preferencesLoader,
    @visibleForTesting bool autoLoad = true,
  })  : _repository = repository,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        super(defaultAstraPaletteId) {
    if (autoLoad) unawaited(reloadForCurrentUser());
  }

  final AstraPaletteRepository _repository;
  final AstraPalettePreferencesLoader _preferencesLoader;
  int _requestGeneration = 0;
  int _selectionVersion = 0;
  bool _disposed = false;
  Future<void> _saveQueue = Future<void>.value();
  final Completer<void> _localBootstrapCompleter = Completer<void>();

  @visibleForTesting
  Future<void> get pendingPersistence => _saveQueue;

  /// Completes as soon as the current account's local cache (or safe default)
  /// has been applied. Cloud validation intentionally continues in background.
  Future<void> get localBootstrapCompleted => _localBootstrapCompleter.future;

  void _completeLocalBootstrap() {
    if (!_localBootstrapCompleter.isCompleted) {
      _localBootstrapCompleter.complete();
    }
  }

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

  /// Loads the active account local-first, then validates it against cloud.
  /// Calling it again invalidates every older in-flight result.
  @visibleForTesting
  Future<void> reloadForCurrentUser() async {
    final generation = ++_requestGeneration;
    final selectionVersion = _selectionVersion;
    final userId = _repository.currentUserId;

    if (!_disposed) state = defaultAstraPaletteId;

    try {
      final prefs = await _preferencesLoader();
      // The v1 key has no trustworthy owner and is never migrated to an
      // account. Removing it prevents future code from accidentally reusing it.
      await prefs.remove(astraLegacyPalettePrefsKey);

      if (userId == null ||
          _disposed ||
          _requestGeneration != generation ||
          _repository.currentUserId != userId) {
        _completeLocalBootstrap();
        return;
      }

      final localRaw = prefs.getString(astraPalettePrefsKeyForUser(userId));
      final localId = AstraThemeId.fromWireValue(localRaw);
      if (_isCurrentRequest(
        userId: userId,
        generation: generation,
        selectionVersion: selectionVersion,
      )) {
        state = localId;
      }
      _completeLocalBootstrap();

      try {
        final cloudRaw = await _repository.fetchPaletteId(userId);
        final cloudId = AstraThemeId.fromWireValue(cloudRaw);
        if (!_isCurrentRequest(
          userId: userId,
          generation: generation,
          selectionVersion: selectionVersion,
        )) {
          return;
        }

        if (state != cloudId) state = cloudId;
        await prefs.setString(
          astraPalettePrefsKeyForUser(userId),
          cloudId.wireValue,
        );
      } on AstraPaletteAccountChangedException {
        // Expected when an account changes while the request is in flight.
      } catch (error) {
        // Offline/cloud failures leave the fast local value intact.
        debugPrint('[AstraPalette] Cloud palette load failed: $error');
      }
    } catch (error) {
      // Missing/unavailable preferences leave the safe default in memory.
      _completeLocalBootstrap();
      debugPrint('[AstraPalette] Local palette load failed: $error');
    }
  }

  Future<void> select(AstraThemeId id) async {
    final userId = _repository.currentUserId;
    _selectionVersion++;

    // Pre-auth UI always uses ASTRA's neutral default and never reads/writes an
    // account cache. Phase 3 will remove the pre-auth picker route itself.
    if (userId == null) {
      state = defaultAstraPaletteId;
      return;
    }

    state = id;
    _saveQueue = _saveQueue.then(
      (_) => _persistSelection(userId: userId, id: id),
    );
    unawaited(_saveQueue);
  }

  Future<void> _persistSelection({
    required String userId,
    required AstraThemeId id,
  }) async {
    try {
      final prefs = await _preferencesLoader();
      await prefs.setString(
        astraPalettePrefsKeyForUser(userId),
        id.wireValue,
      );
    } catch (error) {
      debugPrint('[AstraPalette] Local palette save failed: $error');
    }

    if (_disposed || _repository.currentUserId != userId) return;

    try {
      await _repository.updatePaletteId(userId, id.wireValue);
    } on AstraPaletteAccountChangedException {
      // The selection belongs to the captured account; never write it as the
      // newly signed-in user.
    } catch (error) {
      // The local selection remains active. Cloud is retried by a later user
      // selection; startup keeps cloud authoritative across devices.
      debugPrint('[AstraPalette] Cloud palette save failed: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    super.dispose();
  }
}

final astraPaletteRepositoryProvider = Provider<AstraPaletteRepository>(
  (ref) => SupabaseAstraPaletteRepository(),
);

final astraPaletteProvider =
    StateNotifierProvider<AstraPaletteNotifier, AstraThemeId>(
  (ref) => AstraPaletteNotifier(
    repository: ref.watch(astraPaletteRepositoryProvider),
  ),
);

/// Recreates the provider for the current auth identity and waits only for the
/// fast local cache. A timeout keeps startup safe; cloud validation continues
/// independently inside the notifier.
Future<void> bootstrapAstraPaletteForCurrentUser(WidgetRef ref) async {
  ref.invalidate(astraPaletteProvider);
  final notifier = ref.read(astraPaletteProvider.notifier);
  try {
    await notifier.localBootstrapCompleted.timeout(
      const Duration(seconds: 2),
    );
  } on TimeoutException {
    debugPrint('[AstraPalette] Local bootstrap timed out; using safe default');
  }
}

/// The resolved palette for the current selection — what widgets actually read.
final activePaletteProvider = Provider<AstraPalette>(
  (ref) => astraPaletteFor(ref.watch(astraPaletteProvider)),
);
