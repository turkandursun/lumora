import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_journal/core/router/app_router.dart';
import 'package:mindful_journal/features/journal/domain/journal_tone_analysis.dart';
import 'package:mindful_journal/features/journal/presentation/widgets/journal_tone_feedback_sheet.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('positive feedback has no wellness buttons', (tester) async {
    await tester.pumpWidget(_sheetApp(_analysis(tone: JournalTone.positive)));

    expect(find.byKey(const ValueKey('journal-tone-message')), findsOneWidget);
    expect(_allSuggestionButtons(), findsNothing);
  });

  testWidgets('mixed feedback has no wellness buttons', (tester) async {
    await tester.pumpWidget(_sheetApp(_analysis(tone: JournalTone.mixed)));

    expect(_allSuggestionButtons(), findsNothing);
  });

  testWidgets('only suggestions present in the response are rendered',
      (tester) async {
    await tester.pumpWidget(
      _sheetApp(
        _analysis(
          tone: JournalTone.lowMood,
          showWellnessSuggestions: true,
          suggestions: const [JournalWellnessSuggestion.calm],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('journal-tone-suggestion-calm')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('journal-tone-suggestion-breathing')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('journal-tone-suggestion-meditation')),
      findsNothing,
    );
  });

  for (final testCase in const [
    (
      JournalWellnessSuggestion.breathing,
      AppRoutes.breathing,
    ),
    (
      JournalWellnessSuggestion.meditation,
      AppRoutes.meditation,
    ),
    (
      JournalWellnessSuggestion.calm,
      AppRoutes.calm,
    ),
  ]) {
    testWidgets('${testCase.$1.name} action closes sheet and opens its route',
        (tester) async {
      final router = _routerForSuggestion(testCase.$1);
      addTearDown(router.dispose);
      await tester.pumpWidget(_routerApp(router));

      await tester.tap(find.byKey(const ValueKey('open-feedback')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          ValueKey('journal-tone-suggestion-${testCase.$1.name}'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JournalToneFeedbackSheet), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, testCase.$2);
      expect(
          find.byKey(ValueKey('target-${testCase.$1.name}')), findsOneWidget);
    });
  }
}

Finder _allSuggestionButtons() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('journal-tone-suggestion-'),
    );

Widget _sheetApp(JournalToneAnalysis analysis) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: JournalToneFeedbackSheet(analysis: analysis, isDark: false),
      ),
    );

GoRouter _routerForSuggestion(JournalWellnessSuggestion suggestion) {
  final analysis = _analysis(
    tone: JournalTone.lowMood,
    showWellnessSuggestions: true,
    suggestions: [suggestion],
  );
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            key: const ValueKey('open-feedback'),
            onPressed: () => unawaited(
              JournalToneFeedbackSheet.showAndNavigate(
                context: context,
                analysis: analysis,
                isDark: false,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.breathing,
        builder: (_, __) => const Scaffold(
          body: SizedBox(key: ValueKey('target-breathing')),
        ),
      ),
      GoRoute(
        path: AppRoutes.meditation,
        builder: (_, __) => const Scaffold(
          body: SizedBox(key: ValueKey('target-meditation')),
        ),
      ),
      GoRoute(
        path: AppRoutes.calm,
        builder: (_, __) => const Scaffold(
          body: SizedBox(key: ValueKey('target-calm')),
        ),
      ),
    ],
  );
}

Widget _routerApp(GoRouter router) => MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );

JournalToneAnalysis _analysis({
  required JournalTone tone,
  bool showWellnessSuggestions = false,
  List<JournalWellnessSuggestion> suggestions = const [],
}) =>
    JournalToneAnalysis(
      tone: tone,
      confidence: showWellnessSuggestions ? 0.91 : 0.70,
      message: 'A short and gentle reflection on the writing.',
      showWellnessSuggestions: showWellnessSuggestions,
      suggestions: suggestions,
    );
