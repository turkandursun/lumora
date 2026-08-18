import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/mood/data/mood_log_repository.dart';

void main() {
  test('daily mood gate uses the device-local calendar day', () {
    final log = <DateTime, int>{DateTime(2026, 8, 17): 2};
    expect(
      MoodLogRepository.containsMoodForDay(
        log,
        DateTime(2026, 8, 17, 23, 59),
      ),
      isTrue,
    );
    expect(
      MoodLogRepository.containsMoodForDay(
        log,
        DateTime(2026, 8, 18),
      ),
      isFalse,
    );
  });

  test('mood local cache key is account-scoped', () {
    expect(MoodLogRepository.keyForUser('user-a'), 'mood_log_v2_user-a');
    expect(
      MoodLogRepository.keyForUser('user-a'),
      isNot(MoodLogRepository.keyForUser('user-b')),
    );
  });
}
