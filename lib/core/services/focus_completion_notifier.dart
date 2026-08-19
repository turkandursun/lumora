/// Notification boundary for a running focus interval.
abstract interface class FocusCompletionNotifier {
  Future<void> requestPermission();

  Future<void> scheduleFocusCompletion({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  });

  Future<void> cancelFocusCompletion(int id);
}
