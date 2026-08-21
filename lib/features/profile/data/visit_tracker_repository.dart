import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef VisitPreferencesLoader = Future<SharedPreferences> Function();
typedef VisitUserIdProvider = String? Function();
typedef VisitCloudUpsert = Future<void> Function(
  String userId,
  Set<String> dateKeys,
);
typedef VisitCloudFetch = Future<Set<String>> Function(
  String userId,
  String fromDate,
  String toDate,
);
typedef VisitProfileSummarySync = Future<void> Function(
  String userId,
  Set<String> pendingDateKeys,
);
typedef VisitSummaryFetch = Future<VisitProfileSummary> Function(String userId);

class VisitProfileSummary {
  const VisitProfileSummary({
    required this.streakCount,
    required this.lastVisitDateKey,
  });

  static const empty = VisitProfileSummary(
    streakCount: 0,
    lastVisitDateKey: null,
  );

  final int streakCount;
  final String? lastVisitDateKey;
}

/// Tracks exact app-visit calendar dates with an account-scoped local cache.
///
/// SharedPreferences is both the instant/offline UI source and a lightweight
/// persistent outbox. Supabase `user_visit_days` is the cross-device source of
/// truth. Aggregate profile fields are retained for existing profile/stats UI
/// and provide a display-only compatibility fallback for incomplete legacy
/// weekly history. Derived fallback dates are never persisted as exact visits.
class VisitTrackerRepository {
  VisitTrackerRepository({
    SupabaseClient? client,
    VisitPreferencesLoader? preferencesLoader,
    VisitUserIdProvider? currentUserId,
    VisitCloudUpsert? cloudUpsert,
    VisitCloudFetch? cloudFetch,
    VisitProfileSummarySync? profileSummarySync,
    VisitSummaryFetch? summaryFetch,
    DateTime Function()? now,
  })  : _client = client ?? Supabase.instance.client,
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _currentUserId = currentUserId,
        _cloudUpsert = cloudUpsert,
        _cloudFetch = cloudFetch,
        _profileSummarySync = profileSummarySync,
        _summaryFetch = summaryFetch,
        _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final VisitPreferencesLoader _preferencesLoader;
  final VisitUserIdProvider? _currentUserId;
  final VisitCloudUpsert? _cloudUpsert;
  final VisitCloudFetch? _cloudFetch;
  final VisitProfileSummarySync? _profileSummarySync;
  final VisitSummaryFetch? _summaryFetch;
  final DateTime Function() _now;
  final Map<String, Future<void>> _activeSyncs = {};

  static String lastVisitKey(String userId) => 'visit_last_date_v1_$userId';
  static String visitHistoryKey(String userId) => 'visit_dates_v2_$userId';
  static String profileSummaryPendingKey(String userId) =>
      'visit_profile_summary_pending_v1_$userId';

  String? get _userId => _currentUserId?.call() ?? _client.auth.currentUser?.id;

  static String localDateKey(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// Records the authenticated user's local calendar date before any network
  /// work. Repeated opens on the same day are idempotent.
  Future<bool> recordVisitIfNewDay() async {
    final userId = _userId;
    if (userId == null) return false;

    final today = _now().toLocal();
    final todayStr = localDateKey(today);

    try {
      final prefs = await _preferencesLoader();
      if (_userId != userId) return false;

      final localLastVisit = prefs.getString(lastVisitKey(userId));
      final isNewDay = localLastVisit != todayStr;

      // Always seed the exact date. This handles users whose legacy last-date
      // already says today without inventing any earlier dates from the count.
      await _recordLocalVisitDates(
        prefs: prefs,
        userId: userId,
        dateKeys: {todayStr},
      );

      if (isNewDay) {
        await prefs.setString(lastVisitKey(userId), todayStr);
      }
      // Queue the profile summary even when an older app version already set
      // the local last-date key. Cloud equality makes this idempotent, while a
      // previously failed profile update can now recover.
      await _addPendingProfileDate(prefs, userId, todayStr);

      // The local write is already durable. Network failure leaves the date in
      // the local outbox for startup/resume/next-open retry.
      unawaited(syncVisitHistoryForCurrentUser());
      return isNewDay;
    } catch (error) {
      debugPrint(
        '[VisitTracker] local record deferred error=${error.runtimeType}',
      );
      return false;
    }
  }

  Future<void> _addPendingProfileDate(
    SharedPreferences prefs,
    String userId,
    String dateKey,
  ) async {
    final key = profileSummaryPendingKey(userId);
    final dates = prefs.getStringList(key)?.toSet() ?? <String>{};
    dates.add(dateKey);
    final ordered = dates.where(_isDateKey).toList()..sort();
    await prefs.setStringList(key, ordered);
  }

  Future<void> _recordLocalVisitDates({
    required SharedPreferences prefs,
    required String userId,
    required Set<String> dateKeys,
  }) async {
    final key = visitHistoryKey(userId);
    final dates = prefs.getStringList(key)?.toSet() ?? <String>{};
    dates.addAll(dateKeys.where(_isDateKey));

    // Keep all exact locally observed dates until cloud confirms them. One
    // ISO date per day is small, and pruning would lose an extended-offline
    // device's persistent outbox before it reconnects.
    dates.removeWhere((value) => !_isDateKey(value));
    final ordered = dates.toList()..sort();
    await prefs.setStringList(key, ordered);
  }

  /// Returns exact locally cached dates for the current Monday-Sunday week.
  Future<Set<String>> fetchVisitDatesForCurrentWeek() async {
    final userId = _userId;
    if (userId == null) return const <String>{};
    final prefs = await _preferencesLoader();
    if (_userId != userId) return const <String>{};
    final range = _currentWeekRange();
    final stored = prefs.getStringList(visitHistoryKey(userId)) ?? const [];
    return stored.where((value) {
      if (!_isDateKey(value)) return false;
      return value.compareTo(range.$1) >= 0 && value.compareTo(range.$2) <= 0;
    }).toSet();
  }

  /// Merges exact current-week dates with a display-only legacy streak span.
  ///
  /// Exact history always wins and remains untouched. For an older account
  /// whose exact history is incomplete, [lastVisitDateKey] and [streakCount]
  /// describe a consecutive calendar-day span ending at the last visit. Only
  /// the portion intersecting the current week is added to the returned set.
  Future<Set<String>> fetchWeeklyVisitDatesWithLegacyFallback() async {
    final userId = _userId;
    if (userId == null) return const <String>{};

    final exactDates = await fetchVisitDatesForCurrentWeek();
    if (_userId != userId) return const <String>{};
    final summary = await _fetchProfileSummaryForUser(userId);
    if (_userId != userId) return const <String>{};

    final fallbackDates = _legacyFallbackDatesForCurrentWeek(summary);
    if (fallbackDates.isEmpty || exactDates.containsAll(fallbackDates)) {
      return exactDates;
    }
    return {...fallbackDates, ...exactDates};
  }

  /// Pushes the durable local date set first, then pulls and merges the current
  /// cloud week. Concurrent callers for one user await the same sync operation.
  Future<void> syncVisitHistoryForCurrentUser() async {
    final userId = _userId;
    if (userId == null) return;

    final existing = _activeSyncs[userId];
    if (existing != null) return existing;

    final operation = _syncForUser(userId);
    _activeSyncs[userId] = operation;
    try {
      await operation;
    } finally {
      if (identical(_activeSyncs[userId], operation)) {
        _activeSyncs.remove(userId);
      }
    }
  }

  Future<void> _syncForUser(String userId) async {
    try {
      final prefs = await _preferencesLoader();
      if (_userId != userId) return;

      final localDates =
          (prefs.getStringList(visitHistoryKey(userId)) ?? const [])
              .where(_isDateKey)
              .toSet();

      // Push-before-pull preserves offline dates and makes retries idempotent.
      if (localDates.isNotEmpty) {
        await (_cloudUpsert?.call(userId, localDates) ??
            _upsertCloudDates(userId, localDates));
      }
      if (_userId != userId) return;

      final range = _currentWeekRange();
      final cloudDates = await (_cloudFetch?.call(
            userId,
            range.$1,
            range.$2,
          ) ??
          _fetchCloudDates(userId, range.$1, range.$2));
      if (_userId != userId) return;

      await _recordLocalVisitDates(
        prefs: prefs,
        userId: userId,
        dateKeys: cloudDates,
      );

      final pending =
          (prefs.getStringList(profileSummaryPendingKey(userId)) ?? const [])
              .where(_isDateKey)
              .toSet();
      if (pending.isNotEmpty) {
        await (_profileSummarySync?.call(userId, pending) ??
            _syncProfileSummary(userId, pending));
        if (_userId != userId) return;
        await prefs.remove(profileSummaryPendingKey(userId));
      }
    } catch (error) {
      // Local dates and pending summary dates remain durable for a later retry.
      debugPrint(
        '[VisitTracker] cloud sync deferred error=${error.runtimeType}',
      );
    }
  }

  Future<void> _upsertCloudDates(
    String userId,
    Set<String> dateKeys,
  ) async {
    if (_userId != userId || dateKeys.isEmpty) return;
    final rows = dateKeys
        .map((date) => {'user_id': userId, 'visit_date': date})
        .toList(growable: false);
    await _client.from('user_visit_days').upsert(
          rows,
          onConflict: 'user_id,visit_date',
          ignoreDuplicates: true,
        );
  }

  Future<Set<String>> _fetchCloudDates(
    String userId,
    String fromDate,
    String toDate,
  ) async {
    if (_userId != userId) return const <String>{};
    final response = await _client
        .from('user_visit_days')
        .select('visit_date')
        .eq('user_id', userId)
        .gte('visit_date', fromDate)
        .lte('visit_date', toDate);
    return response
        .map((row) => row['visit_date'])
        .whereType<String>()
        .where(_isDateKey)
        .toSet();
  }

  /// Keeps legacy aggregate profile fields stable without deriving weekly UI
  /// from them. Only dates newly observed by this device version are pending;
  /// an equal/later cloud last date prevents double increments across devices.
  Future<void> _syncProfileSummary(
    String userId,
    Set<String> pendingDateKeys,
  ) async {
    if (_userId != userId) return;
    final response = await _client
        .from('profiles')
        .select('visit_days_count, last_visit_date')
        .eq('id', userId)
        .maybeSingle();
    if (_userId != userId) return;

    final currentCount = (response?['visit_days_count'] as int?) ?? 0;
    final rawLast = response?['last_visit_date']?.toString();
    final cloudLast = rawLast != null && rawLast.length >= 10
        ? rawLast.substring(0, 10)
        : null;
    final ordered = pendingDateKeys.where(_isDateKey).toList()..sort();
    final newDates = cloudLast == null
        ? ordered
        : ordered.where((date) => date.compareTo(cloudLast) > 0).toList();
    if (newDates.isEmpty) return;

    await _client.from('profiles').update({
      'visit_days_count': currentCount + newDates.length,
      'last_visit_date': newDates.last,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  (String, String) _currentWeekRange() {
    final now = _now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return (
      localDateKey(monday),
      localDateKey(monday.add(const Duration(days: 6))),
    );
  }

  static bool _isDateKey(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    return parsed != null && localDateKey(parsed) == value;
  }

  Set<String> _legacyFallbackDatesForCurrentWeek(
    VisitProfileSummary summary,
  ) {
    final lastKey = summary.lastVisitDateKey;
    if (summary.streakCount <= 0 || lastKey == null || !_isDateKey(lastKey)) {
      return const <String>{};
    }

    final lastVisit = DateTime.parse(lastKey);
    final firstVisit = lastVisit.subtract(
      Duration(days: summary.streakCount - 1),
    );
    final range = _currentWeekRange();
    final monday = DateTime.parse(range.$1);

    final result = <String>{};
    for (var index = 0; index < 7; index++) {
      final day = monday.add(Duration(days: index));
      if (!day.isBefore(firstVisit) && !day.isAfter(lastVisit)) {
        result.add(localDateKey(day));
      }
    }
    return result;
  }

  Future<VisitProfileSummary> _fetchProfileSummaryForUser(
    String userId,
  ) async {
    try {
      final injected = await _summaryFetch?.call(userId);
      if (injected != null) {
        return _userId == userId ? injected : VisitProfileSummary.empty;
      }

      final response = await _client
          .from('profiles')
          .select('visit_days_count, last_visit_date')
          .eq('id', userId)
          .maybeSingle();
      if (_userId != userId) return VisitProfileSummary.empty;

      final rawLast = response?['last_visit_date']?.toString();
      final normalizedLast = rawLast != null && rawLast.length >= 10
          ? rawLast.substring(0, 10)
          : null;
      return VisitProfileSummary(
        streakCount: (response?['visit_days_count'] as int?) ?? 0,
        lastVisitDateKey: normalizedLast != null && _isDateKey(normalizedLast)
            ? normalizedLast
            : null,
      );
    } catch (error) {
      debugPrint(
        '[VisitTracker] summary fetch deferred error=${error.runtimeType}',
      );
      return VisitProfileSummary.empty;
    }
  }

  /// Fetches the preserved aggregate total for existing profile/stat screens.
  Future<int> fetchVisitDaysCount() async {
    final userId = _userId;
    if (userId == null) return 0;
    return (await _fetchProfileSummaryForUser(userId)).streakCount;
  }
}
