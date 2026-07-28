import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/journal/presentation/widgets/home_mood_background.dart';
import 'package:mindful_journal/theme/mood_gradients.dart';
import 'package:mindful_journal/theme/mood_theme_provider.dart';

Future<void> _pumpBackground(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: HomeMoodBackground(child: SizedBox.shrink())),
      ),
    ),
  );
  await tester.pump();
}

/// Steps animation time in small frame-sized chunks so continuously
/// repeating AnimationControllers (Ken Burns) and AnimatedSwitcher fades
/// advance realistically, mirroring the pattern used in
/// `luma_companion_test.dart`.
Future<void> _pumpFrames(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 16);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    final next = (total - elapsed) < step ? (total - elapsed) : step;
    await tester.pump(next);
    elapsed += next;
  }
}

void main() {
  testWidgets('defaults to the calm background when no mood is selected', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpBackground(tester, container);

    expect(find.byKey(const ValueKey('assets/images/home_bg_calm.png')), findsOneWidget);
  });

  testWidgets('shows the matching image for every mood', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpBackground(tester, container);

    for (final entry in HomeMoodBackground.assets.entries) {
      container.read(moodThemeProvider.notifier).state = entry.key;
      await _pumpFrames(tester, const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(ValueKey(entry.value)),
        findsOneWidget,
        reason: '${entry.key} should show ${entry.value}',
      );
    }
  });

  testWidgets('crossfades: both old and new images are present mid-transition', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpBackground(tester, container);
    // Settle the initial calm image in fully before switching.
    await _pumpFrames(tester, const Duration(milliseconds: 700));

    container.read(moodThemeProvider.notifier).state = AppMood.happy;
    // Advance partway into the 700ms crossfade — both frames should
    // briefly coexist rather than snapping instantly.
    await _pumpFrames(tester, const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('assets/images/home_bg_calm.png')), findsOneWidget);
    expect(find.byKey(const ValueKey('assets/images/home_bg_happy.png')), findsOneWidget);

    // Finish the transition — only the new image should remain.
    await _pumpFrames(tester, const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('assets/images/home_bg_calm.png')), findsNothing);
    expect(find.byKey(const ValueKey('assets/images/home_bg_happy.png')), findsOneWidget);
  });
}
