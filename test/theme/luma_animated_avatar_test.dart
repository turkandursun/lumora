import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/theme/luma_animated_avatar.dart';

void main() {
  test('ambient sequences and timing are stable', () {
    expect(
      LumaAnimatedAvatar.waveOrder,
      <int>[0, 1, 2, 3, 4, 3, 2, 1, 0],
    );
    expect(
      LumaAnimatedAvatar.blinkOrder,
      <int>[0, 1, 2, 2, 2, 3, 4],
    );
    expect(
      LumaAnimatedAvatar.happyOrder,
      <int>[0, 1, 2, 3, 4, 3, 2, 1, 0],
    );
    expect(
      LumaAnimatedAvatar.ambientPauses,
      const <Duration>[
        Duration(milliseconds: 2600),
        Duration(milliseconds: 2500),
        Duration(milliseconds: 4000),
      ],
    );
  });

  test('speaking alternates wave and speak without blink or happy', () {
    final speakingAssets = <String>{
      ...LumaAnimatedAvatar.waveFrames,
      ...LumaAnimatedAvatar.speakFrames,
    };
    expect(
      speakingAssets.intersection(LumaAnimatedAvatar.blinkFrames.toSet()),
      isEmpty,
    );
    expect(
      speakingAssets.intersection(LumaAnimatedAvatar.happyFrames.toSet()),
      isEmpty,
    );
    expect(
      LumaAnimatedAvatar.speakFrames,
      <String>[
        'assets/images/luma/speak/speak_1.png',
        'assets/images/luma/speak/speak_2.png',
        'assets/images/luma/speak/speak_3.png',
        'assets/images/luma/speak/speak_4.png',
        'assets/images/luma/speak/speak_5.png',
      ],
    );
    expect(
      LumaAnimatedAvatar.speakFrameDuration,
      const Duration(milliseconds: 130),
    );
  });

  testWidgets('ambient starts idle on wave_1 in a stable square',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: LumaAnimatedAvatar(size: 96)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/images/luma/wave/wave_1.png');
    expect(image.fit, BoxFit.contain);
    expect(image.gaplessPlayback, isTrue);
    expect(
      tester.getSize(find.byType(LumaAnimatedAvatar)),
      const Size(96, 96),
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('speaking starts on wave_1 and returns to ambient base',
      (tester) async {
    var mode = LumaAnimationMode.speaking;
    late StateSetter setHostState;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return LumaAnimatedAvatar(size: 100, mode: mode);
          },
        ),
      ),
    );

    AssetImage currentAsset() =>
        tester.widget<Image>(find.byType(Image).first).image as AssetImage;

    expect(
      currentAsset().assetName,
      'assets/images/luma/wave/wave_1.png',
    );

    setHostState(() => mode = LumaAnimationMode.ambient);
    await tester.pump();

    expect(
      currentAsset().assetName,
      'assets/images/luma/wave/wave_1.png',
    );
    await tester.pumpWidget(const SizedBox());
  });
}
