import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';

/// Owns persistence for journal entries written in Home's writing area.
class JournalEntriesRepository {
  JournalEntriesRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Future<void> save(String content, {String? audioPath}) async {
    debugPrint('[JournalSave] about to insert content="$content"');
    final id = await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            createdAt: DateTime.now(),
            content: content,
            audioPath: Value(audioPath),
          ),
        );
    debugPrint('[JournalSave] insert complete, new row id=$id');
  }

  Stream<List<JournalEntryRow>> watchRecent({int limit = 20}) {
    return (_db.select(_db.journalEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Every saved entry, newest first — used by the calendar to mark which
  /// days have a journal entry.
  Stream<List<JournalEntryRow>> watchAll() {
    return (_db.select(_db.journalEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
