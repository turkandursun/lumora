import 'package:supabase_flutter/supabase_flutter.dart';

/// The reconciled "chairman" synthesis returned by the `dilemma-coach` Edge
/// Function after the user works their real dilemma through the decision
/// frameworks. It reflects, it never dictates.
class DilemmaSynthesis {
  const DilemmaSynthesis({
    required this.title,
    required this.reflection,
    required this.lean,
    required this.question,
  });

  /// A short name for the tension underneath the dilemma.
  final String title;

  /// The warm 2–4 sentence reconciliation of the user's own answers.
  final String reflection;

  /// A gentle, hedged sentence on where their answers seem to lean.
  final String lean;

  /// One final empowering question to sit with.
  final String question;

  factory DilemmaSynthesis.fromJson(Map<String, dynamic> json) {
    String req(String key) {
      final v = json[key];
      if (v is! String || v.trim().isEmpty) {
        throw const DilemmaCoachException();
      }
      return v.trim();
    }

    return DilemmaSynthesis(
      title: req('title'),
      reflection: req('reflection'),
      lean: req('lean'),
      question: req('question'),
    );
  }
}

class DilemmaCoachException implements Exception {
  const DilemmaCoachException();
}

/// The answers a user gives across the decision-framework steps. Every field
/// except [dilemma] is optional — the synthesis works with whatever is shared.
class DilemmaInput {
  const DilemmaInput({
    required this.dilemma,
    this.optionA = '',
    this.optionB = '',
    this.widen = '',
    this.values = '',
    this.tenTen = '',
    this.regret = '',
    this.friend = '',
  });

  final String dilemma;
  final String optionA;
  final String optionB;
  final String widen;
  final String values;
  final String tenTen;
  final String regret;
  final String friend;
}

/// Talks to the `dilemma-coach` Supabase Edge Function, the only place the
/// Gemini key is used. Mirrors [AiService]'s session/transport handling.
class DilemmaCoachService {
  DilemmaCoachService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _sessionReadyTimeout = Duration(seconds: 5);

  Future<bool> ensureSessionReady() async {
    if (_client.auth.currentSession != null) return true;
    try {
      final state = await _client.auth.onAuthStateChange
          .firstWhere((s) => s.session != null)
          .timeout(_sessionReadyTimeout);
      return state.session != null;
    } catch (_) {
      return false;
    }
  }

  Future<DilemmaSynthesis> synthesize({
    required DilemmaInput input,
    required String language,
  }) async {
    await ensureSessionReady();
    final accessToken = _client.auth.currentSession?.accessToken;
    if (accessToken == null) throw const DilemmaCoachException();

    try {
      final response = await _client.functions.invoke(
        'dilemma-coach',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'dilemma': input.dilemma,
          'optionA': input.optionA,
          'optionB': input.optionB,
          'widen': input.widen,
          'values': input.values,
          'tenTen': input.tenTen,
          'regret': input.regret,
          'friend': input.friend,
          'locale': language,
        },
      );
      final data = response.data;
      if (data is Map) {
        return DilemmaSynthesis.fromJson(Map<String, dynamic>.from(data));
      }
      throw const DilemmaCoachException();
    } on DilemmaCoachException {
      rethrow;
    } catch (_) {
      throw const DilemmaCoachException();
    }
  }
}
