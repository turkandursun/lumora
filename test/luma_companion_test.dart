import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';
import 'package:mindful_journal/theme/luma_companion.dart';
import 'package:mindful_journal/theme/mood_gradients.dart';
import 'package:mindful_journal/theme/mood_theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpLuma(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LumaCompanion(child: SizedBox.shrink())),
      ),
    ),
  );
  // Continuously-repeating AnimationControllers never settle, so advance
  // fixed frames instead of pumpAndSettle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pumps [total] worth of animation time in small ~16ms (one-frame) steps,
/// mirroring real 60fps rendering. A single huge `pump(total)` only ever
/// produces *one* frame tick — whose elapsed time is always 0 relative to
/// a just-started ticker — so an [AnimationController] driven that way
/// never actually advances past its start value. Stepping avoids that
/// artifact and lets fade animations progress realistically.
Future<void> _pumpFrames(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 16);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    final next = (total - elapsed) < step ? (total - elapsed) : step;
    await tester.pump(next);
    elapsed += next;
  }
}

/// Records play/pause/resume/volume calls instead of touching real
/// platform audio channels, so tests can assert on exactly how
/// [LumaCompanion]'s ambient rain loop is driven.
class _FakeAudioPlayer extends AudioPlayer {
  int playCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  final List<double> volumeSets = [];

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playCalls++;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
  }

  @override
  Future<void> setVolume(double volume) async {
    volumeSets.add(volume);
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    debugRainPlayerFactory = null;
  });

  testWidgets('shows one of the rotating greetings on load', (tester) async {
    await _pumpLuma(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final greetings = [
      l10n.lumaGreeting1,
      l10n.lumaGreeting2,
      l10n.lumaGreeting3,
      l10n.lumaGreeting4,
      l10n.lumaGreeting5,
    ];
    final shown = greetings.where((g) => find.text(g).evaluate().isNotEmpty);
    expect(shown.length, 1);
  });

  testWidgets('speech bubble switches to the mood-acknowledging line on mood select',
      (tester) async {
    await _pumpLuma(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final container = ProviderScope.containerOf(tester.element(find.byType(LumaCompanion)));
    container.read(moodThemeProvider.notifier).state = AppMood.tired;

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450)); // AnimatedSwitcher crossfade

    expect(find.text(l10n.lumaMoodAckTired), findsOneWidget);
  });

  testWidgets('renders without throwing for every mood (particles + glow)', (tester) async {
    await _pumpLuma(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(LumaCompanion)));

    for (final mood in AppMood.values) {
      container.read(moodThemeProvider.notifier).state = mood;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'mood: $mood');
    }
  });

  testWidgets(
      'rapid sad/not-sad toggling never issues more than one overlapping play call',
      (tester) async {
    final fake = _FakeAudioPlayer();
    debugRainPlayerFactory = () => fake;

    await _pumpLuma(tester);
    await tester.pump(const Duration(milliseconds: 50)); // let prefs load resolve

    final container = ProviderScope.containerOf(tester.element(find.byType(LumaCompanion)));

    // Flip in and out of "sad" quickly, always well before the 900ms
    // fade-out could ever reach silence, so the loop should never be told
    // to stop-and-restart mid-flight (each brief reverse only nudges the
    // fade down a little before the next forward interrupts it again).
    for (var i = 0; i < 6; i++) {
      container.read(moodThemeProvider.notifier).state = AppMood.sad;
      await _pumpFrames(tester, const Duration(milliseconds: 400));
      container.read(moodThemeProvider.notifier).state = AppMood.happy;
      await _pumpFrames(tester, const Duration(milliseconds: 50));
    }

    expect(tester.takeException(), isNull);
    // A single underlying loop the whole time: play() only fires once,
    // never once per toggle — i.e. never stacked/overlapping instances.
    expect(fake.playCalls, 1);
    expect(fake.pauseCalls, 0); // fade-out never got the chance to finish
  });

  testWidgets('sad mood cleanly restarts the loop after a full fade-out completes',
      (tester) async {
    final fake = _FakeAudioPlayer();
    debugRainPlayerFactory = () => fake;

    await _pumpLuma(tester);
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(tester.element(find.byType(LumaCompanion)));

    for (var i = 0; i < 3; i++) {
      container.read(moodThemeProvider.notifier).state = AppMood.sad;
      await _pumpFrames(tester, const Duration(milliseconds: 1000)); // fade-in completes
      container.read(moodThemeProvider.notifier).state = AppMood.calm;
      await _pumpFrames(tester, const Duration(milliseconds: 1000)); // fade-out completes -> pause
    }

    expect(tester.takeException(), isNull);
    // Every play is paired with exactly one pause before the next play —
    // i.e. the loop is always fully stopped before it is ever restarted.
    expect(fake.playCalls, 3);
    expect(fake.pauseCalls, 3);
  });

  testWidgets('sound toggle mutes rain, persists the preference, and stops playback',
      (tester) async {
    final fake = _FakeAudioPlayer();
    debugRainPlayerFactory = () => fake;

    await _pumpLuma(tester);
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(tester.element(find.byType(LumaCompanion)));
    container.read(moodThemeProvider.notifier).state = AppMood.sad;
    await _pumpFrames(tester, const Duration(milliseconds: 1000));
    expect(fake.playCalls, 1);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await _pumpFrames(tester, const Duration(milliseconds: 1000));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    expect(fake.pauseCalls, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('luma_ambient_sound_muted'), isTrue);
  });
}
