import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hobbies_repository.dart';

final hobbiesRepositoryProvider = Provider<HobbiesRepository>((ref) {
  return HobbiesRepository();
});

class HobbiesNotifier extends StateNotifier<Set<String>> {
  HobbiesNotifier(this._repo) : super(const {}) {
    _load();
  }

  final HobbiesRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
    await _repo.save(next);
  }

  Future<void> add(String id) async {
    if (id.isEmpty || state.contains(id)) return;
    final next = {...state, id};
    state = next;
    await _repo.save(next);
  }

  Future<void> remove(String id) async {
    final next = {...state}..remove(id);
    state = next;
    await _repo.save(next);
  }
}

final hobbiesProvider =
    StateNotifierProvider<HobbiesNotifier, Set<String>>((ref) {
  return HobbiesNotifier(ref.watch(hobbiesRepositoryProvider));
});
