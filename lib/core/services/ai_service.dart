import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Failure signal for [AiService] calls — kept string-free so the
/// presentation layer maps it to a warm, localized message rather than
/// showing anything the Edge Function or network layer returned directly.
class AiServiceException implements Exception {
  const AiServiceException();
}

/// Talks to the `luma-chat` Supabase Edge Function, which is the only
/// place the Gemini API key is ever used. This service never talks to
/// Gemini directly — it just forwards the user's message (and optional
/// mood/journal context) and returns Luma's reply.
class AiService {
  AiService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _sessionReadyTimeout = Duration(seconds: 5);

  /// Session restore (app cold start) and sign-in both update
  /// [GoTrueClient.currentSession] slightly after their triggering call
  /// returns, so a message sent in that window would otherwise see a null
  /// session. This waits for [GoTrueClient.onAuthStateChange]'s replayed
  /// initial/current state before giving up.
  Future<bool> ensureSessionReady() async {
    if (_client.auth.currentSession != null) return true;
    try {
      final state = await _client.auth.onAuthStateChange
          .firstWhere((state) => state.session != null)
          .timeout(_sessionReadyTimeout);
      return state.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<String> sendLumaMessage({
    required String message,
    required String language,
    String? context,
  }) async {
    await ensureSessionReady();
    final accessToken = _client.auth.currentSession?.accessToken;
    debugPrint('[AiService] sendLumaMessage called; accessToken present: ${accessToken != null}');
    if (accessToken == null) {
      debugPrint('[AiService] no access token — aborting before HTTP call, throwing AiServiceException');
      throw const AiServiceException();
    }

    try {
      debugPrint('[AiService] about to call _client.functions.invoke("luma-chat")');
      final response = await _client.functions.invoke(
        'luma-chat',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'message': message,
          'language': language,
          if (context != null && context.trim().isNotEmpty) 'context': context.trim(),
        },
      );

      final data = response.data;
      final reply = data is Map ? data['reply'] : null;
      if (reply is String && reply.trim().isNotEmpty) {
        return reply.trim();
      }
      throw const AiServiceException();
    } on AiServiceException {
      rethrow;
    } catch (_) {
      throw const AiServiceException();
    }
  }
}
