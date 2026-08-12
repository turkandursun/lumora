import '../../../../core/services/journal_tone_service.dart';
import '../../domain/journal_tone_analysis.dart';

typedef JournalTonePresentationCallback = Future<void> Function(
  JournalToneAnalysis analysis,
);

/// Owns request generation for journal-tone feedback. A later request always
/// invalidates an older response, and service failures stay isolated from the
/// journal persistence flow.
class JournalToneFeedbackController {
  JournalToneFeedbackController(this._service);

  final JournalToneService _service;
  int _generation = 0;
  bool _disposed = false;

  Future<void> analyzeSavedJournal({
    required String text,
    required String locale,
    required bool Function() canPresent,
    required JournalTonePresentationCallback onAnalysisReady,
  }) async {
    final requestGeneration = ++_generation;
    try {
      final analysis = await _service.analyze(text: text, locale: locale);
      if (_disposed || requestGeneration != _generation || !canPresent()) {
        return;
      }
      await onAnalysisReady(analysis);
    } catch (_) {
      // AI feedback is optional. Auth, network, Gemini and parsing failures
      // must never escape into the already-successful journal save flow.
    }
  }

  /// Returns the tone analysis, or `null` if it was superseded by a newer
  /// request or failed for any reason. Used by the loading-first feedback
  /// sheet, which shows a "Luma is reading…" state while this resolves so the
  /// user immediately understands a reflection is on its way.
  Future<JournalToneAnalysis?> requestAnalysis({
    required String text,
    required String locale,
  }) async {
    final requestGeneration = ++_generation;
    try {
      final analysis = await _service.analyze(text: text, locale: locale);
      if (_disposed || requestGeneration != _generation) return null;
      return analysis;
    } catch (_) {
      // AI feedback is optional; every failure resolves to a quiet null.
      return null;
    }
  }

  void invalidate() => _generation++;

  void dispose() {
    _disposed = true;
    _generation++;
  }
}

bool shouldAnalyzeSavedJournal({
  required bool isNewEntry,
  required bool crisisSupportTriggered,
}) =>
    isNewEntry && !crisisSupportTriggered;

/// Runs one non-critical post-save operation behind its own error boundary.
/// The optional callback receives only the error type at the presentation
/// layer; journal text or other sensitive values are never included.
Future<void> runJournalSecondaryEffectSafely(
  Future<void> Function() effect, {
  void Function(Object error)? onError,
}) async {
  try {
    await effect();
  } catch (error) {
    onError?.call(error);
  }
}
