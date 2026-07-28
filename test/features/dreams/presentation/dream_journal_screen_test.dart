import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/providers/database_provider.dart';
import 'package:mindful_journal/features/dreams/presentation/screens/dream_journal_screen.dart';
import 'package:mindful_journal/features/dreams/presentation/screens/dream_reflection_screen.dart';
import 'package:mindful_journal/features/dreams/presentation/screens/new_dream_screen.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';

Future<void> _pumpDreamJournalScreen(WidgetTester tester, AppDatabase db) async {
  // The default 800x600 test surface is shorter than several dream cards —
  // grow it so nothing needed by these tests lays out below the visible
  // viewport.
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/dreams',
    routes: [
      GoRoute(path: '/dreams', builder: (context, state) => const DreamJournalScreen()),
      GoRoute(path: '/dreams/new', builder: (context, state) => const NewDreamScreen()),
      GoRoute(
        path: '/dreams/reflection',
        builder: (context, state) => DreamReflectionScreen(dreamId: state.extra! as int),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _disposeAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

/// Writes and saves a dream, then skips the post-save reflection flow
/// entirely — the path most of these list/detection tests care about.
Future<void> _writeDream(WidgetTester tester, AppLocalizations l10n, String text) async {
  await tester.tap(find.text(l10n.dreamJournalWriteButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.text(l10n.dreamEntrySaveButton));
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.dreamReflectionSkipButton));
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  testWidgets('shows the empty state and a zero count with no dreams saved', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.dreamJournalTitle), findsOneWidget);
    expect(find.text(l10n.dreamJournalListHeader(0)), findsOneWidget);
    expect(find.text(l10n.dreamJournalEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('writing a dream saves it and tags a detected symbol', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await _writeDream(tester, l10n, 'I was swimming in the water all night');

    expect(find.text(l10n.dreamJournalListHeader(1)), findsOneWidget);
    expect(find.text(l10n.dreamSymbolWaterLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('tapping a symbol chip shows its gentle association', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await _writeDream(tester, l10n, 'I was flying over the ocean');
    await tester.tap(find.text(l10n.dreamSymbolFlyingLabel));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dreamSymbolFlyingDesc), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('shows a recurring-symbol insight only once a symbol appears in 3 dreams', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final insight = l10n.dreamJournalRecurringSymbolInsight(l10n.dreamSymbolWaterLabel);

    await _writeDream(tester, l10n, 'Dream one about water');
    expect(find.text(insight), findsNothing);

    await _writeDream(tester, l10n, 'Dream two, water again');
    expect(find.text(insight), findsNothing);

    await _writeDream(tester, l10n, 'Dream three, more water');
    expect(find.text(insight), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('answering the reflection flow shows the feeling chip and expanded details', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.dreamJournalWriteButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A quiet ordinary dream');
    await tester.tap(find.text(l10n.dreamEntrySaveButton));
    await tester.pumpAndSettle();

    // Page 1: feeling.
    await tester.tap(find.text(l10n.dreamFeelingPeaceful));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.dreamReflectionNextButton));
    await tester.pumpAndSettle();

    // Page 2: familiar person.
    await tester.tap(find.text(l10n.dreamFamiliarPersonYes));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.dreamReflectionNextButton));
    await tester.pumpAndSettle();

    // Page 3: first thought.
    await tester.enterText(
      find.byKey(const Key('dreamReflectionFirstThoughtField')),
      'I need to call my sister',
    );
    await tester.tap(find.text(l10n.dreamReflectionNextButton));
    await tester.pumpAndSettle();

    // Page 4: life connection.
    await tester.enterText(
      find.byKey(const Key('dreamReflectionLifeConnectionField')),
      'I have been missing home lately',
    );
    await tester.tap(find.text(l10n.dreamReflectionFinishButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dreamJournalTitle), findsOneWidget);
    expect(find.text(l10n.dreamFeelingPeaceful), findsOneWidget);
    expect(find.text(l10n.dreamCardFirstThoughtLabel), findsNothing);

    await tester.tap(find.text(l10n.dreamCardShowMore));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dreamCardFamiliarPersonLabel), findsOneWidget);
    expect(find.text(l10n.dreamFamiliarPersonYes), findsWidgets);
    expect(find.text(l10n.dreamCardFirstThoughtLabel), findsOneWidget);
    expect(find.text('I need to call my sister'), findsOneWidget);
    expect(find.text(l10n.dreamCardLifeConnectionLabel), findsOneWidget);
    expect(find.text('I have been missing home lately'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('skipping the reflection flow immediately leaves every field null', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.dreamJournalWriteButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'A dream I will not reflect on');
    await tester.tap(find.text(l10n.dreamEntrySaveButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.dreamReflectionSkipButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dreamJournalTitle), findsOneWidget);
    expect(find.text(l10n.dreamFeelingPeaceful), findsNothing);
    // "Show more" now always appears — even a short, unreflected-on dream
    // can be expanded to reach the AI interpretation feature.
    expect(find.text(l10n.dreamCardShowMore), findsOneWidget);

    await tester.tap(find.text(l10n.dreamCardShowMore));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dreamCardFamiliarPersonLabel), findsNothing);
    expect(find.text(l10n.dreamCardFirstThoughtLabel), findsNothing);
    expect(find.text(l10n.dreamCardLifeConnectionLabel), findsNothing);
    expect(find.text(l10n.dreamCardInterpretButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });

  testWidgets('tapping Interpret with AI surfaces a warm error when the request fails', (tester) async {
    await _pumpDreamJournalScreen(tester, db);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await _writeDream(tester, l10n, 'A quiet ordinary dream');

    await tester.tap(find.text(l10n.dreamCardShowMore));
    await tester.pumpAndSettle();
    expect(find.text(l10n.dreamCardInterpretButton), findsOneWidget);

    // No Supabase instance is configured in this test environment, so the
    // request fails immediately — exercising the same warm-error path a
    // real network failure would take, rather than a raw exception.
    await tester.tap(find.text(l10n.dreamCardInterpretButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.dreamCardInterpretError), findsOneWidget);
    expect(find.text(l10n.dreamCardInterpretButton), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeAndDrain(tester);
  });
}
