import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/letter_repository.dart';

final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  return LetterRepository();
});

class LettersNotifier extends StateNotifier<List<Letter>> {
  LettersNotifier(this._repo) : super(const []) {
    _load();
  }

  final LetterRepository _repo;

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> add({
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    final letter = Letter(
      id: DateTime.now().millisecondsSinceEpoch,
      createdAt: DateTime.now(),
      openAt: openAt,
      title: title.trim(),
      body: body.trim(),
    );
    final next = [letter, ...state]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = next;
    await _repo.save(next);
  }

  Future<void> delete(int id) async {
    final next = state.where((l) => l.id != id).toList();
    state = next;
    await _repo.save(next);
  }
}

final lettersProvider =
    StateNotifierProvider<LettersNotifier, List<Letter>>((ref) {
  return LettersNotifier(ref.watch(letterRepositoryProvider));
});
