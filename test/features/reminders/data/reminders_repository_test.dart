import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/database/tables/reminders_table.dart';
import 'package:mindful_journal/core/services/reminder_notifier.dart';
import 'package:mindful_journal/features/reminders/data/reminders_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _copy = {
  DefaultReminderIconKeys.morningJournal: ReminderCopy(title: 'Morning Journal', body: 'Body A'),
  DefaultReminderIconKeys.breathingBreak: ReminderCopy(title: 'Breathing Break', body: 'Body B'),
  DefaultReminderIconKeys.gratitudeMoment: ReminderCopy(title: 'Gratitude Moment', body: 'Body C'),
  DefaultReminderIconKeys.weeklyReflection: ReminderCopy(title: 'Weekly Reflection', body: 'Body D'),
};

/// No-op stand-in for [NotificationService] — these tests are about the
/// database/repository logic; the plugin calls themselves are covered
/// separately in notification_service_test.dart and
/// reminder_scheduling_test.dart.
class _FakeReminderNotifier implements ReminderNotifier {
  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required ReminderFrequency frequency,
    int? weekday,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

void main() {
  late AppDatabase db;
  late RemindersRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RemindersRepository(database: db, notifications: _FakeReminderNotifier());
  });

  tearDown(() async {
    await db.close();
  });

  test('ensureSeeded inserts the four starter reminders exactly once', () async {
    await repository.ensureSeeded(_copy);
    final firstSeed = await db.select(db.reminders).get();
    expect(firstSeed, hasLength(4));
    expect(
      firstSeed.map((r) => r.title),
      containsAll(['Morning Journal', 'Breathing Break', 'Gratitude Moment', 'Weekly Reflection']),
    );
    expect(firstSeed.every((r) => r.enabled), isTrue);

    // Calling again (e.g. on a later app launch) must not duplicate them.
    await repository.ensureSeeded(_copy);
    expect(await db.select(db.reminders).get(), hasLength(4));
  });

  test('ensureSeeded does not resurrect reminders the user deleted', () async {
    await repository.ensureSeeded(_copy);
    final all = await db.select(db.reminders).get();
    await repository.delete(all.first);
    expect(await db.select(db.reminders).get(), hasLength(3));

    await repository.ensureSeeded(_copy); // simulate a later app launch
    expect(await db.select(db.reminders).get(), hasLength(3));
  });

  test('setEnabled toggles the stored enabled flag', () async {
    await repository.ensureSeeded(_copy);
    final reminder = (await db.select(db.reminders).get()).first;
    expect(reminder.enabled, isTrue);

    await repository.setEnabled(reminder, false);
    final disabledQuery = db.select(db.reminders)..where((t) => t.id.equals(reminder.id));
    expect((await disabledQuery.getSingle()).enabled, isFalse);

    final afterDisable = await disabledQuery.getSingle();
    await repository.setEnabled(afterDisable, true, copy: _copy[afterDisable.iconKey]);
    expect((await disabledQuery.getSingle()).enabled, isTrue);
  });

  test('addCustomReminder inserts a new enabled reminder with the custom icon key', () async {
    await repository.addCustomReminder(
      title: 'Evening Walk',
      frequency: ReminderFrequency.weekly,
      weekday: DateTime.friday,
      hour: 19,
      minute: 30,
      notificationBody: 'Time for your reminder',
    );

    final rows = await db.select(db.reminders).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, 'Evening Walk');
    expect(rows.single.iconKey, customReminderIconKey);
    expect(rows.single.frequency, ReminderFrequency.weekly);
    expect(rows.single.weekday, DateTime.friday);
    expect(rows.single.hour, 19);
    expect(rows.single.minute, 30);
    expect(rows.single.enabled, isTrue);
  });

  test('delete removes the reminder', () async {
    await repository.addCustomReminder(
      title: 'X',
      frequency: ReminderFrequency.daily,
      hour: 7,
      minute: 0,
      notificationBody: 'body',
    );
    final reminder = (await db.select(db.reminders).get()).single;

    await repository.delete(reminder);

    expect(await db.select(db.reminders).get(), isEmpty);
  });

  test('watchAll emits an updated list whenever a reminder is added', () async {
    final emittedCounts = <int>[];
    final subscription = repository.watchAll().listen((rows) => emittedCounts.add(rows.length));
    await pumpEventQueue();

    await repository.addCustomReminder(
      title: 'X',
      frequency: ReminderFrequency.daily,
      hour: 7,
      minute: 0,
      notificationBody: 'body',
    );
    await pumpEventQueue();

    await subscription.cancel();
    expect(emittedCounts, [0, 1]);
  });
}
