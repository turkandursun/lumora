import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// The single [AppDatabase] instance shared by every feature that persists
/// to local storage (reminders, goals, and eventually journal entries).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
