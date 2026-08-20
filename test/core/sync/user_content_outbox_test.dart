import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/sync/user_content_sync.dart';
import 'package:mindful_journal/features/activities/data/activity_repository.dart';
import 'package:mindful_journal/features/dreams/data/dreams_repository.dart';
import 'package:mindful_journal/features/letters/data/letter_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_user_content_remote_data_source.dart';

void main() {
  group('dream outbox', () {
    late AppDatabase database;
    late FakeUserContentRemoteDataSource remote;
    late DreamsRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      remote = FakeUserContentRemoteDataSource()..online = false;
      repository = DreamsRepository(
        database: database,
        remoteDataSource: remote,
        uuidGenerator: () => '00000000-0000-4000-8000-000000000101',
      );
    });
    tearDown(() => database.close());

    test('offline create and reflection update retry without duplicates',
        () async {
      final localId = await repository.addDream('Flying over water');
      await _settle();
      await repository.saveReflection(id: localId, feelingTag: 'peaceful');
      await _settle();
      expect(
        (await database.select(database.dreams).getSingle()).syncState,
        contentSyncPendingUpsert,
      );

      remote.online = true;
      await repository.syncForCurrentUser();
      await repository.syncForCurrentUser();
      expect(remote.table('dreams'), hasLength(1));
      expect(remote.table('dreams').values.single['feeling_tag'], 'peaceful');
    });

    test('offline tombstone is hidden and wins over cloud pull', () async {
      remote.online = true;
      final id = await repository.addDream('A dream');
      await repository.syncForCurrentUser();
      final row = await database.select(database.dreams).getSingle();
      remote.online = false;
      await repository.deleteDream(id, supabaseId: row.supabaseId);
      await _settle();
      expect(await repository.watchAll().first, isEmpty);
      expect(
        (await database.select(database.dreams).getSingle()).syncState,
        contentSyncPendingDelete,
      );
      remote.online = true;
      await repository.syncForCurrentUser();
      expect(await database.select(database.dreams).get(), isEmpty);
      expect(remote.table('dreams'), isEmpty);
    });
  });

  group('activity outbox', () {
    late AppDatabase database;
    late SupabaseClient client;
    late FakeUserContentRemoteDataSource remote;
    late ActivityRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      client = SupabaseClient('http://localhost:54321', 'test-anon-key');
      remote = FakeUserContentRemoteDataSource()..online = false;
      repository = ActivityRepository(
        database: database,
        supabaseClient: client,
        remoteDataSource: remote,
        uuidGenerator: () => '00000000-0000-4000-8000-000000000201',
      );
    });
    tearDown(() async {
      await database.close();
      client.dispose();
    });

    test('offline create and update stay scoped then retry idempotently',
        () async {
      await repository.add(
        Activity(
          createdAt: DateTime.utc(2026, 8, 20, 12),
          activityIds: const ['reading'],
          text: 'Read',
        ),
      );
      await _settle();
      var activity = (await repository.load()).single;
      await repository.update(
        Activity(
          id: activity.id,
          createdAt: activity.createdAt,
          activityIds: const ['reading'],
          text: 'Read and noted',
        ),
      );
      await _settle();
      remote.online = true;
      await repository.syncForCurrentUser();
      await repository.syncForCurrentUser();
      expect(remote.table('activities'), hasLength(1));
      expect(
          remote.table('activities').values.single['text'], 'Read and noted');

      remote.currentUserId = 'user-b';
      expect(await repository.load(), isEmpty);
      remote.currentUserId = 'user-a';
      activity = (await repository.load()).single;
      expect(activity.text, 'Read and noted');
    });

    test('offline activity delete remains a tombstone until retry', () async {
      remote.online = true;
      await repository.add(
        Activity(
          createdAt: DateTime.utc(2026, 8, 20, 12),
          text: 'Walk',
        ),
      );
      await repository.syncForCurrentUser();
      final row = await database.select(database.activities).getSingle();
      remote.online = false;
      await repository.delete(row.id, supabaseId: row.supabaseId);
      await _settle();
      expect(await repository.load(), isEmpty);
      expect(
        (await database.select(database.activities).getSingle()).syncState,
        contentSyncPendingDelete,
      );
      remote.online = true;
      await repository.syncForCurrentUser();
      expect(await database.select(database.activities).get(), isEmpty);
    });
  });

  group('letter outbox', () {
    late AppDatabase database;
    late FakeUserContentRemoteDataSource remote;
    late LetterRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      remote = FakeUserContentRemoteDataSource()..online = false;
      repository = LetterRepository(
        database: database,
        remoteDataSource: remote,
        uuidGenerator: () => '00000000-0000-4000-8000-000000000301',
      );
    });
    tearDown(() => database.close());

    test('offline create and update retry to one cloud letter', () async {
      await repository.save(
        title: 'Future',
        body: 'First body',
        openAt: DateTime.utc(2027, 8, 20),
      );
      await _settle();
      final letter = (await repository.load()).single;
      await repository.update(
        localId: letter.id,
        title: 'Future',
        body: 'Latest body',
        openAt: letter.openAt,
      );
      await _settle();
      remote.online = true;
      await repository.syncForCurrentUser();
      await repository.syncForCurrentUser();
      expect(remote.table('letters'), hasLength(1));
      expect(remote.table('letters').values.single['body'], 'Latest body');
    });

    test('offline letter delete is hidden and eventually removed', () async {
      remote.online = true;
      await repository.save(
        title: 'Future',
        body: 'Body',
        openAt: DateTime.utc(2027, 8, 20),
      );
      await repository.syncForCurrentUser();
      final row = await database.select(database.letters).getSingle();
      remote.online = false;
      await repository.delete(row.id, supabaseId: row.supabaseId);
      await _settle();
      expect(await repository.load(), isEmpty);
      expect(
        (await database.select(database.letters).getSingle()).syncState,
        contentSyncPendingDelete,
      );
      remote.online = true;
      await repository.syncForCurrentUser();
      expect(await database.select(database.letters).get(), isEmpty);
    });
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
