import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../domain/daily_content.dart';
import '../domain/quote.dart';

/// Owns the offline-first quote catalogue.
///
/// Drift is the source read by the app. The bundled famous quotes bootstrap an
/// empty database, while Supabase refreshes the same rows (and any legacy
/// catalogue rows) in the background when it is available.
class QuotesRepository {
  QuotesRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  Future<int> _localQuoteCount() async {
    final rows = await _db.select(_db.quotes).get();
    return rows.length;
  }

  /// Seeds the 22 bundled famous quotes only when the local catalogue is empty.
  Future<void> ensureSeeded() async {
    final existingCount = await _localQuoteCount();
    if (existingCount > 0) {
      debugPrint(
        '[Quotes] embedded seed count: 0 '
        '(skipped; Drift already contains $existingCount rows)',
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final companions = <QuotesCompanion>[
      for (final entry in famousQuotes.indexed)
        QuotesCompanion.insert(
          id: entry.$2.id,
          textTr: entry.$2.tr,
          textEn: entry.$2.en,
          author: Value(entry.$2.author),
          rotationOrder: Value(entry.$1),
          isActive: true,
          source: 'famous',
          updatedAt: now,
        ),
    ];

    await _db.batch((batch) {
      batch.insertAll(
        _db.quotes,
        companions,
        mode: InsertMode.insertOrIgnore,
      );
    });
    debugPrint('[Quotes] embedded seed count: ${companions.length}');
  }

  /// Refreshes the local catalogue from Supabase without making network
  /// failures visible to catalogue consumers.
  Future<void> fetchAndSyncFromSupabase() async {
    try {
      debugPrint(
        '[Quotes] Supabase fetch started '
        '(authenticated: ${_client.auth.currentUser != null})',
      );
      final response = await _client.from('quotes').select();
      debugPrint('[Quotes] Supabase fetched count: ${response.length}');
      final fallbackUpdatedAt = DateTime.now().toUtc();
      final companions = <QuotesCompanion>[];

      for (final row in response) {
        final id = row['id'] as String?;
        final textTr = row['text_tr'] as String?;
        final textEn = row['text_en'] as String?;
        final source = row['source'] as String?;
        if (id == null || textTr == null || textEn == null || source == null) {
          continue;
        }

        final rawUpdatedAt = row['updated_at'];
        final updatedAt = rawUpdatedAt is String
            ? DateTime.tryParse(rawUpdatedAt)?.toUtc() ?? fallbackUpdatedAt
            : fallbackUpdatedAt;

        companions.add(
          QuotesCompanion.insert(
            id: id,
            textTr: textTr,
            textEn: textEn,
            author: Value(row['author'] as String?),
            rotationOrder: Value((row['rotation_order'] as num?)?.toInt()),
            isActive: row['is_active'] as bool? ?? false,
            source: source,
            updatedAt: updatedAt,
          ),
        );
      }

      if (companions.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.quotes, companions);
        });
      }
      debugPrint(
        '[Quotes] Drift count after sync: ${await _localQuoteCount()}',
      );
    } catch (error) {
      debugPrint('[Quotes] sync error: $error');
    }
  }

  /// Active daily-rotation quotes, always ordered by their stable index.
  Stream<List<Quote>> watchActiveQuotes() {
    final query = _db.select(_db.quotes)
      ..where((table) => table.isActive.equals(true))
      ..orderBy([
        (table) => OrderingTerm.asc(table.rotationOrder),
        (table) => OrderingTerm.asc(table.id),
      ]);
    return query.watch().map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  /// Resolves any active or legacy quote by its stable catalogue id.
  Future<Quote?> getById(String id) async {
    final row = await (_db.select(_db.quotes)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Quote _toDomain(QuoteRow row) {
    return Quote(
      id: row.id,
      textTr: row.textTr,
      textEn: row.textEn,
      author: row.author,
      rotationOrder: row.rotationOrder,
      isActive: row.isActive,
      source: row.source,
      updatedAt: row.updatedAt,
    );
  }
}
