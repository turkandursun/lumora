import 'package:supabase_flutter/supabase_flutter.dart';

class DailyAiQuestionsException implements Exception {
  const DailyAiQuestionsException();
}

/// Calls the authenticated `daily-ai-questions` Edge Function and returns the
/// five questions cached/generated for the current user and calendar day.
class DailyAiQuestionsService {
  DailyAiQuestionsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _sessionReadyTimeout = Duration(seconds: 5);

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

  Future<List<String>> fetchQuestions({
    required String language,
    String? recentMood,
    String? recentJournalSnippet,
    String? recentDreamSnippet,
  }) async {
    await ensureSessionReady();
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) throw const DailyAiQuestionsException();

    try {
      final response = await _client.functions.invoke(
        'daily-ai-questions',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'language': language,
          if (recentMood != null && recentMood.trim().isNotEmpty)
            'recentMood': recentMood.trim(),
          if (recentJournalSnippet != null &&
              recentJournalSnippet.trim().isNotEmpty)
            'recentJournalSnippet': recentJournalSnippet.trim(),
          if (recentDreamSnippet != null &&
              recentDreamSnippet.trim().isNotEmpty)
            'recentDreamSnippet': recentDreamSnippet.trim(),
        },
      );

      final data = response.data;
      final rawQuestions = data is Map ? data['questions'] : null;
      if (rawQuestions is! List || rawQuestions.length != 5) {
        throw const DailyAiQuestionsException();
      }

      final questions = rawQuestions
          .whereType<String>()
          .map((question) => question.trim())
          .where((question) => question.isNotEmpty)
          .toList(growable: false);
      if (questions.length != 5) throw const DailyAiQuestionsException();
      return questions;
    } on DailyAiQuestionsException {
      rethrow;
    } catch (_) {
      throw const DailyAiQuestionsException();
    }
  }
}
