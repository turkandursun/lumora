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
