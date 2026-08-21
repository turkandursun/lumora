import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/profile/presentation/providers/visit_tracker_providers.dart';

void main() {
  test('banner gate claims once per user for one app process', () {
    final gate = StreakBannerLaunchGate();

    expect(gate.claim('user-a'), isTrue);
    expect(gate.claim('user-a'), isFalse);
    expect(gate.claim('user-b'), isTrue);
  });

  test('a new app process gate permits the banner again', () {
    final firstLaunch = StreakBannerLaunchGate();
    final nextColdLaunch = StreakBannerLaunchGate();

    expect(firstLaunch.claim('user-a'), isTrue);
    expect(firstLaunch.claim('user-a'), isFalse);
    expect(nextColdLaunch.claim('user-a'), isTrue);
  });
}
