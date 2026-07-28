import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'dream_symbol_keywords.dart';

/// The canonical symbol keys detected in [dream]'s text at save time.
List<String> symbolTagsFor(DreamRow dream) =>
    dream.symbolTags.isEmpty ? const [] : dream.symbolTags.split(',');

/// Owns dream entry persistence via [AppDatabase]. Symbol detection happens
/// once, at save time, using the local keyword dictionary in
/// `dream_symbol_keywords.dart` — no AI involved.
class DreamsRepository {
  DreamsRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  /// Every saved dream, most recent first.
  Stream<List<DreamRow>> watchAll() =>
      (_db.select(_db.dreams)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  /// Inserts a new dream entry and returns its row id, so the caller can
  /// follow up with [saveReflection] once the optional reflection flow
  /// finishes (or is skipped).
  Future<int> addDream(String text) async {
    final trimmed = text.trim();
    final tags = detectDreamSymbols(trimmed);
    return _db.into(_db.dreams).insert(
          DreamsCompanion.insert(
            date: DateTime.now(),
            content: trimmed,
            symbolTags: Value(tags.join(',')),
          ),
        );
  }

  /// Records whatever the user answered in the post-save reflection flow.
  /// Any question left unanswered (including all of them, for a full skip)
  /// stays null — there's no forced completion.
  Future<void> saveReflection({
    required int id,
    String? feelingTag,
    String? familiarPerson,
    String? firstThought,
    String? lifeConnection,
  }) async {
    await (_db.update(_db.dreams)..where((t) => t.id.equals(id))).write(
      DreamsCompanion(
        feelingTag: Value(feelingTag),
        familiarPerson: Value(familiarPerson),
        firstThought: Value(firstThought),
        lifeConnection: Value(lifeConnection),
      ),
    );
  }

  /// Caches an AI-generated interpretation against a dream so re-opening
  /// the entry doesn't re-call the `dream-interpret` Edge Function.
  /// Overwrites any previously cached interpretation when the user
  /// explicitly asks to re-interpret.
  Future<void> saveAiInterpretation({required int id, required String interpretation}) async {
    await (_db.update(_db.dreams)..where((t) => t.id.equals(id))).write(
      DreamsCompanion(aiInterpretation: Value(interpretation)),
    );
  }
}
