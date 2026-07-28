import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';
import 'package:mindful_journal/theme/crisis_support_sheet.dart';

Future<void> _pumpHost(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => CrisisSupportSheet.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the warm opening line and disclaimer, never blocking dismissal', (
    tester,
  ) async {
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    tester.binding.platformDispatcher.localeTestValue = const Locale('en', 'GB');

    await _pumpHost(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text("It looks like you're going through something hard right now. You're not alone."),
      findsOneWidget,
    );
    expect(
      find.text("This isn't a substitute for professional care, but reaching out can really help."),
      findsOneWidget,
    );

    // A country other than Turkey/the US falls back to the universal
    // findahelpline.com resource.
    expect(find.text('Find a helpline near you'), findsOneWidget);

    await tester.tap(find.text("I'm okay, continue"));
    await tester.pumpAndSettle();

    expect(find.text("I'm okay, continue"), findsNothing);
  });

  testWidgets('shows Turkey resources when the device region is Turkey', (tester) async {
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    tester.binding.platformDispatcher.localeTestValue = const Locale('tr', 'TR');

    await _pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('112 - Emergency Line'), findsOneWidget);
    expect(find.text('183 - Social Support Line'), findsOneWidget);
  });

  testWidgets('shows the US crisis lifeline when the device region is the US', (tester) async {
    addTearDown(() => tester.binding.platformDispatcher.clearLocaleTestValue());
    tester.binding.platformDispatcher.localeTestValue = const Locale('en', 'US');

    await _pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('988 - Suicide & Crisis Lifeline'), findsOneWidget);
  });
}
