import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../data/letter_repository.dart';

final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  return LetterRepository(database: ref.watch(appDatabaseProvider));
});

class LettersNotifier extends StateNotifier<List<Letter>> {
  LettersNotifier(this._repo) : super(const []) {
    refresh();
  }

  final LetterRepository _repo;

  Future<void> refresh() async {
    state = await _repo.load();
    await _repo.fetchAndSyncFromSupabase();
    state = await _repo.load();
  }

  Future<void> add({
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    await _repo.save(
      title: title,
      body: body,
      openAt: openAt,
    );
    state = await _repo.load();
  }

  Future<void> delete(int id, {String? supabaseId}) async {
    await _repo.delete(id, supabaseId: supabaseId);
    state = await _repo.load();
  }
}

final lettersProvider =
    StateNotifierProvider<LettersNotifier, List<Letter>>((ref) {
  return LettersNotifier(ref.watch(letterRepositoryProvider));
});
