import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../domain/quote.dart';

const _favoriteQuoteIdsKey = 'favorite_quote_ids';
const _pendingSyncState = 'pending';
const _syncedSyncState = 'synced';

final _legacyQuoteIdPattern = RegExp(r'^quote_[1-6]$');

/// Local-first persistence and cloud synchronization for user quote favorites.
class QuoteFavoritesRepository {
  QuoteFavoritesRepository({
    required AppDatabase database,
    SupabaseClient? supabaseClient,
  })  : _db = database,
        _client = supabaseClient ?? Supabase.instance.client;

  final AppDatabase _db;
  final SupabaseClient _client;

  String _migrationMarker(String userId) =>
      'quote_favorites_migrated_v1_$userId';

  Stream<Set<String>> watchFavoriteIdsForCurrentUser() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const <String>{});

    final query = _db.select(_db.quoteFavorites)
      ..where(
        (table) => table.userId.equals(userId) & table.isFavorite.equals(true),
      );
    return query.watch().map(
          (rows) => rows.map((row) => row.quoteId).toSet(),
        );
  }

  /// Favorite quote models resolved entirely from the local Drift catalogue.
  Stream<List<Quote>> watchFavoriteQuotesForCurrentUser() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const <Quote>[]);

    final query = _db.select(_db.quoteFavorites).join([
      innerJoin(
        _db.quotes,
        _db.quotes.id.equalsExp(_db.quoteFavorites.quoteId),
      ),
    ])
      ..where(
        _db.quoteFavorites.userId.equals(userId) &
            _db.quoteFavorites.isFavorite.equals(true),
      )
      ..orderBy([OrderingTerm.desc(_db.quoteFavorites.changedAt)]);

    return query.watch().map(
          (rows) => rows
              .map((row) => _quoteToDomain(row.readTable(_db.quotes)))
              .toList(growable: false),
        );
  }

  Future<void> toggle(String quoteId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final existing = await _localRow(userId, quoteId);
    final shouldFavorite = !(existing?.isFavorite ?? false);
    final changedAt = DateTime.now().toUtc();

    debugPrint(
      '[QuoteFavorites] toggle ${shouldFavorite ? 'add' : 'remove'}: $quoteId',
    );
    await _db.into(_db.quoteFavorites).insertOnConflictUpdate(
          QuoteFavoritesCompanion.insert(
            userId: userId,
            quoteId: quoteId,
            isFavorite: shouldFavorite,
            syncState: _pendingSyncState,
            changedAt: changedAt,
          ),
        );
    debugPrint(
      '[QuoteFavorites] local pending '
      '${shouldFavorite ? 'add' : 'remove'} saved',
    );

    final pending = await _localRow(userId, quoteId);
    if (pending != null) {
      await _pushPendingRow(userId, pending);
    }
  }

  Future<void> syncForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final syncStartedAt = DateTime.now().toUtc();

    debugPrint('[QuoteFavorites] sync started user=$userId');
    try {
      final pendingRows = await (_db.select(_db.quoteFavorites)
            ..where(
              (table) =>
                  table.userId.equals(userId) &
                  table.syncState.equals(_pendingSyncState),
            ))
          .get();
      debugPrint('[QuoteFavorites] pending count=${pendingRows.length}');

      for (final row in pendingRows) {
        await _pushPendingRow(userId, row);
      }

      if (_client.auth.currentUser?.id != userId) return;
      final cloudRows = await _client
          .from('quote_favorites')
          .select('quote_id')
          .eq('user_id', userId);
      final cloudIds = cloudRows
          .map((row) => row['quote_id'] as String?)
          .whereType<String>()
          .toSet();
      debugPrint('[QuoteFavorites] cloud favorite count=${cloudIds.length}');

      if (_client.auth.currentUser?.id != userId) return;
      await _db.transaction(() async {
        final localRows = await (_db.select(_db.quoteFavorites)
              ..where((table) => table.userId.equals(userId)))
            .get();
        final localById = {for (final row in localRows) row.quoteId: row};

        bool isProtectedLocalChange(QuoteFavoriteRow row) =>
            row.syncState == _pendingSyncState ||
            row.changedAt.isAfter(syncStartedAt);

        final pulledAt = DateTime.now().toUtc();
        for (final quoteId in cloudIds) {
          final local = localById[quoteId];
          if (local != null && isProtectedLocalChange(local)) continue;
          await _db.into(_db.quoteFavorites).insertOnConflictUpdate(
                QuoteFavoritesCompanion.insert(
                  userId: userId,
                  quoteId: quoteId,
                  isFavorite: true,
                  syncState: _syncedSyncState,
                  changedAt: pulledAt,
                ),
              );
        }

        for (final local in localRows) {
          if (isProtectedLocalChange(local)) continue;
          if (!local.isFavorite || !cloudIds.contains(local.quoteId)) {
            await (_db.delete(_db.quoteFavorites)
                  ..where(
                    (table) =>
                        table.userId.equals(userId) &
                        table.quoteId.equals(local.quoteId),
                  ))
                .go();
          }
        }
      });

      if (_client.auth.currentUser?.id != userId) return;
      final localRows = await (_db.select(_db.quoteFavorites)
            ..where((table) => table.userId.equals(userId)))
          .get();
      final activeCount = localRows.where((row) => row.isFavorite).length;
      final pendingCount =
          localRows.where((row) => row.syncState == _pendingSyncState).length;
      debugPrint(
        '[QuoteFavorites] local active favorite count=$activeCount',
      );
      debugPrint('[QuoteFavorites] pending count=$pendingCount');
    } catch (error) {
      debugPrint('[QuoteFavorites] sync error: $error');
    }
  }

  Future<void> migrateLegacyFavoritesForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final marker = _migrationMarker(userId);
    if (prefs.getBool(marker) ?? false) return;

    final oldIds =
        prefs.getStringList(_favoriteQuoteIdsKey) ?? const <String>[];
    final quoteIds = oldIds.where(_isQuoteId).toSet();
    debugPrint('[QuoteFavorites] legacy migration count=${quoteIds.length}');

    if (quoteIds.isEmpty) {
      await prefs.setBool(marker, true);
      debugPrint('[QuoteFavorites] legacy migration completed');
      return;
    }

    final changedAt = DateTime.now().toUtc();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.quoteFavorites,
        [
          for (final quoteId in quoteIds)
            QuoteFavoritesCompanion.insert(
              userId: userId,
              quoteId: quoteId,
              isFavorite: true,
              syncState: _pendingSyncState,
              changedAt: changedAt,
            ),
        ],
      );
    });

    try {
      await _client.from('quote_favorites').upsert(
        [
          for (final quoteId in quoteIds)
            {'user_id': userId, 'quote_id': quoteId},
        ],
        onConflict: 'user_id,quote_id',
      );
      if (_client.auth.currentUser?.id != userId) return;

      for (final quoteId in quoteIds) {
        await (_db.update(_db.quoteFavorites)
              ..where(
                (table) =>
                    table.userId.equals(userId) &
                    table.quoteId.equals(quoteId) &
                    table.isFavorite.equals(true) &
                    table.syncState.equals(_pendingSyncState) &
                    table.changedAt.equals(changedAt),
              ))
            .write(
          const QuoteFavoritesCompanion(
            syncState: Value(_syncedSyncState),
          ),
        );
      }

      final remainingIds =
          oldIds.where((id) => !quoteIds.contains(id)).toList();
      if (remainingIds.isEmpty) {
        await prefs.remove(_favoriteQuoteIdsKey);
      } else {
        await prefs.setStringList(_favoriteQuoteIdsKey, remainingIds);
      }
      await prefs.setBool(marker, true);
      debugPrint('[QuoteFavorites] legacy migration completed');
    } catch (error) {
      debugPrint('[QuoteFavorites] sync error: $error');
    }
  }

  Future<void> clearLocalDataForUser(String userId) async {
    await (_db.delete(_db.quoteFavorites)
          ..where((table) => table.userId.equals(userId)))
        .go();
  }

  Future<void> clearAllLocalData() async {
    await _db.delete(_db.quoteFavorites).go();
  }

  Future<QuoteFavoriteRow?> _localRow(String userId, String quoteId) {
    return (_db.select(_db.quoteFavorites)
          ..where(
            (table) =>
                table.userId.equals(userId) & table.quoteId.equals(quoteId),
          ))
        .getSingleOrNull();
  }

  Future<bool> _pushPendingRow(
    String userId,
    QuoteFavoriteRow row,
  ) async {
    try {
      if (row.isFavorite) {
        await _client.from('quote_favorites').upsert(
          {'user_id': userId, 'quote_id': row.quoteId},
          onConflict: 'user_id,quote_id',
        );
        debugPrint(
          '[QuoteFavorites] Supabase upsert success: ${row.quoteId}',
        );
      } else {
        await _client
            .from('quote_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('quote_id', row.quoteId);
        debugPrint(
          '[QuoteFavorites] Supabase delete success: ${row.quoteId}',
        );
      }

      if (_client.auth.currentUser?.id != userId) return true;
      if (row.isFavorite) {
        await (_db.update(_db.quoteFavorites)
              ..where(
                (table) =>
                    table.userId.equals(userId) &
                    table.quoteId.equals(row.quoteId) &
                    table.isFavorite.equals(true) &
                    table.syncState.equals(_pendingSyncState) &
                    table.changedAt.equals(row.changedAt),
              ))
            .write(
          const QuoteFavoritesCompanion(
            syncState: Value(_syncedSyncState),
          ),
        );
      } else {
        await (_db.delete(_db.quoteFavorites)
              ..where(
                (table) =>
                    table.userId.equals(userId) &
                    table.quoteId.equals(row.quoteId) &
                    table.isFavorite.equals(false) &
                    table.syncState.equals(_pendingSyncState) &
                    table.changedAt.equals(row.changedAt),
              ))
            .go();
      }
      return true;
    } catch (error) {
      debugPrint('[QuoteFavorites] sync error: $error');
      return false;
    }
  }

  bool _isQuoteId(String id) =>
      id.startsWith('fq_') || _legacyQuoteIdPattern.hasMatch(id);

  Quote _quoteToDomain(QuoteRow row) {
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
