import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';

void main() {
  test('23 to 24 migration adds focus sessions without touching existing data',
      () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase.execute(
            'CREATE TABLE legacy_data (id INTEGER PRIMARY KEY, value TEXT)',
          );
          rawDatabase.execute(
            "INSERT INTO legacy_data (id, value) VALUES (1, 'keep')",
          );
          rawDatabase.execute('PRAGMA user_version = 23');
        },
      ),
    );
    addTearDown(database.close);

    await database.into(database.focusSessions).insert(
          FocusSessionsCompanion.insert(
            sessionUuid: 'focus-id',
            userId: 'user-a',
            plannedDurationSeconds: 1500,
            actualDurationSeconds: 1500,
            startedAt: DateTime.utc(2026, 8, 19, 10),
            endedAt: DateTime.utc(2026, 8, 19, 10, 25),
          ),
        );

    final legacy =
        await database.customSelect('SELECT * FROM legacy_data').get();
    expect(legacy.single.data['value'], 'keep');
    expect(await database.select(database.focusSessions).get(), hasLength(1));

    await expectLater(
      database.into(database.focusSessions).insert(
            FocusSessionsCompanion.insert(
              sessionUuid: 'focus-id',
              userId: 'user-a',
              plannedDurationSeconds: 60,
              actualDurationSeconds: 60,
              startedAt: DateTime.utc(2026, 8, 19, 11),
              endedAt: DateTime.utc(2026, 8, 19, 11, 1),
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
