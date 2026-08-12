import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/hobbies/data/hobbies_repository.dart';
import 'package:mindful_journal/features/hobbies/presentation/providers/hobbies_providers.dart';

void main() {
  test('first selection survives local and cloud initialization', () async {
    final local = Completer<Set<String>>();
    final cloud = Completer<Set<String>>();
    final persistence = _FakeHobbiesPersistence(
      local: local.future,
      cloud: cloud.future,
    );
    final notifier = HobbiesNotifier(persistence);

    final toggle = notifier.toggle('reading');
    expect(notifier.state, {'reading'});

    local.complete({'walking'});
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state, {'walking', 'reading'});

    cloud.complete({'walking'});
    await toggle;

    expect(notifier.state, {'walking', 'reading'});
    expect(persistence.saved.single, {'walking', 'reading'});
    notifier.dispose();
  });

  test('selection removal made during cloud sync is not restored', () async {
    final cloud = Completer<Set<String>>();
    final persistence = _FakeHobbiesPersistence(
      local: Future.value({'reading'}),
      cloud: cloud.future,
    );
    final notifier = HobbiesNotifier(persistence);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state, {'reading'});

    final remove = notifier.remove('reading');
    expect(notifier.state, isEmpty);

    cloud.complete({'reading', 'walking'});
    await remove;

    expect(notifier.state, {'walking'});
    expect(persistence.saved.single, {'walking'});
    notifier.dispose();
  });

  test('multiple selections persist the latest local state in order', () async {
    final persistence = _FakeHobbiesPersistence(
      local: Future.value({}),
      cloud: Future.value({}),
    );
    final notifier = HobbiesNotifier(persistence);

    await Future.wait([
      notifier.toggle('reading'),
      notifier.toggle('walking'),
    ]);

    expect(notifier.state, {'reading', 'walking'});
    expect(persistence.saved.last, {'reading', 'walking'});
    notifier.dispose();
  });
}

class _FakeHobbiesPersistence implements HobbiesPersistence {
  _FakeHobbiesPersistence({required this.local, required this.cloud});

  final Future<Set<String>> local;
  final Future<Set<String>> cloud;
  final List<Set<String>> saved = [];

  @override
  Future<Set<String>> load() => local;

  @override
  Future<void> save(Set<String> hobbies) async {
    saved.add({...hobbies});
  }

  @override
  Future<Set<String>> syncHobbiesWithSupabase() => cloud;
}
