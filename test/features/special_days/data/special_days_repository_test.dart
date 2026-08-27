import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/sync/user_content_sync.dart';
import 'package:mindful_journal/features/special_days/data/special_day.dart';
import 'package:mindful_journal/features/special_days/data/special_days_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_user_content_remote_data_source.dart';

void main() {
  late AppDatabase database;
  late FakeUserContentRemoteDataSource remote;
  late SpecialDaysRepository repository;
  late int uuidSequence;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeUserContentRemoteDataSource()..online = false;
    uuidSequence = 1;
    repository = SpecialDaysRepository(
      database: database,
      remoteDataSource: remote,
      uuidGenerator: () =>
          '00000000-0000-4000-8000-${(uuidSequence++).toString().padLeft(12, '0')}',
    );
  });

  tearDown(() => database.close());

  test('offline create remains visible and retries idempotently', () async {
    final created = await repository.create(
      title: 'Wedding',
      dayType: SpecialDay.kindWedding,
      eventDate: DateTime(2026, 5, 15, 23, 45),
      repeatsAnnually: true,
    );
    await _settle();

    final local = await database.select(database.specialDays).getSingle();
    expect(local.syncState, contentSyncPendingUpsert);
    expect((await repository.load()).single.id, created.id);

    remote.online = true;
    await repository.syncForCurrentUser();
    await repository.syncForCurrentUser();
    expect(remote.table('special_days'), hasLength(1));
    expect(
      remote.table('special_days').values.single['event_date'],
      '2026-05-15',
    );
    expect(
      (await database.select(database.specialDays).getSingle()).syncState,
      contentSyncSynced,
    );
  });

  test('birthday update keeps one stable row and one cloud identity', () async {
    final first = await repository.setBirthday(
      eventDate: DateTime(1995, 2, 3),
      title: 'My birthday',
    );
    final updated = await repository.setBirthday(
      eventDate: DateTime(1995, 2, 4),
      title: 'My birthday',
    );

    expect(updated.id, first.id);
    final local = await database.select(database.specialDays).get();
    expect(local, hasLength(1));
    expect(local.single.eventDate, DateTime(1995, 2, 4));

    remote.online = true;
    await repository.syncForCurrentUser();
    expect(remote.table('special_days'), hasLength(1));
    expect(
      remote.table('special_days').values.single['event_date'],
      '1995-02-04',
    );
  });

  test('custom and wedding records are independent', () async {
    await repository.create(
      title: 'A custom day',
      dayType: SpecialDay.kindCustom,
      eventDate: DateTime(2026, 6, 1),
      repeatsAnnually: false,
    );
    await repository.create(
      title: 'Wedding',
      dayType: SpecialDay.kindWedding,
      eventDate: DateTime(2020, 7, 2),
      repeatsAnnually: true,
    );

    final days = await repository.load();
    expect(days, hasLength(2));
    expect(
        days.map((day) => day.kind),
        containsAll([
          SpecialDay.kindCustom,
          SpecialDay.kindWedding,
        ]));
  });

  test('offline edit and delete use pending upsert and tombstone', () async {
    remote.online = true;
    final created = await repository.create(
      title: 'Anniversary',
      dayType: SpecialDay.kindAnniversary,
      eventDate: DateTime(2020, 8, 1),
      repeatsAnnually: true,
    );
    await repository.syncForCurrentUser();
    remote.online = false;

    await repository.update(created.copyWith(title: 'Updated anniversary'));
    await _settle();
    expect(
      (await database.select(database.specialDays).getSingle()).syncState,
      contentSyncPendingUpsert,
    );

    await repository.delete(created.id);
    await _settle();
    expect(await repository.load(), isEmpty);
    expect(
      (await database.select(database.specialDays).getSingle()).syncState,
      contentSyncPendingDelete,
    );

    remote.online = true;
    await repository.syncForCurrentUser();
    expect(await database.select(database.specialDays).get(), isEmpty);
    expect(remote.table('special_days'), isEmpty);
  });

  test('account switch never exposes another account local rows', () async {
    await repository.create(
      title: 'A day',
      dayType: SpecialDay.kindCustom,
      eventDate: DateTime(2026, 8, 21),
      repeatsAnnually: true,
    );
    remote.currentUserId = 'user-b';
    expect(await repository.load(), isEmpty);

    await repository.create(
      title: 'B day',
      dayType: SpecialDay.kindCustom,
      eventDate: DateTime(2026, 8, 22),
      repeatsAnnually: true,
    );
    expect((await repository.load()).single.title, 'B day');
    remote.currentUserId = 'user-a';
    expect((await repository.load()).single.title, 'A day');
  });

  test('late user A cloud response cannot alter user B state', () async {
    remote.online = true;
    remote.upsertGate = Completer<void>();
    await repository.create(
      title: 'A day',
      dayType: SpecialDay.kindCustom,
      eventDate: DateTime(2026, 8, 21),
      repeatsAnnually: true,
    );
    await remote.upsertObserved.future;

    remote.currentUserId = 'user-b';
    remote.upsertGate!.complete();
    await repository.syncForCurrentUser();

    expect(await repository.load(), isEmpty);
    final bRows = await (database.select(database.specialDays)
          ..where((table) => table.userId.equals('user-b')))
        .get();
    expect(bRows, isEmpty);
  });

  test('ownerless global v1 list is never claimed by current account',
      () async {
    SharedPreferences.setMockInitialValues({
      'special_days_v1': <String>[
        jsonEncode({
          'id': 'legacy',
          'title': 'Unknown owner',
          'month': 5,
          'day': 15,
          'kind': 'custom',
        }),
      ],
    });
    expect(await repository.load(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get('special_days_v1'), isNull);
  });

  test('calendar date serialization never shifts through UTC', () {
    final localDate = DateTime(2026, 5, 15, 0, 5);
    expect(formatSpecialDayDate(localDate), '2026-05-15');
    expect(parseSpecialDayDate('2026-05-15'), DateTime(2026, 5, 15));
    expect(parseSpecialDayDate('2026-02-30'), isNull);
  });

  test('29 February annual occurrence advances to the next leap year', () {
    const day = SpecialDay(
      id: 'leap',
      title: 'Leap day',
      month: 2,
      day: 29,
      year: 2024,
    );
    expect(
      SpecialDayNotifications.nextOccurrenceForTesting(
        day,
        DateTime(2025, 3, 1),
      ),
      DateTime(2028, 2, 29, 9),
    );
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
