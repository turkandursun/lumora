import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_lock_service.dart';
import '../../domain/app_section.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) => AppLockService());

/// Whether a PIN has been set up yet. Watched by the settings screen to
/// decide between showing "Set PIN" vs "Change PIN", and by section gates
/// (no PIN ever set means nothing can actually be locked).
final hasPinProvider = FutureProvider<bool>((ref) {
  return ref.watch(appLockServiceProvider).hasPin();
});

/// The set of [AppSection]s currently toggled on in App Lock settings.
/// Re-read from secure storage via `ref.invalidate` whenever a toggle
/// changes, so every live [SectionLockGate] picks up the new state.
final protectedSectionsProvider = FutureProvider<Set<AppSection>>((ref) {
  return ref.watch(appLockServiceProvider).getProtectedSections();
});

/// Sections unlocked for the CURRENT app session only — reset by simply
/// recreating the provider container, i.e. a full app restart. Never
/// persisted, and deliberately untouched by app backgrounding/resuming.
class SectionUnlockNotifier extends StateNotifier<Set<AppSection>> {
  SectionUnlockNotifier() : super(const {});

  void unlock(AppSection section) => state = {...state, section};
}

final sectionUnlockProvider =
    StateNotifierProvider<SectionUnlockNotifier, Set<AppSection>>((ref) {
  return SectionUnlockNotifier();
});
