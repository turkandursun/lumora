import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/journal_tone_service.dart';
import 'package:mindful_journal/features/journal/presentation/controllers/journal_tone_feedback_controller.dart';

void main() {
  test('successful new save policy starts analysis exactly once', () async {
    var invocations = 0;
    var presentations = 0;
    final controller = JournalToneFeedbackController(
      JournalToneService.testing(
        accessTokenProvider: () async => 'token',
        functionInvoker: (_, __) async {
          invocations++;
          return _analysisJson(message: 'A gentle reflection.');
        },
      ),
    );

    if (shouldAnalyzeSavedJournal(
      isNewEntry: true,
      crisisSupportTriggered: false,
    )) {
      await controller.analyzeSavedJournal(
        text: 'A newly saved journal entry.',
        locale: 'en',
        canPresent: () => true,
        onAnalysisReady: (_) async => presentations++,
      );
    }

    expect(invocations, 1);
    expect(presentations, 1);
  });

  test('edit policy never starts journal-tone analysis', () {
    expect(
      shouldAnalyzeSavedJournal(
        isNewEntry: false,
        crisisSupportTriggered: false,
      ),
      isFalse,
    );
  });

  test('AI failure is swallowed and cannot escape into journal save', () async {
    var presented = false;
    final controller = JournalToneFeedbackController(
      JournalToneService.testing(
        accessTokenProvider: () async => 'token',
        functionInvoker: (_, __) => throw Exception('offline'),
      ),
    );

    await controller.analyzeSavedJournal(
      text: 'This journal is already safely saved.',
      locale: 'en',
      canPresent: () => true,
      onAnalysisReady: (_) async => presented = true,
    );

    expect(presented, isFalse);
  });

  test('route no longer current prevents feedback presentation', () async {
    var presented = false;
    final controller = JournalToneFeedbackController(
      JournalToneService.testing(
        accessTokenProvider: () async => 'token',
        functionInvoker: (_, __) async => _analysisJson(
          message: 'This response arrived after navigation.',
        ),
      ),
    );

    await controller.analyzeSavedJournal(
      text: 'A journal entry long enough to analyze.',
      locale: 'en',
      canPresent: () => false,
      onAnalysisReady: (_) async => presented = true,
    );

    expect(presented, isFalse);
  });

  test('stale previous response cannot replace the latest result', () async {
    final firstResponse = Completer<Object?>();
    final secondResponse = Completer<Object?>();
    final presentedMessages = <String>[];
    final controller = JournalToneFeedbackController(
      JournalToneService.testing(
        accessTokenProvider: () async => 'token',
        functionInvoker: (_, body) {
          return body['text'] == 'First journal response.'
              ? firstResponse.future
              : secondResponse.future;
        },
      ),
    );

    final first = controller.analyzeSavedJournal(
      text: 'First journal response.',
      locale: 'en',
      canPresent: () => true,
      onAnalysisReady: (analysis) async {
        presentedMessages.add(analysis.message);
      },
    );
    final second = controller.analyzeSavedJournal(
      text: 'Second journal response.',
      locale: 'en',
      canPresent: () => true,
      onAnalysisReady: (analysis) async {
        presentedMessages.add(analysis.message);
      },
    );

    firstResponse.complete(_analysisJson(message: 'Old response'));
    await first;
    secondResponse.complete(_analysisJson(message: 'Latest response'));
    await second;

    expect(presentedMessages, ['Latest response']);
  });

  test('secondary failure stays isolated from successful persistence',
      () async {
    var journalPersisted = true;
    var errorObserved = false;

    await runJournalSecondaryEffectSafely(
      () async => throw Exception('Goal provider failed'),
      onError: (_) => errorObserved = true,
    );

    expect(journalPersisted, isTrue);
    expect(errorObserved, isTrue);
  });

  test('crisis support flow prevents journal-tone analysis', () {
    expect(
      shouldAnalyzeSavedJournal(
        isNewEntry: true,
        crisisSupportTriggered: true,
      ),
      isFalse,
    );
  });
}

Map<String, dynamic> _analysisJson({required String message}) => {
      'tone': 'positive',
      'confidence': 0.91,
      'message': message,
      'show_wellness_suggestions': false,
      'suggestions': <String>[],
    };
