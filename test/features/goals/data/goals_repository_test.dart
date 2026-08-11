import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/database/app_database.dart';
import 'package:mindful_journal/core/database/tables/goals_table.dart';
import 'package:mindful_journal/features/goals/data/goals_repository.dart';
import 'package:mindful_journal/features/goals/domain/goal_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late _FakeGoalsRemoteDataSource remote;
  late GoalsRepository repository;
  late int uuidCounter;
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    remote = _FakeGoalsRemoteDataSource()..currentUserId = 'user-a';
    uuidCounter = 0;
    now = DateTime(2026, 8, 11, 12);
    repository = GoalsRepository(
      database: database,
      remoteDataSource: remote,
      uuidGenerator: () {
        uuidCounter++;
        return '00000000-0000-4000-8000-${uuidCounter.toString().padLeft(12, '0')}';
      },
      clock: () => now,
    );
  });

  tearDown(() async {
    await repository.syncForCurrentUser();
    await database.close();
  });

  test('offline create is immediately visible as a local pending goal',
      () async {
    remote.failUpserts = true;

    await repository.addCustomGoal(
      title: 'Offline goal',
      unit: GoalUnit.pages,
      target: 20,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();

    final rows = await database.select(database.goals).get();
    expect(rows, hasLength(1));
    expect(rows.single.userId, 'user-a');
    expect(rows.single.supabaseId, isNotNull);
    expect(rows.single.status, 'active');
    expect(rows.single.syncState, 'pending');
    expect(remote.cloud, isEmpty);
  });

  test('sync retries the same UUID without creating a duplicate', () async {
    await repository.addCustomGoal(
      title: 'Synced goal',
      unit: GoalUnit.books,
      target: 4,
      frequency: GoalFrequency.monthly,
    );
    await repository.syncForCurrentUser();

    final firstRows = await database.select(database.goals).get();
    final remoteId = firstRows.single.supabaseId;
    expect(firstRows.single.syncState, 'synced');
    expect(remote.cloud.keys, [remoteId]);

    await repository.syncForCurrentUser();

    final secondRows = await database.select(database.goals).get();
    expect(secondRows, hasLength(1));
    expect(secondRows.single.supabaseId, remoteId);
    expect(remote.cloud, hasLength(1));
  });

  test('legacy pending goal receives one stable UUID across retries', () async {
    remote.failUpserts = true;
    await database.into(database.goals).insert(
          GoalsCompanion.insert(
            title: 'Legacy local goal',
            iconKey: 'custom',
            unit: GoalUnit.custom,
            target: 3,
            frequency: GoalFrequency.weekly,
            periodStart: DateTime(2026, 8, 10),
            userId: const Value('user-a'),
            syncState: const Value('pending'),
          ),
        );

    await repository.syncForCurrentUser();
    final first = await database.select(database.goals).getSingle();
    expect(first.supabaseId, isNotNull);

    await repository.syncForCurrentUser();
    final second = await database.select(database.goals).getSingle();
    expect(second.supabaseId, first.supabaseId);
    expect(uuidCounter, 1);
  });

  test('cloud pull never overwrites a local pending change', () async {
    remote.failUpserts = true;
    await repository.addCustomGoal(
      title: 'Local intent',
      unit: GoalUnit.minutes,
      target: 15,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();
    final local = await database.select(database.goals).getSingle();

    remote.cloud[local.supabaseId!] = _cloudGoal(
      id: local.supabaseId!,
      userId: 'user-a',
      title: 'Older cloud value',
      progress: 0,
    );

    await repository.syncForCurrentUser();

    final afterPull = await database.select(database.goals).getSingle();
    expect(afterPull.title, 'Local intent');
    expect(afterPull.syncState, 'pending');
  });

  test('account A pending goal is never pushed while account B is active',
      () async {
    remote.failUpserts = true;
    await repository.addCustomGoal(
      title: 'A pending',
      unit: GoalUnit.pages,
      target: 10,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();

    remote.attemptedPayloads.clear();
    remote.failUpserts = false;
    remote.currentUserId = 'user-b';
    await repository.syncForCurrentUser();

    expect(remote.attemptedPayloads, isEmpty);
    final aRows = await (database.select(database.goals)
          ..where((table) => table.userId.equals('user-a')))
        .get();
    final bRows = await (database.select(database.goals)
          ..where((table) => table.userId.equals('user-b')))
        .get();
    expect(aRows.single.syncState, 'pending');
    expect(bRows, isEmpty);
  });

  test('auth null blocks create and sync mutations', () async {
    remote.currentUserId = null;

    await repository.addCustomGoal(
      title: 'Must not be created',
      unit: GoalUnit.pages,
      target: 10,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();

    expect(await database.select(database.goals).get(), isEmpty);
    expect(remote.attemptedPayloads, isEmpty);
  });

  test('progress update is current-user scoped and remains pending offline',
      () async {
    remote.failUpserts = true;
    await database.into(database.goals).insert(
          GoalsCompanion.insert(
            title: 'User A goal',
            iconKey: 'custom',
            unit: GoalUnit.pages,
            target: 20,
            frequency: GoalFrequency.daily,
            periodStart: DateTime(2026, 8, 11),
            userId: const Value('user-a'),
            supabaseId: const Value(
              '20000000-0000-4000-8000-000000000001',
            ),
          ),
        );
    await database.into(database.goals).insert(
          GoalsCompanion.insert(
            title: 'User B goal',
            iconKey: 'custom',
            unit: GoalUnit.pages,
            target: 20,
            frequency: GoalFrequency.daily,
            periodStart: DateTime(2026, 8, 11),
            userId: const Value('user-b'),
            supabaseId: const Value(
              '20000000-0000-4000-8000-000000000002',
            ),
          ),
        );
    final rows = await database.select(database.goals).get();
    final userAGoal = rows.singleWhere((row) => row.userId == 'user-a');
    final userBGoal = rows.singleWhere((row) => row.userId == 'user-b');

    expect(await repository.incrementProgress(userBGoal, 10), isFalse);
    expect(await repository.incrementProgress(userAGoal, 10), isFalse);
    await repository.syncForCurrentUser();

    final updated = await database.select(database.goals).get();
    final updatedA = updated.singleWhere((row) => row.userId == 'user-a');
    final untouchedB = updated.singleWhere((row) => row.userId == 'user-b');
    expect(updatedA.progress, 10);
    expect(updatedA.syncState, 'pending');
    expect(untouchedB.progress, 0);
    expect(untouchedB.syncState, 'synced');
  });

  test('cloud pull updates an existing synced Drift row', () async {
    const remoteId = '10000000-0000-4000-8000-000000000001';
    await database.into(database.goals).insert(
          GoalsCompanion.insert(
            title: 'Old local title',
            iconKey: 'custom',
            unit: GoalUnit.minutes,
            target: 10,
            progress: const Value(2),
            frequency: GoalFrequency.daily,
            periodStart: DateTime.utc(2026, 8, 11),
            userId: const Value('user-a'),
            supabaseId: const Value(remoteId),
            status: const Value('active'),
            syncState: const Value('synced'),
          ),
        );
    remote.cloud[remoteId] = _cloudGoal(
      id: remoteId,
      userId: 'user-a',
      title: 'Cloud title',
      templateKey: 'meditation',
      progress: 5,
    );

    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(row.title, 'Cloud title');
    expect(row.templateKey, 'meditation');
    expect(row.progress, 5);
    expect(row.syncState, 'synced');
    expect(row.cloudUpdatedAt, isNotNull);
    expect(row.lastSyncedAt, isNotNull);
  });

  test('archive is local-first and converges to cloud archived status',
      () async {
    await repository.addCustomGoal(
      title: 'Archive me',
      unit: GoalUnit.custom,
      target: 1,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();
    final created = await database.select(database.goals).getSingle();

    await repository.archiveGoal(created.id);
    await repository.syncForCurrentUser();

    final archived = await database.select(database.goals).getSingle();
    expect(archived.status, 'archived');
    expect(archived.syncState, 'synced');
    expect(remote.cloud[archived.supabaseId]!['status'], 'archived');
    expect(await repository.watchAll().first, isEmpty);
    expect(
      await repository.watchArchivedGoalsForCurrentUser().first,
      hasLength(1),
    );
  });

  test('legacy local starter adopts the matching cloud template UUID',
      () async {
    const cloudId = '30000000-0000-4000-8000-000000000001';
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '30000000-0000-4000-8000-000000000002',
      progress: 2,
      target: 8,
      unit: GoalUnit.glasses,
    );
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Water',
      templateKey: 'water',
      target: 8,
      progress: 2,
      unit: 'glasses',
    );

    await repository.syncForCurrentUser();

    final rows = await database.select(database.goals).get();
    expect(rows, hasLength(1));
    expect(rows.single.supabaseId, cloudId);
    expect(rows.single.templateKey, 'water');
    expect(rows.single.syncState, 'synced');
    expect(remote.cloud, hasLength(1));
  });

  test('higher local pending progress survives cloud UUID adoption', () async {
    const cloudId = '31000000-0000-4000-8000-000000000001';
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '31000000-0000-4000-8000-000000000002',
      progress: 7,
      target: 8,
      unit: GoalUnit.glasses,
    );
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Water',
      templateKey: 'water',
      target: 8,
      progress: 3,
      unit: 'glasses',
    );

    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(row.supabaseId, cloudId);
    expect(row.progress, 7);
    expect(remote.cloud[cloudId]!['progress'], 7);
  });

  test('higher cloud progress wins within the same period', () async {
    const cloudId = '32000000-0000-4000-8000-000000000001';
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '32000000-0000-4000-8000-000000000002',
      progress: 2,
      target: 8,
      unit: GoalUnit.glasses,
    );
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Water',
      templateKey: 'water',
      target: 8,
      progress: 6,
      unit: 'glasses',
    );

    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(row.supabaseId, cloudId);
    expect(row.progress, 6);
    expect(row.syncState, 'synced');
  });

  test('newer period wins without carrying older progress', () async {
    const cloudId = '33000000-0000-4000-8000-000000000001';
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '33000000-0000-4000-8000-000000000002',
      progress: 7,
      target: 8,
      unit: GoalUnit.glasses,
      periodStart: DateTime(2026, 8, 10),
    );
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Water',
      templateKey: 'water',
      target: 8,
      progress: 1,
      unit: 'glasses',
      periodStart: DateTime.utc(2026, 8, 11),
    );

    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(row.progress, 1);
    expect(row.periodStart.day, 11);
  });

  test('five local duplicates collapse to one active goal and create index',
      () async {
    for (var index = 0; index < 5; index++) {
      await _insertLocalTemplate(
        database,
        templateKey: 'water',
        remoteId:
            '34000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
        progress: index,
        target: 8,
        unit: GoalUnit.glasses,
      );
    }

    await repository.syncForCurrentUser();

    final rows = await database.select(database.goals).get();
    expect(rows, hasLength(1));
    expect(rows.single.progress, 4);

    await expectLater(
      database.into(database.goals).insert(
            GoalsCompanion.insert(
              title: 'Duplicate after index',
              iconKey: 'water',
              unit: GoalUnit.glasses,
              target: 8,
              frequency: GoalFrequency.daily,
              periodStart: DateTime(2026, 8, 11),
              userId: const Value('user-a'),
              supabaseId: const Value(
                '34000000-0000-4000-8000-000000000999',
              ),
              templateKey: const Value('water'),
              status: const Value('active'),
              syncState: const Value('pending'),
            ),
          ),
      throwsA(anything),
    );
  });

  test('duplicate cleanup preserves a customized target', () async {
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '34500000-0000-4000-8000-000000000001',
      progress: 3,
      target: 8,
      unit: GoalUnit.glasses,
    );
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '34500000-0000-4000-8000-000000000002',
      progress: 2,
      target: 12,
      unit: GoalUnit.glasses,
    );

    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(row.target, 12);
    expect(row.progress, 3);
  });

  test('23505 recovery adopts cloud UUID and stops retrying old UUID',
      () async {
    const localId = '35000000-0000-4000-8000-000000000001';
    const cloudId = '35000000-0000-4000-8000-000000000002';
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: localId,
      progress: 7,
      target: 8,
      unit: GoalUnit.glasses,
    );
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Water',
      templateKey: 'water',
      target: 8,
      progress: 3,
      unit: 'glasses',
    );
    remote.hiddenFetches = 1;

    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(row.supabaseId, cloudId);
    expect(row.progress, 7);
    expect(row.syncState, 'synced');
    expect(
      remote.attemptedPayloads.map((payload) => payload['id']),
      containsAllInOrder([localId, cloudId]),
    );
    expect(remote.cloud, hasLength(1));
  });

  test('cloud pull adopts template match instead of inserting second row',
      () async {
    const localId = '36000000-0000-4000-8000-000000000001';
    const cloudId = '36000000-0000-4000-8000-000000000002';
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: localId,
      progress: 2,
      target: 8,
      unit: GoalUnit.glasses,
      syncState: 'synced',
    );
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Water',
      templateKey: 'water',
      target: 8,
      progress: 5,
      unit: 'glasses',
    );
    remote.hiddenFetches = 1;

    await repository.syncForCurrentUser();

    final rows = await database.select(database.goals).get();
    expect(rows, hasLength(1));
    expect(rows.single.supabaseId, cloudId);
    expect(rows.single.progress, 5);
  });

  test('custom goals with null template are never merged together', () async {
    await _insertLocalTemplate(
      database,
      templateKey: null,
      remoteId: '37000000-0000-4000-8000-000000000001',
      progress: 1,
    );
    await _insertLocalTemplate(
      database,
      templateKey: null,
      remoteId: '37000000-0000-4000-8000-000000000002',
      progress: 2,
    );

    await repository.syncForCurrentUser();

    expect(await database.select(database.goals).get(), hasLength(2));
    expect(remote.cloud, hasLength(2));
  });

  test('same template belonging to two users is never cross-merged', () async {
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '38000000-0000-4000-8000-000000000001',
      progress: 3,
      target: 8,
      unit: GoalUnit.glasses,
      userId: 'user-a',
    );
    await _insertLocalTemplate(
      database,
      templateKey: 'water',
      remoteId: '38000000-0000-4000-8000-000000000002',
      progress: 6,
      target: 8,
      unit: GoalUnit.glasses,
      userId: 'user-b',
    );

    await repository.syncForCurrentUser();

    final rows = await database.select(database.goals).get();
    expect(rows.where((row) => row.userId == 'user-a'), hasLength(1));
    expect(rows.where((row) => row.userId == 'user-b'), hasLength(1));
    expect(
      rows.singleWhere((row) => row.userId == 'user-b').progress,
      6,
    );
  });

  test('new user initialization does not create starter goals', () async {
    await repository.syncForCurrentUser();

    expect(await database.select(database.goals).get(), isEmpty);
    expect(remote.cloud, isEmpty);
  });

  test('selecting water template creates one correctly shaped goal', () async {
    final created = await repository.addGoalFromTemplate(
      template: _template(GoalTemplateKeys.water),
      localizedTitle: 'Drink water',
    );
    await repository.syncForCurrentUser();

    final row = await database.select(database.goals).getSingle();
    expect(created, isTrue);
    expect(row.templateKey, GoalTemplateKeys.water);
    expect(row.iconKey, GoalTemplateKeys.water);
    expect(row.target, 8);
    expect(row.unit, GoalUnit.glasses);
    expect(row.frequency, GoalFrequency.daily);
    expect(remote.cloud, hasLength(1));
  });

  test('selecting an already active template never creates a second goal',
      () async {
    final template = _template(GoalTemplateKeys.water);
    expect(
      await repository.addGoalFromTemplate(
        template: template,
        localizedTitle: 'Drink water',
      ),
      isTrue,
    );
    expect(
      await repository.addGoalFromTemplate(
        template: template,
        localizedTitle: 'Drink water',
      ),
      isFalse,
    );

    expect(await database.select(database.goals).get(), hasLength(1));
  });

  test('archived template can be selected again as a new active goal',
      () async {
    final template = _template(GoalTemplateKeys.water);
    await repository.addGoalFromTemplate(
      template: template,
      localizedTitle: 'Drink water',
    );
    await repository.syncForCurrentUser();
    final first = await database.select(database.goals).getSingle();
    await repository.archiveGoal(first.id);
    await repository.syncForCurrentUser();

    expect(
      await repository.addGoalFromTemplate(
        template: template,
        localizedTitle: 'Drink water',
      ),
      isTrue,
    );

    final rows = await database.select(database.goals).get();
    expect(rows.where((row) => row.status == 'active'), hasLength(1));
    expect(rows.where((row) => row.status == 'archived'), hasLength(1));
  });

  test('custom goal always keeps templateKey null', () async {
    await repository.addCustomGoal(
      title: 'My custom goal',
      unit: GoalUnit.custom,
      customUnitLabel: 'times',
      target: 3,
      frequency: GoalFrequency.weekly,
    );

    expect(
      (await database.select(database.goals).getSingle()).templateKey,
      isNull,
    );
  });

  test('title-only edit preserves progress and period', () async {
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.water,
      remoteId: '41000000-0000-4000-8000-000000000001',
      progress: 5,
      target: 8,
      unit: GoalUnit.glasses,
    );
    final before = await database.select(database.goals).getSingle();

    expect(
      await repository.updateGoal(
        localId: before.id,
        title: 'Hydrate',
        target: 8,
        unit: GoalUnit.glasses,
        frequency: GoalFrequency.daily,
      ),
      isTrue,
    );

    final after = await database.select(database.goals).getSingle();
    expect(after.title, 'Hydrate');
    expect(after.progress, 5);
    expect(after.periodStart, before.periodStart);
    expect(after.syncState, 'pending');
  });

  test('lowering target clamps progress after confirmed repository update',
      () async {
    await _insertLocalTemplate(
      database,
      templateKey: null,
      remoteId: '42000000-0000-4000-8000-000000000001',
      progress: 8,
      target: 10,
    );
    final goal = await database.select(database.goals).getSingle();

    await repository.updateGoal(
      localId: goal.id,
      title: goal.title,
      target: 5,
      unit: goal.unit,
      frequency: goal.frequency,
    );

    expect((await database.select(database.goals).getSingle()).progress, 5);
  });

  test('frequency change resets progress and recalculates period start',
      () async {
    await _insertLocalTemplate(
      database,
      templateKey: null,
      remoteId: '43000000-0000-4000-8000-000000000001',
      progress: 8,
      target: 10,
    );
    final goal = await database.select(database.goals).getSingle();

    await repository.updateGoal(
      localId: goal.id,
      title: goal.title,
      target: goal.target,
      unit: goal.unit,
      frequency: GoalFrequency.monthly,
    );

    final after = await database.select(database.goals).getSingle();
    expect(after.progress, 0);
    expect(after.periodStart, DateTime(2026, 8));
  });

  test('another users goal cannot be edited', () async {
    await _insertLocalTemplate(
      database,
      templateKey: null,
      remoteId: '44000000-0000-4000-8000-000000000001',
      userId: 'user-b',
    );
    final goal = await database.select(database.goals).getSingle();

    expect(
      await repository.updateGoal(
        localId: goal.id,
        title: 'Forbidden',
        target: goal.target,
        unit: goal.unit,
        frequency: goal.frequency,
      ),
      isFalse,
    );
    expect((await database.select(database.goals).getSingle()).title,
        'Custom goal');
  });

  test('daily increment resets an elapsed day before adding', () async {
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.water,
      remoteId: '45000000-0000-4000-8000-000000000001',
      progress: 7,
      target: 8,
      unit: GoalUnit.glasses,
      periodStart: DateTime(2026, 8, 10),
    );

    expect(
      await repository.incrementByTemplateKey(GoalTemplateKeys.water, 1),
      isTrue,
    );
    final row = await database.select(database.goals).getSingle();
    expect(row.progress, 1);
    expect(row.periodStart, DateTime(2026, 8, 11));
  });

  test('weekly increment resets at the next Monday', () async {
    now = DateTime(2026, 8, 17, 9);
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.reading,
      remoteId: '46000000-0000-4000-8000-000000000001',
      progress: 3,
      target: 10,
      frequency: GoalFrequency.weekly,
      periodStart: DateTime(2026, 8, 10),
    );

    await repository.incrementByTemplateKey(GoalTemplateKeys.reading, 1);
    final row = await database.select(database.goals).getSingle();
    expect(row.progress, 1);
    expect(row.periodStart, DateTime(2026, 8, 17));
  });

  test('monthly increment resets on the first day of a new month', () async {
    now = DateTime(2026, 9, 3, 9);
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.reading,
      remoteId: '47000000-0000-4000-8000-000000000001',
      progress: 3,
      target: 4,
      frequency: GoalFrequency.monthly,
      periodStart: DateTime(2026, 8),
    );

    await repository.incrementByTemplateKey(GoalTemplateKeys.reading, 1);
    final row = await database.select(database.goals).getSingle();
    expect(row.progress, 1);
    expect(row.periodStart, DateTime(2026, 9));
  });

  test('meditation and breathing completions use exact template amounts',
      () async {
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.meditation,
      remoteId: '48000000-0000-4000-8000-000000000001',
      target: 30,
      progress: 0,
    );
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.breathing,
      remoteId: '48000000-0000-4000-8000-000000000002',
      target: 10,
      progress: 0,
    );

    expect(
      await repository.incrementByTemplateKey(
        GoalTemplateKeys.meditation,
        15,
      ),
      isTrue,
    );
    expect(
      await repository.incrementByTemplateKey(
        GoalTemplateKeys.breathing,
        4,
      ),
      isTrue,
    );

    final rows = await database.select(database.goals).get();
    expect(
      rows.singleWhere((row) => row.templateKey == 'meditation').progress,
      15,
    );
    expect(
      rows.singleWhere((row) => row.templateKey == 'breathing').progress,
      4,
    );
  });

  test('activity completion is harmless when matching goal does not exist',
      () async {
    expect(
      await repository.incrementByTemplateKey(
        GoalTemplateKeys.meditation,
        15,
      ),
      isFalse,
    );
    expect(await database.select(database.goals).get(), isEmpty);
  });

  test('journal template increments once and clamps repeated entries at 1',
      () async {
    await repository.addGoalFromTemplate(
      template: _template(GoalTemplateKeys.journal),
      localizedTitle: 'Write a journal entry',
      localizedCustomUnitLabel: 'entry',
    );
    await repository.incrementByTemplateKey(GoalTemplateKeys.journal, 1);
    await repository.incrementByTemplateKey(GoalTemplateKeys.journal, 1);

    final row = await database.select(database.goals).getSingle();
    expect(row.target, 1);
    expect(row.unit, GoalUnit.custom);
    expect(row.progress, 1);
  });

  test('offline edit remains pending then converges with cloud', () async {
    await repository.addCustomGoal(
      title: 'Before',
      unit: GoalUnit.pages,
      target: 10,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();
    final goal = await database.select(database.goals).getSingle();
    remote.failUpserts = true;

    await repository.updateGoal(
      localId: goal.id,
      title: 'After',
      target: 12,
      unit: goal.unit,
      frequency: goal.frequency,
    );
    await repository.syncForCurrentUser();
    expect((await database.select(database.goals).getSingle()).syncState,
        'pending');

    remote.failUpserts = false;
    await repository.syncForCurrentUser();
    expect((await database.select(database.goals).getSingle()).syncState,
        'synced');
    expect(remote.cloud[goal.supabaseId]!['title'], 'After');
  });

  test('offline archive remains pending then converges with cloud', () async {
    await repository.addCustomGoal(
      title: 'Archive offline',
      unit: GoalUnit.pages,
      target: 10,
      frequency: GoalFrequency.daily,
    );
    await repository.syncForCurrentUser();
    final goal = await database.select(database.goals).getSingle();
    remote.failUpserts = true;

    await repository.archiveGoal(goal.id);
    await repository.syncForCurrentUser();
    expect((await database.select(database.goals).getSingle()).syncState,
        'pending');

    remote.failUpserts = false;
    await repository.syncForCurrentUser();
    expect(remote.cloud[goal.supabaseId]!['status'], 'archived');
  });

  test('repository restart does not change active template count', () async {
    await repository.addGoalFromTemplate(
      template: _template(GoalTemplateKeys.water),
      localizedTitle: 'Drink water',
    );
    await repository.syncForCurrentUser();

    final restarted = GoalsRepository(
      database: database,
      remoteDataSource: remote,
      uuidGenerator: () => '49000000-0000-4000-8000-000000000001',
      clock: () => now,
    );
    await restarted.syncForCurrentUser();

    expect(await restarted.watchAll().first, hasLength(1));
    expect(remote.cloud, hasLength(1));
  });

  test('catalog contains exactly nine stable templates in product order', () {
    expect(
      goalTemplates.map((template) => template.key).toList(),
      const [
        'water',
        'journal',
        'meditation',
        'breathing',
        'reading',
        'walking',
        'stretching',
        'sleep_early',
        'screen_free',
      ],
    );
    expect(
      goalTemplates.map((template) => template.sortOrder).toList(),
      List<int>.generate(9, (index) => index),
    );
  });

  test('journal catalog tracks one localized custom entry per day', () {
    final journal = _template(GoalTemplateKeys.journal);
    expect(journal.defaultTarget, 1);
    expect(journal.unit, GoalUnit.custom);
    expect(journal.customUnitLabelKey, 'goalsCustomUnitEntry');
    expect(journal.frequency, GoalFrequency.daily);
    expect(journal.autoProgressSource, GoalAutoProgressSource.journal);
  });

  test('unit change resets current progress without changing template key',
      () async {
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.walking,
      remoteId: '50000000-0000-4000-8000-000000000001',
      progress: 20,
      target: 30,
    );
    final goal = await database.select(database.goals).getSingle();

    await repository.updateGoal(
      localId: goal.id,
      title: goal.title,
      target: 3,
      unit: GoalUnit.custom,
      customUnitLabel: 'laps',
      frequency: goal.frequency,
    );

    final updated = await database.select(database.goals).getSingle();
    expect(updated.progress, 0);
    expect(updated.templateKey, GoalTemplateKeys.walking);
  });

  test('automatic progress never exceeds target', () async {
    await _insertLocalTemplate(
      database,
      templateKey: GoalTemplateKeys.meditation,
      remoteId: '51000000-0000-4000-8000-000000000001',
      progress: 14,
      target: 15,
    );

    await repository.incrementByTemplateKey(
      GoalTemplateKeys.meditation,
      15,
    );
    expect((await database.select(database.goals).getSingle()).progress, 15);
  });

  test('cloud active template preflight prevents a second local row', () async {
    const cloudId = '52000000-0000-4000-8000-000000000001';
    remote.cloud[cloudId] = _cloudGoal(
      id: cloudId,
      userId: 'user-a',
      title: 'Drink water',
      templateKey: GoalTemplateKeys.water,
      target: 8,
      unit: 'glasses',
    );

    expect(
      await repository.addGoalFromTemplate(
        template: _template(GoalTemplateKeys.water),
        localizedTitle: 'Drink water',
      ),
      isFalse,
    );
    await repository.syncForCurrentUser();
    expect(await database.select(database.goals).get(), hasLength(1));
    expect((await database.select(database.goals).getSingle()).supabaseId,
        cloudId);
  });

  test('auth null blocks template creation', () async {
    remote.currentUserId = null;
    expect(
      await repository.addGoalFromTemplate(
        template: _template(GoalTemplateKeys.water),
        localizedTitle: 'Drink water',
      ),
      isFalse,
    );
    expect(await database.select(database.goals).get(), isEmpty);
  });

  test('goal streak preferences remain isolated between accounts', () async {
    final userAStreak = await repository.recordActivityToday();
    expect(userAStreak.count, 1);

    remote.currentUserId = 'user-b';
    expect((await repository.loadStreak()).count, 0);
    expect((await repository.recordActivityToday()).count, 1);

    remote.currentUserId = 'user-a';
    expect((await repository.loadStreak()).count, 1);
  });
}

GoalTemplate _template(String key) =>
    goalTemplates.singleWhere((template) => template.key == key);

Future<void> _insertLocalTemplate(
  AppDatabase database, {
  required String? templateKey,
  required String remoteId,
  int progress = 0,
  int target = 10,
  GoalUnit unit = GoalUnit.minutes,
  GoalFrequency frequency = GoalFrequency.daily,
  DateTime? periodStart,
  String syncState = 'pending',
  String userId = 'user-a',
}) async {
  await database.into(database.goals).insert(
        GoalsCompanion.insert(
          title: templateKey == null ? 'Custom goal' : _titleFor(templateKey),
          iconKey: templateKey ?? 'custom',
          unit: unit,
          target: target,
          progress: Value(progress),
          frequency: frequency,
          periodStart: periodStart ?? DateTime(2026, 8, 11),
          userId: Value(userId),
          supabaseId: Value(remoteId),
          templateKey: Value(templateKey),
          status: const Value('active'),
          syncState: Value(syncState),
        ),
      );
}

String _titleFor(String templateKey) {
  return switch (templateKey) {
    'water' => 'Water',
    'journal' => 'Journal',
    'meditation' => 'Meditation',
    'breathing' => 'Breathing',
    'reading' => 'Reading',
    'walking' => 'Walking',
    'stretching' => 'Stretching',
    'sleep_early' => 'Sleep early',
    'screen_free' => 'Screen free',
    _ => templateKey,
  };
}

class _FakeGoalsRemoteDataSource implements GoalsRemoteDataSource {
  @override
  String? currentUserId;
  bool failUpserts = false;
  bool failFetch = false;
  int hiddenFetches = 0;
  final Map<String, Map<String, dynamic>> cloud = {};
  final List<Map<String, dynamic>> attemptedPayloads = [];

  @override
  Future<Map<String, dynamic>> upsertGoal(
    Map<String, dynamic> payload,
  ) async {
    attemptedPayloads.add(Map<String, dynamic>.from(payload));
    if (failUpserts) throw Exception('offline');

    final id = payload['id'] as String;
    final templateKey = payload['template_key'] as String?;
    final hasTemplateConflict = templateKey != null &&
        payload['status'] == 'active' &&
        cloud.values.any(
          (row) =>
              row['id'] != id &&
              row['user_id'] == payload['user_id'] &&
              row['template_key'] == templateKey &&
              row['status'] == 'active',
        );
    if (hasTemplateConflict) {
      throw const GoalsActiveTemplateConflict(
        '23505 goals_user_active_template_unique',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final existing = cloud[id];
    cloud[id] = {
      ...?existing,
      ...payload,
      'created_at': existing?['created_at'] ?? now,
      'updated_at': now,
    };
    return {'id': id, 'updated_at': now};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGoals(String userId) async {
    if (failFetch) throw Exception('offline');
    if (hiddenFetches > 0) {
      hiddenFetches--;
      return const [];
    }
    return cloud.values
        .where(
          (row) =>
              row['user_id'] == userId &&
              (row['status'] == 'active' || row['status'] == 'archived'),
        )
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> findActiveGoalByTemplate({
    required String userId,
    required String templateKey,
  }) async {
    for (final row in cloud.values) {
      if (row['user_id'] == userId &&
          row['template_key'] == templateKey &&
          row['status'] == 'active') {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }
}

Map<String, dynamic> _cloudGoal({
  required String id,
  required String userId,
  required String title,
  String? templateKey,
  int target = 10,
  int progress = 0,
  String unit = 'minutes',
  String frequency = 'daily',
  DateTime? periodStart,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return {
    'id': id,
    'user_id': userId,
    'title': title,
    'icon_key': 'custom',
    'template_key': templateKey,
    'unit': unit,
    'custom_unit_label': null,
    'target': target,
    'progress': progress,
    'frequency': frequency,
    'period_start':
        (periodStart ?? DateTime.utc(2026, 8, 11)).toIso8601String(),
    'status': 'active',
    'created_at': now,
    'updated_at': now,
  };
}
