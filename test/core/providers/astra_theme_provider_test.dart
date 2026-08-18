import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/providers/astra_theme_provider.dart';
import 'package:mindful_journal/features/profile/data/astra_theme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('preference mapping keeps legacy sakura safely light', () {
    expect(
      AstraThemeNotifier.modeFromPreference('light'),
      AstraThemeMode.light,
    );
    expect(
      AstraThemeNotifier.modeFromPreference('dark'),
      AstraThemeMode.dark,
    );
    expect(
      AstraThemeNotifier.modeFromPreference('sakura'),
      AstraThemeMode.light,
    );
    expect(
      AstraThemeNotifier.modeFromPreference('unknown'),
      AstraThemeMode.light,
    );
    expect(
      AstraThemeNotifier.modeFromPreference(null),
      AstraThemeMode.light,
    );
  });

  test('brand new user without local or cloud preference starts light',
      () async {
    SharedPreferences.setMockInitialValues({
      'astra_bg_theme': 'dark',
      'astra_bg_theme_guest': 'dark',
      astraThemePrefsKeyForUser('previous-user'): 'dark',
    });
    final repository = _FakeThemeRepository(currentUserId: 'new-user');
    final notifier = _notifier(repository);

    await notifier.reloadForCurrentUser();

    expect(notifier.state, AstraThemeMode.light);
    expect(repository.fetches, ['new-user']);
    expect(
      (await SharedPreferences.getInstance())
          .getString(astraThemePrefsKeyForUser('new-user')),
      'light',
    );
    notifier.dispose();
  });

  test('auth null remains light and never persists an account preference',
      () async {
    final repository = _FakeThemeRepository();
    final notifier = _notifier(repository);

    await notifier.reloadForCurrentUser();
    await notifier.setDarkMode(true);

    expect(notifier.state, AstraThemeMode.light);
    expect(repository.fetches, isEmpty);
    expect(repository.updates, isEmpty);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    notifier.dispose();
  });

  test('user local cache paints first and cloud remains authoritative',
      () async {
    SharedPreferences.setMockInitialValues({
      astraThemePrefsKeyForUser('user-a'): 'dark',
    });
    final cloud = Completer<String?>();
    final repository = _FakeThemeRepository(
      currentUserId: 'user-a',
      fetch: (_) => cloud.future,
    );
    final notifier = _notifier(repository);

    final loading = notifier.reloadForCurrentUser();
    await _waitUntil(() => repository.fetches.isNotEmpty);
    expect(notifier.state, AstraThemeMode.dark);

    cloud.complete('light');
    await loading;
    expect(notifier.state, AstraThemeMode.light);
    expect(
      (await SharedPreferences.getInstance())
          .getString(astraThemePrefsKeyForUser('user-a')),
      'light',
    );
    notifier.dispose();
  });

  test('dark toggle is immediate and persists light/dark wire values',
      () async {
    final repository = _FakeThemeRepository(currentUserId: 'user-a');
    final notifier = _notifier(repository);

    await notifier.setDarkMode(true);
    expect(notifier.state, AstraThemeMode.dark);
    await notifier.pendingPersistence;
    expect(
      (await SharedPreferences.getInstance())
          .getString(astraThemePrefsKeyForUser('user-a')),
      'dark',
    );
    expect(repository.updates.last, ('user-a', 'dark'));

    await notifier.setDarkMode(false);
    expect(notifier.state, AstraThemeMode.light);
    await notifier.pendingPersistence;
    expect(repository.updates.last, ('user-a', 'light'));
    notifier.dispose();
  });

  test('logout and account switch never reuse another account cache', () async {
    SharedPreferences.setMockInitialValues({
      astraThemePrefsKeyForUser('user-a'): 'dark',
      astraThemePrefsKeyForUser('user-b'): 'light',
    });
    final repository = _FakeThemeRepository(
      currentUserId: 'user-a',
      cloudValues: {'user-a': 'dark', 'user-b': 'light'},
    );
    final notifier = _notifier(repository);

    await notifier.reloadForCurrentUser();
    expect(notifier.state, AstraThemeMode.dark);

    repository.currentUserId = null;
    await notifier.reloadForCurrentUser();
    expect(notifier.state, AstraThemeMode.light);

    repository.currentUserId = 'user-b';
    await notifier.reloadForCurrentUser();
    expect(notifier.state, AstraThemeMode.light);

    repository.currentUserId = 'user-a';
    await notifier.reloadForCurrentUser();
    expect(notifier.state, AstraThemeMode.dark);
    notifier.dispose();
  });

  test('persisted dark and light choices survive notifier restart', () async {
    final repository = _FakeThemeRepository(
      currentUserId: 'user-a',
      cloudValues: {'user-a': 'dark'},
    );
    final first = _notifier(repository);

    await first.setDarkMode(true);
    await first.pendingPersistence;
    first.dispose();

    final darkRestart = _notifier(repository);
    await darkRestart.reloadForCurrentUser();
    expect(darkRestart.state, AstraThemeMode.dark);

    await darkRestart.setDarkMode(false);
    await darkRestart.pendingPersistence;
    repository.cloudValues['user-a'] = 'light';
    darkRestart.dispose();

    final lightRestart = _notifier(repository);
    await lightRestart.reloadForCurrentUser();
    expect(lightRestart.state, AstraThemeMode.light);
    lightRestart.dispose();
  });

  test('late user A cloud response cannot overwrite user B appearance',
      () async {
    final aCloud = Completer<String?>();
    final bCloud = Completer<String?>();
    final repository = _FakeThemeRepository(
      currentUserId: 'user-a',
      fetch: (userId) => userId == 'user-a' ? aCloud.future : bCloud.future,
    );
    final notifier = _notifier(repository);

    final loadingA = notifier.reloadForCurrentUser();
    await _waitUntil(() => repository.fetches.contains('user-a'));
    repository.currentUserId = 'user-b';
    final loadingB = notifier.reloadForCurrentUser();
    await _waitUntil(() => repository.fetches.contains('user-b'));

    bCloud.complete('light');
    await loadingB;
    aCloud.complete('dark');
    await loadingA;

    expect(notifier.state, AstraThemeMode.light);
    notifier.dispose();
  });
}

AstraThemeNotifier _notifier(_FakeThemeRepository repository) =>
    AstraThemeNotifier(repository: repository, autoLoad: false);

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 50 && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _FakeThemeRepository implements AstraThemeRepository {
  _FakeThemeRepository({
    this.currentUserId,
    this.cloudValues = const {},
    Future<String?> Function(String userId)? fetch,
  }) : _fetch = fetch;

  @override
  String? currentUserId;
  final Map<String, String?> cloudValues;
  final Future<String?> Function(String userId)? _fetch;
  final List<String> fetches = [];
  final List<(String, String)> updates = [];

  @override
  Future<String?> fetchThemePreference(String expectedUserId) async {
    fetches.add(expectedUserId);
    final fetch = _fetch;
    if (fetch != null) return fetch(expectedUserId);
    return cloudValues[expectedUserId];
  }

  @override
  Future<void> updateThemePreference(
    String expectedUserId,
    String preference,
  ) async {
    updates.add((expectedUserId, preference));
  }
}
