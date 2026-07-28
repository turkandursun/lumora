import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/app_lock_service.dart';
import 'package:mindful_journal/features/app_lock/domain/app_section.dart';
import 'package:mindful_journal/features/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:mindful_journal/features/app_lock/presentation/widgets/section_lock_gate.dart';
import 'package:mindful_journal/l10n/generated/app_localizations.dart';

/// In-memory stand-in for [AppLockService] — see the twin fake in
/// `app_lock_service_test.dart` for why only the storage-touching methods
/// are overridden.
class _InMemoryAppLockService extends AppLockService {
  String? _pin;
  Set<AppSection> _protected = {};

  @override
  Future<bool> hasPin() async => _pin != null;

  @override
  Future<void> setPin(String pin) async => _pin = pin;

  @override
  Future<bool> verifyPin(String pin) async => _pin != null && _pin == pin;

  @override
  Future<Set<AppSection>> getProtectedSections() async => _protected;

  @override
  Future<void> setSectionProtected(AppSection section, bool protected) async {
    _protected = protected ? {..._protected, section} : ({..._protected}..remove(section));
  }
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit).first);
    await tester.pump();
  }
  await tester.tap(find.byIcon(Icons.check_circle_rounded));
  await tester.pump();
}

void main() {
  late _InMemoryAppLockService service;

  Future<void> pumpGate(WidgetTester tester, {List<Override> extraOverrides = const []}) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockServiceProvider.overrideWithValue(service),
          ...extraOverrides,
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SectionLockGate(
            section: AppSection.journalWriting,
            builder: _JournalContent.new,
          ),
        ),
      ),
    );
  }

  setUp(() {
    service = _InMemoryAppLockService();
  });

  testWidgets('section left unprotected: real content shows immediately, no PIN screen',
      (tester) async {
    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(find.text('JOURNAL CONTENT'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets(
      'section toggled on: PIN screen shows INSTEAD of the real content, '
      'correct PIN reveals it', (tester) async {
    await service.setPin('1234');
    await service.setSectionProtected(AppSection.journalWriting, true);

    await pumpGate(tester);
    await tester.pumpAndSettle();

    // The real content must never be built while locked.
    expect(find.text('JOURNAL CONTENT'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await _enterPin(tester, '1234');
    await tester.pumpAndSettle();

    expect(find.text('JOURNAL CONTENT'), findsOneWidget);
  });

  testWidgets('wrong PIN does not unlock and reports attempts remaining', (tester) async {
    await service.setPin('1234');
    await service.setSectionProtected(AppSection.journalWriting, true);

    await pumpGate(tester);
    await tester.pumpAndSettle();

    await _enterPin(tester, '0000');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('JOURNAL CONTENT'), findsNothing);
    expect(find.text('Incorrect PIN. 4 attempts left.'), findsOneWidget);
  });

  testWidgets('locks out after 5 consecutive wrong guesses, even the correct PIN is rejected',
      (tester) async {
    await service.setPin('1234');
    await service.setSectionProtected(AppSection.journalWriting, true);

    await pumpGate(tester);
    await tester.pumpAndSettle();

    for (var i = 0; i < AppLockService.maxAttempts; i++) {
      await _enterPin(tester, '0000');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    // Now locked out — even the correct PIN must not unlock.
    await _enterPin(tester, '1234');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('JOURNAL CONTENT'), findsNothing);
  });

  testWidgets(
      'unlocking is session-scoped: a fresh ProviderScope (simulating a full app restart) '
      'locks again even though the PIN was already entered once', (tester) async {
    await service.setPin('1234');
    await service.setSectionProtected(AppSection.journalWriting, true);

    await pumpGate(tester);
    await tester.pumpAndSettle();
    await _enterPin(tester, '1234');
    await tester.pumpAndSettle();
    expect(find.text('JOURNAL CONTENT'), findsOneWidget);

    // Simulate a full app restart: unmount everything first (pumpWidget
    // alone would just reconcile into the *same* ProviderScope element,
    // keeping its container — and the in-memory unlock — alive), then
    // mount a brand-new tree with a brand-new (empty) sectionUnlockProvider.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(find.text('JOURNAL CONTENT'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });
}

class _JournalContent extends StatelessWidget {
  const _JournalContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('JOURNAL CONTENT')));
  }
}
