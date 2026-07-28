import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/tables/reminders_table.dart';
import 'package:mindful_journal/core/services/notification_service.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('gracefully no-ops on platforms without scheduled-notification support', () async {
    // macOS isn't one of NotificationService's supported platforms — every
    // call should complete without touching the (unavailable) plugin
    // channel or throwing.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final service = NotificationService.instance;

    await service.init();
    await service.requestPermission();
    await service.schedule(
      id: 1,
      title: 'T',
      body: 'B',
      frequency: ReminderFrequency.daily,
      hour: 8,
      minute: 0,
    );
    await service.cancel(1);
  });
}
