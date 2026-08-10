import 'package:drift/drift.dart';

/// User-scoped local mirror and offline outbox for quote favorites.
@DataClassName('QuoteFavoriteRow')
class QuoteFavorites extends Table {
  TextColumn get userId => text()();
  TextColumn get quoteId => text()();
  BoolColumn get isFavorite => boolean()();
  TextColumn get syncState => text()();
  DateTimeColumn get changedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, quoteId};
}
