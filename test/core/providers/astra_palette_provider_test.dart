import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/providers/astra_palette_provider.dart';
import 'package:mindful_journal/features/profile/data/astra_palette_repository.dart';
import 'package:mindful_journal/theme/astra_design_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('wire values are stable snake_case and invalid values are safe', () {
    expect(AstraThemeId.softLilacMist.wireValue, 'soft_lilac_mist');
    expect(AstraThemeId.dustyRoseHaze.wireValue, 'dusty_rose_haze');
    expect(AstraThemeId.sageVeil.wireValue, 'sage_veil');
    expect(AstraThemeId.mutedSkyBloom.wireValue, 'muted_sky_bloom');
    expect(AstraThemeId.apricotCloud.wireValue, 'apricot_cloud');
    expect(AstraThemeId.berrySand.wireValue, 'berry_sand');
    expect(AstraThemeId.smokyTealAura.wireValue, 'smoky_teal_aura');
    expect(
      AstraThemeId.fromWireValue('not-a-palette'),
      AstraThemeId.softLilacMist,
    );
  });

  test('auth null always uses default and never migrates global v1 key',
      () async {
    SharedPreferences.setMockInitialValues({
      astraLegacyPalettePrefsKey: 'berrySand',
      astraPalettePrefsKeyForUser('user-a'): 'berry_sand',
    });
    final repository = _FakePaletteRepository();
    final notifier = _notifier(repository);

    await notifier.reloadForCurrentUser();

    expect(notifier.state, AstraThemeId.softLilacMist);
    expect(repository.fetches, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(astraLegacyPalettePrefsKey), isFalse);
    expect(
      prefs.getString(astraPalettePrefsKeyForUser('user-a')),
      'berry_sand',
    );
    notifier.dispose();
  });

  test('user A local cache paints first and cloud remains authoritative',
      () async {
    SharedPreferences.setMockInitialValues({
      astraPalettePrefsKeyForUser('user-a'): 'sage_veil',
    });
    final cloud = Completer<String?>();
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      fetch: (_) => cloud.future,
    );
    final notifier = _notifier(repository);

    final loading = notifier.reloadForCurrentUser();
    await _waitUntil(() => repository.fetches.isNotEmpty);
    expect(notifier.state, AstraThemeId.sageVeil);

    cloud.complete('apricot_cloud');
    await loading;

    expect(notifier.state, AstraThemeId.apricotCloud);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(astraPalettePrefsKeyForUser('user-a')),
      'apricot_cloud',
    );
    notifier.dispose();
  });

  test('local bootstrap completes without waiting for cloud', () async {
    SharedPreferences.setMockInitialValues({
      astraPalettePrefsKeyForUser('user-a'): 'berry_sand',
    });
    final cloud = Completer<String?>();
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      fetch: (_) => cloud.future,
    );
    final notifier = AstraPaletteNotifier(
      repository: repository,
      autoLoad: false,
    );
    final loading = notifier.reloadForCurrentUser();

    await notifier.localBootstrapCompleted;

    expect(notifier.state, AstraThemeId.berrySand);
    expect(cloud.isCompleted, isFalse);
    cloud.complete('berry_sand');
    await loading;
    notifier.dispose();
  });

  test('cloud failure leaves the fast local cache active', () async {
    SharedPreferences.setMockInitialValues({
      astraPalettePrefsKeyForUser('user-a'): 'muted_sky_bloom',
    });
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      fetch: (_) => Future<String?>.error(StateError('offline')),
    );
    final notifier = _notifier(repository);

    await notifier.reloadForCurrentUser();

    expect(notifier.state, AstraThemeId.mutedSkyBloom);
    notifier.dispose();
  });

  test('logout resets active palette without reading account cache', () async {
    SharedPreferences.setMockInitialValues({
      astraPalettePrefsKeyForUser('user-a'): 'berry_sand',
    });
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      cloudValues: {'user-a': 'berry_sand'},
    );
    final notifier = _notifier(repository);
    await notifier.reloadForCurrentUser();
    expect(notifier.state, AstraThemeId.berrySand);

    repository.currentUserId = null;
    await notifier.reloadForCurrentUser();

    expect(notifier.state, AstraThemeId.softLilacMist);
    notifier.dispose();
  });

  test('account switch loads only B cache and cloud', () async {
    SharedPreferences.setMockInitialValues({
      astraPalettePrefsKeyForUser('user-a'): 'berry_sand',
      astraPalettePrefsKeyForUser('user-b'): 'sage_veil',
    });
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      cloudValues: {
        'user-a': 'berry_sand',
        'user-b': 'smoky_teal_aura',
      },
    );
    final notifier = _notifier(repository);
    await notifier.reloadForCurrentUser();
    expect(notifier.state, AstraThemeId.berrySand);

    repository.currentUserId = 'user-b';
    await notifier.reloadForCurrentUser();

    expect(notifier.state, AstraThemeId.smokyTealAura);
    expect(repository.fetches, ['user-a', 'user-b']);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(astraPalettePrefsKeyForUser('user-b')),
      'smoky_teal_aura',
    );
    notifier.dispose();
  });

  test('late A cloud response cannot overwrite B state', () async {
    final aCloud = Completer<String?>();
    final bCloud = Completer<String?>();
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      fetch: (userId) => userId == 'user-a' ? aCloud.future : bCloud.future,
    );
    final notifier = _notifier(repository);

    final loadingA = notifier.reloadForCurrentUser();
    await _waitUntil(() => repository.fetches.contains('user-a'));
    repository.currentUserId = 'user-b';
    final loadingB = notifier.reloadForCurrentUser();
    await _waitUntil(() => repository.fetches.contains('user-b'));

    bCloud.complete('dusty_rose_haze');
    await loadingB;
    expect(notifier.state, AstraThemeId.dustyRoseHaze);

    aCloud.complete('berry_sand');
    await loadingA;
    expect(notifier.state, AstraThemeId.dustyRoseHaze);
    notifier.dispose();
  });

  test('selection is immediate and persists only for current user', () async {
    final repository = _FakePaletteRepository(currentUserId: 'user-a');
    final notifier = _notifier(repository);

    final selection = notifier.select(AstraThemeId.smokyTealAura);
    expect(notifier.state, AstraThemeId.smokyTealAura);
    await selection;
    await notifier.pendingPersistence;

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(astraPalettePrefsKeyForUser('user-a')),
      'smoky_teal_aura',
    );
    expect(repository.updates, [('user-a', 'smoky_teal_aura')]);
    notifier.dispose();
  });

  test('auth-null selection cannot change or persist the pre-auth default',
      () async {
    final repository = _FakePaletteRepository();
    final notifier = _notifier(repository);

    await notifier.select(AstraThemeId.berrySand);

    expect(notifier.state, AstraThemeId.softLilacMist);
    expect(repository.updates, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
    notifier.dispose();
  });

  test('invalid cloud palette normalizes state and local cache to default',
      () async {
    SharedPreferences.setMockInitialValues({
      astraPalettePrefsKeyForUser('user-a'): 'sage_veil',
    });
    final repository = _FakePaletteRepository(
      currentUserId: 'user-a',
      cloudValues: {'user-a': 'invalid'},
    );
    final notifier = _notifier(repository);

    await notifier.reloadForCurrentUser();

    expect(notifier.state, AstraThemeId.softLilacMist);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(astraPalettePrefsKeyForUser('user-a')),
      'soft_lilac_mist',
    );
    notifier.dispose();
  });
}

AstraPaletteNotifier _notifier(_FakePaletteRepository repository) {
  return AstraPaletteNotifier(
    repository: repository,
    autoLoad: false,
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 50 && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _FakePaletteRepository implements AstraPaletteRepository {
  _FakePaletteRepository({
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
  Future<String?> fetchPaletteId(String expectedUserId) async {
    fetches.add(expectedUserId);
    final fetch = _fetch;
    if (fetch != null) return fetch(expectedUserId);
    return cloudValues[expectedUserId];
  }

  @override
  Future<void> updatePaletteId(
    String expectedUserId,
    String paletteId,
  ) async {
    updates.add((expectedUserId, paletteId));
  }
}
