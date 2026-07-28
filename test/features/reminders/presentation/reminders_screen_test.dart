import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/database/tables/reminders_table.dart';
import 'package:mindful_journal/core/services/reminder_notifier.dart';
import 'package:mindful_journal/features/reminders/presentation/providers/reminders_providers.dart';
import 'package:mindful_journal/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No-op stand-in for [NotificationService] — this suite is about the
/// screen/repository wiring, not the (separately tested) real plugin calls.
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

Future<void> _pumpRemindersScreen(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // `overrideWith` (not `overrideWithValue`) so the provider's own
        // `ref.onDispose(db.close)` still registers — otherwise Drift's
        // stream query store never tears down and leaves a pending Timer
        // that trips `testWidgets`' post-test invariant check.
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
        notificationServiceProvider.overrideWithValue(_FakeReminderNotifier()),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RemindersScreen(),
      ),
    ),
  );
  // `ensureSeeded` has several async hops (SharedPreferences -> Drift
  // insert -> stream emission); pump generously to drain all of them.
  // `pumpAndSettle` isn't an option here — the loading state's
  // indeterminate CircularProgressIndicator animates forever.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Tears the widget tree down *within* the test body (rather than relying
/// on `testWidgets`' automatic teardown between tests), then pumps once
/// more. Drift's `close()` schedules a zero-duration cleanup [Timer] as
/// part of disposing the database's stream query store; without an extra
/// pump to drain it, that timer is still pending when `testWidgets`' final
/// "no pending timers" invariant check runs, and the test fails despite
/// every assertion passing.
Future<void> _disposeAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Closed via the appDatabaseProvider override's own onDispose hook (see
    // _pumpRemindersScreen) once the widget tree tears down — not here, to
    // avoid closing it twice.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  testWidgets('seeds and shows the four starter reminders on first load', (tester) async {
    await _pumpRemindersScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.remindersTitle), findsOneWidget);
    expect(find.text(l10n.reminderMorningJournalTitle), findsOneWidget);
    expect(find.text(l10n.reminderBreathingBreakTitle), findsOneWidget);
    expect(find.text(l10n.reminderGratitudeMomentTitle), findsOneWidget);
    expect(find.text(l10n.reminderWeeklyReflectionTitle), findsOneWidget);
    expect(find.text('Daily - 08:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('upcoming tab only shows enabled reminders', (tester) async {
    await _pumpRemindersScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // The default tab is "Upcoming" — disable "Morning Journal" via its
    // switch while still there.
    final morningJournalCard = find.ancestor(
      of: find.text(l10n.reminderMorningJournalTitle),
      matching: find.byType(Container),
    ).first;
    final toggle = find.descendant(of: morningJournalCard, matching: find.byType(Switch));
    await tester.tap(toggle);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    // Gone from "Upcoming" now that it's disabled ...
    expect(find.text(l10n.reminderMorningJournalTitle), findsNothing);
    expect(find.text(l10n.reminderBreathingBreakTitle), findsOneWidget);

    // ... but still listed (just disabled) on "All".
    await tester.tap(find.text(l10n.remindersTabAll));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reminderMorningJournalTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('new reminder sheet adds a reminder to the list', (tester) async {
    await _pumpRemindersScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.remindersNewButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Evening Walk');
    await tester.tap(find.text(l10n.remindersNewSubmitButton));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Evening Walk'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });
}
