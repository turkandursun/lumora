import 'package:supabase_flutter/supabase_flutter.dart';

/// Failure signal for [DreamInterpretationService] calls — kept string-free
/// so the presentation layer maps it to a warm, localized message rather
/// than showing anything the Edge Function or network layer returned
/// directly.
class DreamInterpretationException implements Exception {
  const DreamInterpretationException();
}

/// Talks to the `dream-interpret` Supabase Edge Function, which is the only
/// place the Gemini API key is ever used for dream interpretation. This
/// service never talks to Gemini directly — it forwards the dream's text
/// plus whatever local context is already on hand (detected symbols, mood
/// tag, reflection answers) and returns Luma's short reflection.
///
/// Entirely optional and additive: the local, offline symbol dictionary in
/// `dream_symbol_keywords.dart` keeps working exactly as before regardless
/// of whether this service is ever called.
class DreamInterpretationService {
  DreamInterpretationService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _sessionReadyTimeout = Duration(seconds: 5);

  /// Mirrors [AiService.ensureSessionReady] — session restore (app cold
  /// start) updates [GoTrueClient.currentSession] slightly after its
  /// triggering call returns, so an interpretation requested in that window
  /// would otherwise see a null session.
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

  Future<String> interpretDream({
    required String dreamText,
    required String language,
    List<String> symbols = const [],
    String? moodTag,
    String? firstThought,
    String? lifeConnection,
  }) async {
    await ensureSessionReady();
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) {
      throw const DreamInterpretationException();
    }

    try {
      final response = await _client.functions.invoke(
        'dream-interpret',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'dreamText': dreamText,
          'language': language,
          if (symbols.isNotEmpty) 'symbols': symbols,
          if (moodTag != null && moodTag.trim().isNotEmpty) 'moodTag': moodTag.trim(),
          if (firstThought != null && firstThought.trim().isNotEmpty) 'firstThought': firstThought.trim(),
          if (lifeConnection != null && lifeConnection.trim().isNotEmpty) 'lifeConnection': lifeConnection.trim(),
        },
      );

      final data = response.data;
      final interpretation = data is Map ? data['interpretation'] : null;
      if (interpretation is String && interpretation.trim().isNotEmpty) {
        return interpretation.trim();
      }
      throw const DreamInterpretationException();
    } on DreamInterpretationException {
      rethrow;
    } catch (_) {
      throw const DreamInterpretationException();
    }
  }
}
