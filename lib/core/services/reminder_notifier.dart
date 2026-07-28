import '../database/tables/reminders_table.dart';

/// What [RemindersRepository] needs from a notification backend —
/// abstracted away from [NotificationService] itself so tests can supply a
/// trivial no-op fake instead of touching the real (singleton,
/// unsubstitutable) `flutter_local_notifications` plugin or platform
/// globals.
abstract class ReminderNotifier {
  Future<void> requestPermission();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required ReminderFrequency frequency,
    int? weekday,
    required int hour,
    required int minute,
  });

  Future<void> cancel(int id);
}
