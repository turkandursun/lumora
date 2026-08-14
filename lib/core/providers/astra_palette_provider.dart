import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/astra_design_tokens.dart';

/// SharedPreferences key for the chosen theme family. Account-independent so a
/// choice made before/around sign-up carries into the account (and it is safe
/// to add to the cloud-backup whitelist later for cross-device sync).
const String astraPalettePrefsKey = 'astra_palette_id_v1';

/// Holds the user's selected [AstraThemeId]. Changing it re-skins the whole
/// app, because the shared UI kit and every screen background read their
/// colours from [activePaletteProvider], which derives from this.
class AstraPaletteNotifier extends StateNotifier<AstraThemeId> {
  AstraPaletteNotifier() : super(AstraThemeId.softLilacMist) {
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(astraPalettePrefsKey);
      if (saved != null) {
        state = AstraThemeId.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => AstraThemeId.softLilacMist,
        );
      }
    } catch (_) {
      // Fall back to the default family.
    }
  }

  Future<void> select(AstraThemeId id) async {
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(astraPalettePrefsKey, id.name);
    } catch (_) {
      // Keep the in-memory choice even if persistence fails.
    }
  }
}

final astraPaletteProvider =
    StateNotifierProvider<AstraPaletteNotifier, AstraThemeId>(
  (ref) => AstraPaletteNotifier(),
);

/// The resolved palette for the current selection — what widgets actually read.
final activePaletteProvider = Provider<AstraPalette>(
  (ref) => astraPaletteFor(ref.watch(astraPaletteProvider)),
);
