import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/journal/domain/journal_tone_analysis.dart';

class JournalToneServiceException implements Exception {
  const JournalToneServiceException();
}

typedef JournalToneFunctionInvoker = Future<Object?> Function(
  String accessToken,
  Map<String, dynamic> body,
);

/// Authenticated transport for the `journal-tone` Edge Function.
///
/// The service owns no journal persistence and never reads or writes mood
/// state. A failure is reported only through [JournalToneServiceException], so
/// callers can keep normal journal saving completely independent from AI.
class JournalToneService {
  JournalToneService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        _accessTokenProvider = null,
        _functionInvoker = null;

  @visibleForTesting
  JournalToneService.testing({
    required Future<String?> Function() accessTokenProvider,
    required JournalToneFunctionInvoker functionInvoker,
  })  : _client = null,
        _accessTokenProvider = accessTokenProvider,
        _functionInvoker = functionInvoker;

  static const _sessionReadyTimeout = Duration(seconds: 5);
  static const minimumTextLength = 10;
  static const maximumTextLength = 8000;
  static const supportedLocales = {'tr', 'en', 'de', 'es', 'fr'};

  final SupabaseClient? _client;
  final Future<String?> Function()? _accessTokenProvider;
  final JournalToneFunctionInvoker? _functionInvoker;

  Future<bool> ensureSessionReady() async {
    if (_accessTokenProvider != null) {
      return (await _accessTokenProvider()) != null;
    }
    final client = _client;
    if (client == null) return false;
    if (client.auth.currentSession != null) return true;
    try {
      final state = await client.auth.onAuthStateChange
          .firstWhere((state) => state.session != null)
          .timeout(_sessionReadyTimeout);
      return state.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<JournalToneAnalysis> analyze({
    required String text,
    required String locale,
  }) async {
    final preparedText = _prepareText(text);
    final normalizedLocale = _normalizeLocale(locale);

    final String? accessToken;
    if (_accessTokenProvider != null) {
      accessToken = await _accessTokenProvider();
    } else {
      await ensureSessionReady();
      accessToken = _client?.auth.currentSession?.accessToken;
    }
    if (accessToken == null) throw const JournalToneServiceException();

    try {
      final body = <String, dynamic>{
        'text': preparedText,
        'locale': normalizedLocale,
      };
      final Object? data;
      if (_functionInvoker != null) {
        data = await _functionInvoker(accessToken, body);
      } else {
        final client = _client;
        if (client == null) throw const JournalToneServiceException();
        final response = await client.functions.invoke(
          'journal-tone',
          headers: {'Authorization': 'Bearer $accessToken'},
          body: body,
        );
        data = response.data;
      }

      if (data is! Map) throw const JournalToneServiceException();
      return JournalToneAnalysis.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on JournalToneServiceException {
      rethrow;
    } catch (_) {
      throw const JournalToneServiceException();
    }
  }

  static String _prepareText(String value) {
    final trimmed = value.trim();
    if (trimmed.runes.length < minimumTextLength) {
      throw const JournalToneServiceException();
    }
    return String.fromCharCodes(trimmed.runes.take(maximumTextLength));
  }

  static String _normalizeLocale(String value) {
    final normalized = value.trim().toLowerCase().split(RegExp('[-_]')).first;
    return supportedLocales.contains(normalized) ? normalized : 'en';
  }
}
