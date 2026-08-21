import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/features/auth/domain/registration_flow_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('registration steps keep mood-reason-hobbies ordering', () {
    expect(
      RegistrationStep.values,
      [
        RegistrationStep.nameEntry,
        RegistrationStep.themeSelect,
        RegistrationStep.storytellingOnboarding,
        RegistrationStep.mood,
        RegistrationStep.dailyReflection,
        RegistrationStep.hobbies,
        RegistrationStep.firstLumaGreeting,
      ],
    );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('begin, advance and complete persist the user-scoped step', () async {
    final store = RegistrationFlowStore();
    final name = await store.begin('user-a');
    expect(name.step, RegistrationStep.nameEntry);

    final theme = await store.advance(name, RegistrationStep.themeSelect);
    expect(store.allows(theme), isTrue);
    var prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(RegistrationFlowStore.markerKey('user-a')),
      RegistrationStep.themeSelect.wireValue,
    );

    await store.complete(theme);
    prefs = await SharedPreferences.getInstance();
    expect(store.hasActiveIntentFor('user-a'), isFalse);
    expect(
      prefs.containsKey(RegistrationFlowStore.markerKey('user-a')),
      isFalse,
    );
  });

  test('restore resumes only the requested account', () async {
    SharedPreferences.setMockInitialValues({
      RegistrationFlowStore.markerKey('user-a'):
          RegistrationStep.dailyReflection.wireValue,
      RegistrationFlowStore.markerKey('user-b'):
          RegistrationStep.themeSelect.wireValue,
    });
    final store = RegistrationFlowStore();

    final a = await store.restore('user-a');
    expect(a?.step, RegistrationStep.dailyReflection);
    expect(store.hasActiveIntentFor('user-b'), isFalse);

    final b = await store.restore('user-b');
    expect(b?.step, RegistrationStep.themeSelect);
    expect(store.hasActiveIntentFor('user-a'), isFalse);
    expect(store.hasActiveIntentFor('user-b'), isTrue);
  });

  test('logout clears active and persisted registration for that user',
      () async {
    final store = RegistrationFlowStore();
    await store.begin('user-a');

    await store.clearForUser('user-a');

    final prefs = await SharedPreferences.getInstance();
    expect(store.hasActiveIntentFor('user-a'), isFalse);
    expect(
      prefs.containsKey(RegistrationFlowStore.markerKey('user-a')),
      isFalse,
    );
  });

  test('legacy true marker resumes at name while false marker is ignored',
      () async {
    SharedPreferences.setMockInitialValues({
      RegistrationFlowStore.markerKey('user-a'): true,
      RegistrationFlowStore.markerKey('user-b'): false,
    });
    final store = RegistrationFlowStore();

    expect(
      (await store.restore('user-a'))?.step,
      RegistrationStep.nameEntry,
    );
    expect(await store.restore('user-b'), isNull);
  });

  test('OAuth signup origin is one-shot and expires', () async {
    final now = DateTime.utc(2026, 8, 17, 12);
    var clock = now;
    final store = RegistrationFlowStore(now: () => clock);

    await store.markOAuthSignupAttempt();
    expect(await store.consumeOAuthSignupAttempt(), isTrue);
    expect(await store.consumeOAuthSignupAttempt(), isFalse);

    await store.markOAuthSignupAttempt();
    clock = now.add(const Duration(minutes: 11));
    expect(await store.consumeOAuthSignupAttempt(), isFalse);
  });

  test('OAuth signup origin timestamp survives a full-page callback', () async {
    final startedAt = DateTime.utc(2026, 8, 21, 12, 30);
    final store = RegistrationFlowStore(now: () => startedAt);

    await store.markOAuthSignupAttempt();

    expect(
      await store.consumeOAuthSignupAttemptStartedAt(),
      startedAt,
    );
    expect(await store.consumeOAuthSignupAttemptStartedAt(), isNull);
  });

  test('OAuth login origin is one-shot, separate from signup, and expires',
      () async {
    var now = DateTime.utc(2026, 8, 21, 12);
    final store = RegistrationFlowStore(now: () => now);

    await store.markOAuthLoginAttempt();
    expect(await store.consumeOAuthSignupAttempt(), isFalse);
    expect(await store.consumeOAuthLoginAttempt(), isTrue);
    expect(await store.consumeOAuthLoginAttempt(), isFalse);

    await store.markOAuthLoginAttempt();
    now = now.add(const Duration(minutes: 11));
    expect(await store.consumeOAuthLoginAttempt(), isFalse);
  });

  test('mismatched stale intent cannot advance another account', () async {
    final store = RegistrationFlowStore();
    final a = await store.begin('user-a');
    await store.begin('user-b');

    await expectLater(
      store.advance(a, RegistrationStep.themeSelect),
      throwsA(isA<RegistrationIntentMismatchException>()),
    );
  });
}
