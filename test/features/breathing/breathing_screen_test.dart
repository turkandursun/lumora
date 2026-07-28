import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/breathing/presentation/screens/breathing_screen.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpBreathingScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BreathingScreen(),
      ),
    ),
  );
  await tester.pump(); // let the async last-mode load resolve
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mode selector shows all four techniques and a next button',
      (tester) async {
    await _pumpBreathingScreen(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.breathingModePrompt), findsOneWidget);
    expect(find.text(l10n.breathingModeCalmAnger), findsOneWidget);
    expect(find.text(l10n.breathingModeEaseAnxiety), findsOneWidget);
    expect(find.text(l10n.breathingModeRelaxUnwind), findsOneWidget);
    expect(find.text(l10n.breathingModeBoostEnergy), findsOneWidget);
    expect(find.text(l10n.onboardingNext), findsOneWidget);
  });

  testWidgets('next advances from mode selection to the duration selector',
      (tester) async {
    await _pumpBreathingScreen(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // stage crossfade

    expect(find.text(l10n.breathingDurationOption(2)), findsOneWidget);
    expect(find.text(l10n.breathingStartButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default box-breathing session cycles through inhale, hold, exhale, hold',
    (tester) async {
      await _pumpBreathingScreen(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(l10n.breathingStartButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.breathingPhaseIn), findsOneWidget);

      // Box breathing: inhale 4s -> hold 4s -> exhale 4s -> hold 4s.
      await tester.pump(const Duration(milliseconds: 4100));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(l10n.breathingPhaseHold), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(l10n.breathingPhaseOut), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(l10n.breathingPhaseHold), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'coherent breathing (relax & unwind) never shows a hold label',
    (tester) async {
      await _pumpBreathingScreen(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(find.text(l10n.breathingModeRelaxUnwind));
      await tester.pump();
      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(l10n.breathingStartButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.breathingPhaseIn), findsOneWidget);
      expect(find.text(l10n.breathingPhaseHold), findsNothing);

      // Coherent breathing: inhale 5s -> exhale 5s, no holds.
      await tester.pump(const Duration(milliseconds: 5100));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(l10n.breathingPhaseOut), findsOneWidget);
      expect(find.text(l10n.breathingPhaseHold), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stop ends the session and returns to the mode selector',
      (tester) async {
    await _pumpBreathingScreen(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.onboardingNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(l10n.breathingStartButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text(l10n.breathingStopButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(l10n.breathingModePrompt), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completing the shortest session shows the completion message, and '
    'continuing returns to the mode selector',
    (tester) async {
      await _pumpBreathingScreen(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(l10n.breathingDurationOption(2)));
      await tester.pump();
      await tester.tap(find.text(l10n.breathingStartButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Fast-forward the full 2-minute session in one jump — the countdown
      // Timer.periodic still fires every virtual second along the way.
      await tester.pump(const Duration(seconds: 121));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.breathingCompletionMessage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(l10n.breathingCompletionContinue));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.breathingModePrompt), findsOneWidget);
    },
  );

  testWidgets(
    'remembers the last selected mode across screen instances',
    (tester) async {
      await _pumpBreathingScreen(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      await tester.tap(find.text(l10n.breathingModeRelaxUnwind));
      await tester.pumpAndSettle();

      // Simulate a fresh app launch: a brand-new BreathingScreen instance,
      // backed by the same (mock) SharedPreferences store.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BreathingScreen(),
          ),
        ),
      );
      await tester.pump(); // let the async last-mode load resolve

      await tester.tap(find.text(l10n.onboardingNext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(l10n.breathingStartButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // If relax & unwind (5s/5s, no holds) carried over, we're in the
      // exhale phase just past 5s — box breathing (the hard-coded default)
      // would instead still be holding at this point.
      await tester.pump(const Duration(milliseconds: 5100));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(l10n.breathingPhaseOut), findsOneWidget);
      expect(find.text(l10n.breathingPhaseHold), findsNothing);

      expect(tester.takeException(), isNull);
    },
  );
}
