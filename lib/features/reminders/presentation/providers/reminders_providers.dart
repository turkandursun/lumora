import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_notifier.dart';
import '../../data/reminders_repository.dart';

export '../../../../core/providers/database_provider.dart' show appDatabaseProvider;

final notificationServiceProvider = Provider<ReminderNotifier>((ref) {
  return NotificationService.instance;
});

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(
    database: ref.watch(appDatabaseProvider),
    notifications: ref.watch(notificationServiceProvider),
  );
});

/// Reactive list of every reminder, in insertion order — the "All" tab
/// shows this directly, and the "Upcoming" tab filters it down to enabled
/// reminders sorted by next-fire time.
final remindersStreamProvider = StreamProvider<List<ReminderRow>>((ref) {
  return ref.watch(remindersRepositoryProvider).watchAll();
});
