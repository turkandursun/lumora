import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';

void main() {
  test('26 to 27 creates special days without deleting existing data',
      () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE retained_data (
              id INTEGER NOT NULL PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          raw.execute("INSERT INTO retained_data (id, value) VALUES (1, 'ok')");
          raw.execute('PRAGMA user_version = 26');
        },
      ),
    );
    addTearDown(database.close);

    expect(database.schemaVersion, 27);
    final retained =
        await database.customSelect('SELECT * FROM retained_data').getSingle();
    expect(retained.read<String>('value'), 'ok');
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'special_days'",
        )
        .get();
    expect(tables, hasLength(1));
  });
}
