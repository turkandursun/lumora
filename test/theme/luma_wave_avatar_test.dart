import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/theme/luma_wave_avatar.dart';

void main() {
  test('uses the expected forward and reverse wave sequence', () {
    expect(
      LumaWaveAvatar.waveFrameOrder,
      <int>[0, 1, 2, 3, 4, 3, 2, 1, 0],
    );
    expect(
      LumaWaveAvatar.frameAssets,
      <String>[
        'assets/images/luma/wave/wave_1.png',
        'assets/images/luma/wave/wave_2.png',
        'assets/images/luma/wave/wave_3.png',
        'assets/images/luma/wave/wave_4.png',
        'assets/images/luma/wave/wave_5.png',
      ],
    );
    expect(
      LumaWaveAvatar.frameDuration,
      const Duration(milliseconds: 120),
    );
    expect(
      LumaWaveAvatar.idleInterval,
      const Duration(milliseconds: 5500),
    );
  });

  testWidgets('starts idle on wave_1 in a stable square layout',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(child: LumaWaveAvatar(size: 96)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/images/luma/wave/wave_1.png');
    expect(image.fit, BoxFit.contain);
    expect(image.gaplessPlayback, isTrue);
    expect(tester.getSize(find.byType(LumaWaveAvatar)), const Size(96, 96));
  });
}
