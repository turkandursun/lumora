import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/calendar/data/period_repository.dart';
import 'package:mindful_journal/features/calendar/data/symptom_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'period_days_v1': <String>['2026-08-01T00:00:00.000'],
      'period_symptoms_v1': <String>['2026-08-01:legacy'],
    });
  });

  test('unauthenticated repositories neither read nor write account data',
      () async {
    final periods = PeriodRepository(userId: null);
    final symptoms = SymptomRepository(userId: null);

    expect(await periods.load(), isEmpty);
    expect(await symptoms.load(), isEmpty);

    await periods.save({DateTime(2026, 8, 20)});
    await symptoms.save({
      DateTime(2026, 8, 20): {'cramps'},
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), containsAll(['period_days_v1', 'period_symptoms_v1']));
    expect(prefs.getKeys().where((key) => key.contains('_v2_')), isEmpty);
  });

  test('period days are isolated by user and restored on re-login', () async {
    final userA = PeriodRepository(userId: 'user-a');
    final userB = PeriodRepository(userId: 'user-b');
    final day = DateTime(2026, 8, 20, 17, 45);

    await userA.save({day});

    expect(await userB.load(), isEmpty);
    expect(
      await PeriodRepository(userId: 'user-a').load(),
      {DateTime(2026, 8, 20)},
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(periodDaysStorageKey('user-b')), isNull);
    expect(prefs.getStringList('period_days_v1'), isNotNull);
  });

  test('symptoms are isolated by user and restored on re-login', () async {
    final userA = SymptomRepository(userId: 'user-a');
    final userB = SymptomRepository(userId: 'user-b');
    final day = DateTime(2026, 8, 20, 17, 45);

    await userA.save({
      day: {'cramps', 'headache'},
    });

    expect(await userB.load(), isEmpty);
    expect(
      await SymptomRepository(userId: 'user-a').load(),
      {
        DateTime(2026, 8, 20): {'cramps', 'headache'},
      },
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(periodSymptomsStorageKey('user-b')), isNull);
    expect(prefs.getStringList('period_symptoms_v1'), isNotNull);
  });
}
