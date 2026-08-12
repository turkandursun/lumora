import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hobbies_repository.dart';

final hobbiesRepositoryProvider = Provider<HobbiesRepository>((ref) {
  return HobbiesRepository();
});

class HobbiesNotifier extends StateNotifier<Set<String>> {
  HobbiesNotifier(this._repo) : super(const {}) {
    _initialization = _load();
  }

  final HobbiesPersistence _repo;
  late final Future<void> _initialization;
  Future<void> _saveTail = Future<void>.value();
  final Map<String, bool> _pendingSelections = {};
  bool _initializing = true;

  Set<String> _withPendingSelections(Set<String> loaded) {
    final merged = {...loaded};
    for (final entry in _pendingSelections.entries) {
      if (entry.value) {
        merged.add(entry.key);
      } else {
        merged.remove(entry.key);
      }
    }
    return merged;
  }

  Future<void> _load() async {
    try {
      state = _withPendingSelections(await _repo.load());
      state = _withPendingSelections(await _repo.syncHobbiesWithSupabase());
    } catch (error) {
      debugPrint('[HobbiesSync] Initialization error: $error');
    } finally {
      _initializing = false;
      _pendingSelections.clear();
    }
  }

  Future<void> _persistLatest() {
    _saveTail = _saveTail.then((_) async {
      await _initialization;
      await _repo.save({...state});
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint('[HobbiesSync] Persistence error: $error');
    });
    return _saveTail;
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
    if (_initializing) _pendingSelections[id] = next.contains(id);
    await _persistLatest();
  }

  Future<void> add(String id) async {
    if (id.isEmpty || state.contains(id)) return;
    final next = {...state, id};
    state = next;
    if (_initializing) _pendingSelections[id] = true;
    await _persistLatest();
  }

  Future<void> remove(String id) async {
    final next = {...state}..remove(id);
    state = next;
    if (_initializing) _pendingSelections[id] = false;
    await _persistLatest();
  }
}

final hobbiesProvider =
    StateNotifierProvider<HobbiesNotifier, Set<String>>((ref) {
  return HobbiesNotifier(ref.watch(hobbiesRepositoryProvider));
});
