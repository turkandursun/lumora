import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/journal_tone_service.dart';
import 'package:mindful_journal/features/journal/domain/journal_tone_analysis.dart';

void main() {
  test('sends only text and normalized locale with the bearer token', () async {
    String? capturedToken;
    Map<String, dynamic>? capturedBody;
    final service = JournalToneService.testing(
      accessTokenProvider: () async => 'access-token',
      functionInvoker: (token, body) async {
        capturedToken = token;
        capturedBody = body;
        return {
          'tone': 'positive',
          'confidence': 0.91,
          'message': 'Bugünkü yazında sıcak ve rahat bir ton hissediliyor.',
          'show_wellness_suggestions': false,
          'suggestions': <String>[],
        };
      },
    );

    final result = await service.analyze(
      text: 'Bugün arkadaşlarımla güzel bir gün geçirdim.',
      locale: 'tr-TR',
    );

    expect(capturedToken, 'access-token');
    expect(capturedBody, {
      'text': 'Bugün arkadaşlarımla güzel bir gün geçirdim.',
      'locale': 'tr',
    });
    expect(result.tone, JournalTone.positive);
  });

  test('unsupported locale falls back to English', () async {
    Map<String, dynamic>? capturedBody;
    final service = JournalToneService.testing(
      accessTokenProvider: () async => 'access-token',
      functionInvoker: (_, body) async {
        capturedBody = body;
        return {
          'tone': 'neutral',
          'confidence': 0.6,
          'message': 'The writing has a mostly steady and neutral tone.',
          'show_wellness_suggestions': false,
          'suggestions': <String>[],
        };
      },
    );

    await service.analyze(
      text: 'Una nota suficientemente larga para analizar.',
      locale: 'it-IT',
    );

    expect(capturedBody?['locale'], 'en');
  });

  test('missing auth and malformed responses use controlled exception',
      () async {
    final unauthenticated = JournalToneService.testing(
      accessTokenProvider: () async => null,
      functionInvoker: (_, __) async => const <String, dynamic>{},
    );
    expect(
      () => unauthenticated.analyze(
        text: 'This is long enough to analyze.',
        locale: 'en',
      ),
      throwsA(isA<JournalToneServiceException>()),
    );

    final malformed = JournalToneService.testing(
      accessTokenProvider: () async => 'access-token',
      functionInvoker: (_, __) async => {'tone': 'unknown'},
    );
    expect(
      () => malformed.analyze(
        text: 'This is long enough to analyze.',
        locale: 'en',
      ),
      throwsA(isA<JournalToneServiceException>()),
    );
  });

  test('very short text is rejected before a function call', () async {
    var invoked = false;
    final service = JournalToneService.testing(
      accessTokenProvider: () async => 'access-token',
      functionInvoker: (_, __) async {
        invoked = true;
        return const <String, dynamic>{};
      },
    );

    expect(
      () => service.analyze(text: 'short', locale: 'en'),
      throwsA(isA<JournalToneServiceException>()),
    );
    expect(invoked, isFalse);
  });
}
