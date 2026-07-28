import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/providers/database_provider.dart';
import 'package:mindful_journal/features/goals/presentation/screens/goals_screen.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpGoalsScreen(WidgetTester tester, AppDatabase db) async {
  // The default 800x600 test surface is shorter than four goal cards (or
  // the new-goal sheet's full form) — grow it so nothing needed by these
  // tests lays out below the visible viewport.
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GoalsScreen(),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _disposeAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  testWidgets('seeds and shows the four starter goals with a streak prompt', (tester) async {
    await _pumpGoalsScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.goalsTitle), findsOneWidget);
    expect(find.text(l10n.goalsDefaultWaterTitle), findsOneWidget);
    expect(find.text(l10n.goalsDefaultJournalTitle), findsOneWidget);
    expect(find.text(l10n.goalsDefaultMeditationTitle), findsOneWidget);
    expect(find.text(l10n.goalsDefaultReadingTitle), findsOneWidget);
    expect(find.text(l10n.goalsStreakStartPrompt), findsOneWidget);
    expect(find.text('0/8 glasses'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('tapping a goal card increments its progress and updates the streak', (tester) async {
    await _pumpGoalsScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text('+1 glasses'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.text('1/8 glasses'), findsOneWidget);
    expect(find.text(l10n.goalsStreakBanner(1)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('completing a goal shows the celebration message', (tester) async {
    await _pumpGoalsScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.text('+1 glasses'));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('8/8 glasses'), findsOneWidget);
    expect(find.text(l10n.goalsCompletedLabel), findsOneWidget);
    expect(
      find.text(l10n.goalsCelebrationMessage(l10n.goalsDefaultWaterTitle)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('new goal sheet adds a custom goal to the list', (tester) async {
    await _pumpGoalsScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.goalsNewButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.goalsNewTitleHint),
      'Evening stretch',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.goalsNewTargetHint),
      '10',
    );
    await tester.tap(find.text(l10n.goalsNewSubmitButton));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Evening stretch'), findsOneWidget);
    expect(find.text('0/10 glasses'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });
}
