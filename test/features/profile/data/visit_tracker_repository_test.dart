import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mindful_journal/features/profile/data/visit_tracker_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;
  late String? currentUserId;
  late DateTime now;
  late bool online;
  late Map<String, Set<String>> cloudDates;
  late Map<String, Set<String>> profileSummaryDates;
  late Map<String, VisitProfileSummary> summaries;

  VisitTrackerRepository repository() => VisitTrackerRepository(
        client: client,
        currentUserId: () => currentUserId,
        now: () => now,
        cloudUpsert: (userId, dates) async {
          if (!online) throw const _OfflineException();
          cloudDates.putIfAbsent(userId, () => <String>{}).addAll(dates);
        },
        cloudFetch: (userId, fromDate, toDate) async {
          if (!online) throw const _OfflineException();
          return (cloudDates[userId] ?? const <String>{})
              .where(
                (date) =>
                    date.compareTo(fromDate) >= 0 &&
                    date.compareTo(toDate) <= 0,
              )
              .toSet();
        },
        profileSummarySync: (userId, dates) async {
          if (!online) throw const _OfflineException();
          profileSummaryDates
              .putIfAbsent(userId, () => <String>{})
              .addAll(dates);
        },
        summaryFetch: (userId) async =>
            summaries[userId] ?? VisitProfileSummary.empty,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = SupabaseClient('http://localhost:54321', 'test-anon-key');
    currentUserId = 'user-a';
    now = DateTime(2026, 8, 19, 10); // Wednesday.
    online = true;
    cloudDates = {};
    profileSummaryDates = {};
    summaries = {};
  });

  tearDown(() async {
    await client.dispose();
  });

  test('fresh Wednesday visit marks and uploads only Wednesday', () async {
    final tracker = repository();

    expect(await tracker.recordVisitIfNewDay(), isTrue);
    await tracker.syncVisitHistoryForCurrentUser();

    expect(await tracker.fetchVisitDatesForCurrentWeek(), {'2026-08-19'});
    expect(cloudDates['user-a'], {'2026-08-19'});
    expect(profileSummaryDates['user-a'], {'2026-08-19'});
  });

  test('same-day opens create one row and Thursday is independent', () async {
    final tracker = repository();

    expect(await tracker.recordVisitIfNewDay(), isTrue);
    expect(await tracker.recordVisitIfNewDay(), isFalse);
    expect(await tracker.recordVisitIfNewDay(), isFalse);
    expect(await tracker.recordVisitIfNewDay(), isFalse);
    expect(await tracker.recordVisitIfNewDay(), isFalse);
    await tracker.syncVisitHistoryForCurrentUser();

    now = DateTime(2026, 8, 20, 9); // Thursday.
    expect(await tracker.recordVisitIfNewDay(), isTrue);
    await tracker.syncVisitHistoryForCurrentUser();

    expect(
      await tracker.fetchVisitDatesForCurrentWeek(),
      {'2026-08-19', '2026-08-20'},
    );
    expect(cloudDates['user-a'], {'2026-08-19', '2026-08-20'});
  });

  test('new week does not inherit prior week check marks', () async {
    final tracker = repository();
    await tracker.recordVisitIfNewDay();
    await tracker.syncVisitHistoryForCurrentUser();

    now = DateTime(2026, 8, 24, 8); // Following Monday.
    await tracker.recordVisitIfNewDay();
    await tracker.syncVisitHistoryForCurrentUser();

    expect(await tracker.fetchVisitDatesForCurrentWeek(), {'2026-08-24'});
  });

  test('visit history is isolated between accounts', () async {
    final tracker = repository();
    await tracker.recordVisitIfNewDay();
    await tracker.syncVisitHistoryForCurrentUser();

    currentUserId = 'user-b';
    expect(await tracker.fetchVisitDatesForCurrentWeek(), isEmpty);
    await tracker.recordVisitIfNewDay();
    await tracker.syncVisitHistoryForCurrentUser();

    expect(cloudDates['user-a'], {'2026-08-19'});
    expect(cloudDates['user-b'], {'2026-08-19'});
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList(VisitTrackerRepository.visitHistoryKey('user-a')),
      ['2026-08-19'],
    );
    expect(
      prefs.getStringList(VisitTrackerRepository.visitHistoryKey('user-b')),
      ['2026-08-19'],
    );
  });

  test('second device pulls exact cloud dates and merges its local visit',
      () async {
    final firstDevice = repository();
    await firstDevice.recordVisitIfNewDay();
    await firstDevice.syncVisitHistoryForCurrentUser();

    // A second install has no local cache but shares the same cloud account.
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 8, 20, 10); // Thursday.
    final secondDevice = repository();
    await secondDevice.recordVisitIfNewDay();
    await secondDevice.syncVisitHistoryForCurrentUser();

    expect(
      await secondDevice.fetchVisitDatesForCurrentWeek(),
      {'2026-08-19', '2026-08-20'},
    );
  });

  test('offline visit stays checked and syncs when network returns', () async {
    final tracker = repository();
    online = false;

    expect(await tracker.recordVisitIfNewDay(), isTrue);
    await tracker.syncVisitHistoryForCurrentUser();
    expect(await tracker.fetchVisitDatesForCurrentWeek(), {'2026-08-19'});
    expect(cloudDates['user-a'], isNull);

    online = true;
    await tracker.syncVisitHistoryForCurrentUser();
    expect(cloudDates['user-a'], {'2026-08-19'});
    expect(profileSummaryDates['user-a'], {'2026-08-19'});
  });

  test('legacy aggregate remains separate from exact persisted history',
      () async {
    summaries['user-a'] = const VisitProfileSummary(
      streakCount: 15,
      lastVisitDateKey: '2026-08-19',
    );
    final tracker = repository();

    expect(await tracker.fetchVisitDaysCount(), 15);
    expect(await tracker.fetchVisitDatesForCurrentWeek(), isEmpty);
    expect(cloudDates['user-a'], isNull);

    await tracker.recordVisitIfNewDay();
    await tracker.syncVisitHistoryForCurrentUser();
    expect(await tracker.fetchVisitDatesForCurrentWeek(), {'2026-08-19'});
    expect(cloudDates['user-a'], {'2026-08-19'});
  });

  test('legacy Friday streak fills Monday through Friday in current week',
      () async {
    now = DateTime(2026, 8, 21, 10); // Friday.
    summaries['user-a'] = const VisitProfileSummary(
      streakCount: 13,
      lastVisitDateKey: '2026-08-21',
    );
    SharedPreferences.setMockInitialValues({
      VisitTrackerRepository.visitHistoryKey('user-a'): <String>[
        '2026-08-21',
      ],
    });

    expect(
      await repository().fetchWeeklyVisitDatesWithLegacyFallback(),
      {
        '2026-08-17',
        '2026-08-18',
        '2026-08-19',
        '2026-08-20',
        '2026-08-21',
      },
    );
  });

  test('exact dates are preserved while fallback only fills missing dates',
      () async {
    now = DateTime(2026, 8, 21, 10); // Friday.
    summaries['user-a'] = const VisitProfileSummary(
      streakCount: 2,
      lastVisitDateKey: '2026-08-21',
    );
    SharedPreferences.setMockInitialValues({
      VisitTrackerRepository.visitHistoryKey('user-a'): <String>[
        '2026-08-17',
        '2026-08-21',
      ],
    });

    expect(
      await repository().fetchWeeklyVisitDatesWithLegacyFallback(),
      {'2026-08-17', '2026-08-20', '2026-08-21'},
    );
  });

  test('legacy fallback profile data remains account scoped', () async {
    now = DateTime(2026, 8, 21, 10); // Friday.
    summaries['user-a'] = const VisitProfileSummary(
      streakCount: 13,
      lastVisitDateKey: '2026-08-21',
    );
    summaries['user-b'] = const VisitProfileSummary(
      streakCount: 1,
      lastVisitDateKey: '2026-08-19',
    );
    final tracker = repository();

    expect(
      await tracker.fetchWeeklyVisitDatesWithLegacyFallback(),
      containsAll({
        '2026-08-17',
        '2026-08-18',
        '2026-08-19',
        '2026-08-20',
        '2026-08-21',
      }),
    );
    currentUserId = 'user-b';
    expect(
      await tracker.fetchWeeklyVisitDatesWithLegacyFallback(),
      {'2026-08-19'},
    );
  });

  test('late account A cloud response is not merged into account B', () async {
    final fetchStarted = Completer<void>();
    final releaseFetch = Completer<void>();
    final tracker = VisitTrackerRepository(
      client: client,
      currentUserId: () => currentUserId,
      now: () => now,
      cloudUpsert: (userId, dates) async {
        cloudDates.putIfAbsent(userId, () => <String>{}).addAll(dates);
      },
      cloudFetch: (userId, fromDate, toDate) async {
        fetchStarted.complete();
        await releaseFetch.future;
        return {'2026-08-18'};
      },
      profileSummarySync: (_, __) async {},
    );

    final sync = tracker.syncVisitHistoryForCurrentUser();
    await fetchStarted.future;
    currentUserId = 'user-b';
    releaseFetch.complete();
    await sync;

    expect(await tracker.fetchVisitDatesForCurrentWeek(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList(VisitTrackerRepository.visitHistoryKey('user-b')),
      isNull,
    );
  });
}

class _OfflineException implements Exception {
  const _OfflineException();
}
