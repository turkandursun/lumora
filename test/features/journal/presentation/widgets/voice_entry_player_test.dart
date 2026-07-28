import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/journal/presentation/widgets/voice_entry_player.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';

/// Records play/pause/seek calls and lets tests drive the position/duration
/// streams directly, instead of touching real platform audio channels —
/// same approach as `_FakeAudioPlayer` in luma_companion_test.dart.
class _FakeAudioPlayer extends AudioPlayer {
  _FakeAudioPlayer({this.throwOnPlay = false});

  final bool throwOnPlay;
  int playCalls = 0;
  int pauseCalls = 0;
  Duration? lastSeek;

  final _durationController = StreamController<Duration>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _completeController = StreamController<void>.broadcast();

  @override
  Stream<Duration> get onDurationChanged => _durationController.stream;

  @override
  Stream<Duration> get onPositionChanged => _positionController.stream;

  @override
  Stream<void> get onPlayerComplete => _completeController.stream;

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
    if (throwOnPlay) {
      throw PlatformException(code: 'missing', message: 'file not found');
    }
    _durationController.add(const Duration(seconds: 30));
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
    _positionController.add(position);
  }

  @override
  Future<void> dispose() async {
    await _durationController.close();
    await _positionController.close();
    await _completeController.close();
  }
}

Future<void> _pumpPlayer(WidgetTester tester, String audioPath) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: VoiceEntryPlayer(audioPath: audioPath)),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(() {
    debugVoiceEntryPlayerFactory = null;
  });

  testWidgets('tapping play starts playback and swaps the icon to pause', (tester) async {
    final fake = _FakeAudioPlayer();
    debugVoiceEntryPlayerFactory = () => fake;

    await _pumpPlayer(tester, '/tmp/voice_notes/entry_1.m4a');

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(fake.playCalls, 1);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('tapping pause while playing pauses the underlying player', (tester) async {
    final fake = _FakeAudioPlayer();
    debugVoiceEntryPlayerFactory = () => fake;

    await _pumpPlayer(tester, '/tmp/voice_notes/entry_1.m4a');
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();

    expect(fake.pauseCalls, 1);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('a missing/corrupted audio file shows the fallback message instead of crashing',
      (tester) async {
    final fake = _FakeAudioPlayer(throwOnPlay: true);
    debugVoiceEntryPlayerFactory = () => fake;

    await _pumpPlayer(tester, '/tmp/voice_notes/missing.m4a');
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.voiceNoteFileMissing), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting playback on one player pauses a previously playing one', (tester) async {
    final fakeA = _FakeAudioPlayer();
    final fakeB = _FakeAudioPlayer();
    final players = [fakeA, fakeB];
    var call = 0;
    debugVoiceEntryPlayerFactory = () => players[call++];

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              VoiceEntryPlayer(audioPath: '/tmp/voice_notes/entry_a.m4a'),
              VoiceEntryPlayer(audioPath: '/tmp/voice_notes/entry_b.m4a'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final playButtons = find.byIcon(Icons.play_arrow_rounded);
    expect(playButtons, findsNWidgets(2));

    await tester.tap(playButtons.first);
    await tester.pump();
    expect(fakeA.playCalls, 1);
    expect(fakeA.pauseCalls, 0);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded)); // now B's play button
    await tester.pump();

    expect(fakeB.playCalls, 1);
    expect(fakeA.pauseCalls, 1, reason: 'starting B should silently pause A');
  });
}
