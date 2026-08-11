import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../domain/journal_tone_analysis.dart';

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

  static Future<JournalWellnessSuggestion?> show({
    required BuildContext context,
    required JournalToneAnalysis analysis,
    required bool isDark,
  }) {
    return showModalBottomSheet<JournalWellnessSuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JournalToneFeedbackSheet(
        analysis: analysis,
        isDark: isDark,
      ),
    );
  }

  static Future<void> showAndNavigate({
    required BuildContext context,
    required JournalToneAnalysis analysis,
    required bool isDark,
  }) async {
    // Keep the router reference before opening the modal. The sheet route is
    // disposed when it returns, so navigation must not depend on its context.
    final router = GoRouter.of(context);
    final suggestion = await show(
      context: context,
      analysis: analysis,
      isDark: isDark,
    );
    if (suggestion == null) return;
    // Let the modal route finish its pop before changing the app location.
    await WidgetsBinding.instance.endOfFrame;
    router.go(routeForSuggestion(suggestion));
  }

  static String routeForSuggestion(JournalWellnessSuggestion suggestion) =>
      switch (suggestion) {
        JournalWellnessSuggestion.breathing => AppRoutes.breathing,
        JournalWellnessSuggestion.meditation => AppRoutes.meditation,
        JournalWellnessSuggestion.calm => AppRoutes.calm,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = AstraKit.primary(isDark);
    final visibleSuggestions = analysis.showWellnessSuggestions
        ? analysis.suggestions
        : const <JournalWellnessSuggestion>[];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171025) : const Color(0xFFFFF8E9),
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
                    color: AstraKit.muted(isDark).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.13),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.journalToneFeedbackTitle,
                      style: AstraKit.heading2(isDark, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('journal-tone-close'),
                    tooltip: l10n.journalToneNotNow,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AstraKit.muted(isDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.09 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  analysis.message,
                  key: const ValueKey('journal-tone-message'),
                  style: AstraKit.body(
                    isDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              if (visibleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.journalToneWellnessPrompt,
                  style: AstraKit.body(
                    isDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                for (final suggestion in visibleSuggestions) ...[
                  _SuggestionButton(
                    suggestion: suggestion,
                    label: _labelForSuggestion(l10n, suggestion),
                    isDark: isDark,
                    primary: primary,
                    onTap: () => Navigator.of(context).pop(suggestion),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('journal-tone-not-now'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  l10n.journalToneNotNow,
                  style: AstraKit.mutedText(
                    isDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      };
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
          isDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}
