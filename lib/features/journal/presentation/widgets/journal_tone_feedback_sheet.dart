import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_chat_sheet.dart';
import '../../domain/journal_tone_analysis.dart';

/// The fixed set of gentle next steps offered whenever a saved entry reads as a
/// low mood — Luma chat, a calm space, breathing and meditation. These are a
/// product decision, not model output, so the same supportive choices always
/// appear when someone is having a hard day.
const List<JournalWellnessSuggestion> _lowMoodSupportOptions = [
  JournalWellnessSuggestion.lumaChat,
  JournalWellnessSuggestion.calm,
  JournalWellnessSuggestion.breathing,
  JournalWellnessSuggestion.meditation,
];

/// The app's own star mascot (Luma), reused wherever the feedback flow needs a
/// star instead of a generic Material sparkle.
const String _lumaStarAsset = 'assets/images/luma_star_closed.png';

/// A quiet, dismissible reflection surface for the optional journal-tone
/// result. It deliberately makes no claim that the user's mood was detected.
class JournalToneFeedbackSheet extends StatelessWidget {
  const JournalToneFeedbackSheet({
    super.key,
    required this.analysis,
    required this.isDark,
  });

  final JournalToneAnalysis analysis;
  final bool isDark;

  /// Opens the feedback flow immediately in a "Luma is reading…" state, then
  /// swaps in the reflection once [analysisFuture] resolves (or a gentle
  /// fallback if it fails). Returning a suggestion routes to the matching
  /// wellbeing surface — or, for [JournalWellnessSuggestion.lumaChat], opens
  /// the Luma chat sheet.
  static Future<void> showAndNavigate({
    required BuildContext context,
    required Future<JournalToneAnalysis?> analysisFuture,
    required bool isDark,
  }) async {
    // Keep the router + a stable context before opening the modal. The sheet
    // route is disposed when it returns, so navigation must not depend on it.
    final router = GoRouter.of(context);
    final launchContext = context;
    final suggestion = await showModalBottomSheet<JournalWellnessSuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ToneFeedbackFlow(
        analysisFuture: analysisFuture,
        isDark: isDark,
      ),
    );
    if (suggestion == null) return;
    // Let the modal route finish its pop before changing the app location.
    await WidgetsBinding.instance.endOfFrame;
    if (suggestion == JournalWellnessSuggestion.lumaChat) {
      if (launchContext.mounted) {
        await LumaChatSheet.show(launchContext);
      }
      return;
    }
    // push (not go) so the destination keeps a back entry — otherwise the
    // wellbeing screen's top-left back button has nothing to pop.
    router.push(routeForSuggestion(suggestion));
  }

  static String routeForSuggestion(JournalWellnessSuggestion suggestion) =>
      switch (suggestion) {
        JournalWellnessSuggestion.breathing => AppRoutes.breathing,
        JournalWellnessSuggestion.meditation => AppRoutes.meditation,
        JournalWellnessSuggestion.calm => AppRoutes.calm,
        // Luma chat is a modal sheet, not a route; showAndNavigate handles it
        // before ever calling this.
        JournalWellnessSuggestion.lumaChat =>
          throw StateError('Luma chat has no navigable route.'),
      };

  @override
  Widget build(BuildContext context) {
    return _ToneSheetShell(
      isDark: isDark,
      child: _ToneResultBody(
        analysis: analysis,
        isDark: isDark,
        onSelect: (suggestion) => Navigator.of(context).pop(suggestion),
        onDismiss: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Stateful driver behind [JournalToneFeedbackSheet.showAndNavigate]: shows the
/// reading state instantly, then cross-fades to the reflection or a soft
/// fallback once the analysis resolves.
class _ToneFeedbackFlow extends StatefulWidget {
  const _ToneFeedbackFlow({
    required this.analysisFuture,
    required this.isDark,
  });

  final Future<JournalToneAnalysis?> analysisFuture;
  final bool isDark;

  @override
  State<_ToneFeedbackFlow> createState() => _ToneFeedbackFlowState();
}

class _ToneFeedbackFlowState extends State<_ToneFeedbackFlow> {
  JournalToneAnalysis? _analysis;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _await();
  }

  Future<void> _await() async {
    final analysis = await widget.analysisFuture;
    if (!mounted) return;
    setState(() {
      _analysis = analysis;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_loading) {
      body = _ToneLoadingBody(isDark: widget.isDark);
    } else if (_analysis == null) {
      body = _ToneFallbackBody(
        isDark: widget.isDark,
        onDismiss: () => Navigator.of(context).maybePop(),
      );
    } else {
      body = _ToneResultBody(
        analysis: _analysis!,
        isDark: widget.isDark,
        onSelect: (suggestion) => Navigator.of(context).pop(suggestion),
        onDismiss: () => Navigator.of(context).maybePop(),
      );
    }

    return _ToneSheetShell(
      isDark: widget.isDark,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_loading
              ? 'loading'
              : _analysis == null
                  ? 'fallback'
                  : 'result'),
          child: body,
        ),
      ),
    );
  }
}

/// Shared rounded-top container with a grabber — every phase (loading, result,
/// fallback) lives inside this so the sheet never visually "jumps".
class _ToneSheetShell extends StatelessWidget {
  const _ToneSheetShell({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = AstraKit.primary(context, isDark);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AstraKit.palette(context).surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: primary.withValues(alpha: 0.34)),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        AstraKit.muted(context, isDark).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// "Luma is reading your journal…" — shown instantly on seal so the user knows
/// a reflection is on its way.
class _ToneLoadingBody extends StatelessWidget {
  const _ToneLoadingBody({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final primary = AstraKit.primary(context, isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          _PulsingSparkle(color: primary),
          const SizedBox(height: 20),
          Text(
            isTr ? 'Luma günlüğünü okuyor…' : 'Luma is reading your journal…',
            textAlign: TextAlign.center,
            style: AstraKit.heading2(context, isDark, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Birkaç saniye içinde küçük bir yansıma hazır olacak.'
                : 'A small reflection will be ready in a few seconds.',
            textAlign: TextAlign.center,
            style: AstraKit.mutedText(context, isDark, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

/// Soft fallback if the analysis could not be produced — never an error, and
/// it always reassures the entry itself was saved.
class _ToneFallbackBody extends StatelessWidget {
  const _ToneFallbackBody({required this.isDark, required this.onDismiss});

  final bool isDark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final primary = AstraKit.primary(context, isDark);
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.13),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
          ),
          child: Icon(Icons.spa_rounded, size: 22, color: primary),
        ),
        const SizedBox(height: 16),
        Text(
          isTr
              ? 'Luma şu an düşüncelerini toparlayamadı — ama günlüğün güvende. 💜'
              : "Luma couldn't gather her thoughts right now — but your journal is safe. 💜",
          textAlign: TextAlign.center,
          style: AstraKit.body(context, isDark,
              fontSize: 15, fontWeight: FontWeight.w500, height: 1.5),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: onDismiss,
          child: Text(
            isTr ? 'Tamam' : 'Okay',
            style: AstraKit.mutedText(context, isDark,
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// The resolved reflection: Luma's message plus, for a low mood, four gentle
/// support options.
class _ToneResultBody extends StatelessWidget {
  const _ToneResultBody({
    required this.analysis,
    required this.isDark,
    required this.onSelect,
    required this.onDismiss,
  });

  final JournalToneAnalysis analysis;
  final bool isDark;
  final ValueChanged<JournalWellnessSuggestion> onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = AstraKit.primary(context, isDark);
    // A hard day always surfaces the same four supportive next steps, no matter
    // which suggestions (if any) the model returned.
    final showSupport = analysis.tone == JournalTone.lowMood;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.13),
                border: Border.all(color: primary.withValues(alpha: 0.25)),
              ),
              child: Image.asset(_lumaStarAsset, width: 22, height: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.journalToneFeedbackTitle,
                style: AstraKit.heading2(context, isDark, fontSize: 18),
              ),
            ),
            IconButton(
              key: const ValueKey('journal-tone-close'),
              tooltip: l10n.journalToneNotNow,
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded,
                  color: AstraKit.muted(context, isDark)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: isDark ? 0.09 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.20)),
          ),
          child: Text(
            analysis.message,
            key: const ValueKey('journal-tone-message'),
            style: AstraKit.body(
              context,
              isDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        if (showSupport) ...[
          const SizedBox(height: 20),
          Text(
            l10n.journalToneWellnessPrompt,
            style: AstraKit.body(context, isDark,
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final suggestion in _lowMoodSupportOptions) ...[
            _SuggestionButton(
              suggestion: suggestion,
              label: _labelForSuggestion(l10n, suggestion),
              isDark: isDark,
              primary: primary,
              onTap: () => onSelect(suggestion),
            ),
            const SizedBox(height: 9),
          ],
        ],
        const SizedBox(height: 4),
        TextButton(
          key: const ValueKey('journal-tone-not-now'),
          onPressed: onDismiss,
          child: Text(
            l10n.journalToneNotNow,
            style: AstraKit.mutedText(context, isDark,
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  static String _labelForSuggestion(
    AppLocalizations l10n,
    JournalWellnessSuggestion suggestion,
  ) =>
      switch (suggestion) {
        JournalWellnessSuggestion.breathing => l10n.breathingTitle,
        JournalWellnessSuggestion.meditation => l10n.homeFeatureMeditationTitle,
        JournalWellnessSuggestion.calm => l10n.journalToneCalmAction,
        JournalWellnessSuggestion.lumaChat => l10n.lumaChatTitle,
      };
}

/// Gently pulsing sparkle used in the loading state.
class _PulsingSparkle extends StatefulWidget {
  const _PulsingSparkle({required this.color});

  final Color color;

  @override
  State<_PulsingSparkle> createState() => _PulsingSparkleState();
}

class _PulsingSparkleState extends State<_PulsingSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.10 + 0.06 * t),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.18 + 0.22 * t),
                blurRadius: 14 + 12 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: Transform.scale(
            scale: 0.9 + 0.18 * t,
            child: Image.asset(_lumaStarAsset, width: 30, height: 30),
          ),
        );
      },
    );
  }
}

class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({
    required this.suggestion,
    required this.label,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final JournalWellnessSuggestion suggestion;
  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (suggestion) {
      JournalWellnessSuggestion.breathing => Icons.air_rounded,
      JournalWellnessSuggestion.meditation => Icons.self_improvement_rounded,
      JournalWellnessSuggestion.calm => Icons.spa_rounded,
      JournalWellnessSuggestion.lumaChat => Icons.chat_bubble_rounded,
    };
    return OutlinedButton.icon(
      key: ValueKey('journal-tone-suggestion-${suggestion.name}'),
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        backgroundColor: primary.withValues(alpha: 0.07),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: primary.withValues(alpha: 0.34)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: AstraKit.body(
          context,
          isDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}
