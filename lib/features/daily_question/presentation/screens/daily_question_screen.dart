import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/crisis_detection_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/responsive_content.dart';
import '../../../community/domain/content_moderation.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../domain/daily_question_bank.dart';
import '../providers/daily_question_providers.dart';

/// Daily Question — a single warm, reflective prompt per calendar day (see
/// `daily_question_bank.dart`), answered once and editable afterward.
/// Answering optionally, anonymously shares the answer to the "Safe Space
/// Community" feed (`features/community`); crisis-language detection always
/// takes priority over sharing (see `_AnswerSheet._handleSave`).
class DailyQuestionScreen extends ConsumerWidget {
  const DailyQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bank = dailyQuestionBank(l10n);
    final todayIndex = dailyQuestionIndexForDate(DateTime.now(), bank.length);
    final todayQuestionText = bank[todayIndex];

    final todayAnswerAsync = ref.watch(todayDailyQuestionAnswerProvider);
    final historyAsync = ref.watch(dailyQuestionHistoryProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Row(
                  children: [
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dailyQuestionTitle,
                              style: AstraKit.heading1(context, isDark,
                                  fontSize: 22)),
                          Text(l10n.dailyQuestionSubtitle,
                              style: AstraKit.mutedText(context, isDark)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _TodayQuestionCard(
                    questionText: todayQuestionText,
                    isDark: isDark,
                    primary: primary),
                const SizedBox(height: 16),
                todayAnswerAsync.when(
                  data: (answer) => answer == null
                      ? AstraGoldButton(
                          isDark: isDark,
                          label: l10n.dailyQuestionAnswerButton,
                          onTap: () => _openAnswerSheet(
                            context,
                            isDark: isDark,
                            questionIndex: todayIndex,
                            questionText: todayQuestionText,
                            existing: null,
                          ),
                        )
                      : _AnsweredState(
                          answer: answer,
                          isDark: isDark,
                          primary: primary,
                          onEdit: () => _openAnswerSheet(
                            context,
                            isDark: isDark,
                            questionIndex: todayIndex,
                            questionText: todayQuestionText,
                            existing: answer,
                          ),
                        ),
                  loading: () => Center(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: primary)),
                  ),
                  error: (_, __) => Text(l10n.dailyQuestionLoadError,
                      style: AstraKit.mutedText(context, isDark)),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(l10n.dailyQuestionHistoryTitle,
                      style: AstraKit.body(context, isDark,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                historyAsync.when(
                  data: (rows) => rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(l10n.dailyQuestionHistoryEmpty,
                              style: AstraKit.mutedText(context, isDark)),
                        )
                      : Column(
                          children: [
                            for (final row in rows)
                              _HistoryTile(
                                row: row,
                                questionText: bank[row.questionIndex
                                    .clamp(0, bank.length - 1)],
                                isDark: isDark,
                                primary: primary,
                              ),
                          ],
                        ),
                  loading: () => Center(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: primary)),
                  ),
                  error: (_, __) => Text(l10n.dailyQuestionLoadError,
                      style: AstraKit.mutedText(context, isDark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the answer bottom sheet and, once it closes, shows the crisis
/// support sheet if the save flow detected crisis language — done here
/// (rather than inside the bottom sheet itself) so it's shown against the
/// screen's own stable [context] rather than the sheet's, which is gone by
/// the time this runs.
Future<void> _openAnswerSheet(
  BuildContext context, {
  required bool isDark,
  required int questionIndex,
  required String questionText,
  required DailyQuestionAnswerRow? existing,
}) async {
  final result = await showModalBottomSheet<_AnswerSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AnswerSheet(
      isDark: isDark,
      questionIndex: questionIndex,
      questionText: questionText,
      existing: existing,
    ),
  );
  if (result?.triggeredCrisis == true && context.mounted) {
    await CrisisSupportSheet.show(context);
  }
}

/// Speech-bubble-style card holding today's question.
class _TodayQuestionCard extends StatelessWidget {
  const _TodayQuestionCard(
      {required this.questionText,
      required this.isDark,
      required this.primary});

  final String questionText;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      borderRadius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.18),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.auto_awesome, color: primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                questionText,
                style: AstraKit.body(context, isDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4)
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnsweredState extends StatelessWidget {
  const _AnsweredState(
      {required this.answer,
      required this.isDark,
      required this.primary,
      required this.onEdit});

  final DailyQuestionAnswerRow answer;
  final bool isDark;
  final Color primary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: primary, size: 18),
            const SizedBox(width: 6),
            Text(l10n.dailyQuestionAnsweredToday,
                style: AstraKit.body(context, isDark,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        AstraGlassCard(
          isDark: isDark,
          primaryColor: primary,
          borderRadius: 16,
          padding: const EdgeInsets.all(14),
          child: Text(answer.answerText,
              style: AstraKit.body(context, isDark,
                  fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onEdit,
          child: Text(l10n.dailyQuestionEditButton,
              style: AstraKit.body(context, isDark,
                  fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(
      {required this.row,
      required this.questionText,
      required this.isDark,
      required this.primary});

  final DailyQuestionAnswerRow row;
  final String questionText;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMd(locale).format(row.date),
                style: AstraKit.label(context, isDark, fontSize: 11)),
            const SizedBox(height: 6),
            Text(questionText,
                style: AstraKit.body(context, isDark,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              row.answerText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AstraKit.mutedText(context, isDark, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returned by [_AnswerSheet] when it closes, so the caller knows whether to
/// show the crisis support sheet against its own stable context.
class _AnswerSheetResult {
  const _AnswerSheetResult({required this.triggeredCrisis});

  final bool triggeredCrisis;
}

class _AnswerSheet extends ConsumerStatefulWidget {
  const _AnswerSheet({
    required this.isDark,
    required this.questionIndex,
    required this.questionText,
    required this.existing,
  });

  final bool isDark;
  final int questionIndex;
  final String questionText;
  final DailyQuestionAnswerRow? existing;

  @override
  ConsumerState<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<_AnswerSheet> {
  late final _controller =
      TextEditingController(text: widget.existing?.answerText ?? '');
  late bool _shareToggle = widget.existing?.isSharedToCommunity ?? false;
  bool _saving = false;
  bool _showValidationError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _showValidationError = true);
      return;
    }

    final l10n = AppLocalizations.of(context);

    // If this answer will be shared publicly, run it through the same content
    // filter as free-form community posts (no phone numbers, links, contact
    // info or hurtful language). Private-only answers are never filtered.
    if (_shareToggle) {
      final issue = ContentModeration.check(text);
      if (issue == ModerationIssue.contact ||
          issue == ModerationIssue.harmful) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(issue == ModerationIssue.contact
                ? l10n.communityModerationContact
                : l10n.communityModerationHarmful),
          ));
        return;
      }
    }

    setState(() => _saving = true);

    final dailyRepo = ref.read(dailyQuestionRepositoryProvider);
    final communityRepo = ref.read(communityRepositoryProvider);
    final today = DateTime.now();
    final previousShareId = widget.existing?.communityShareId;
    final triggeredCrisis =
        _shareToggle && CrisisDetectionService.containsCrisisLanguage(text);

    var isShared = false;
    String? shareId;

    if (_shareToggle && !triggeredCrisis) {
      try {
        if (previousShareId != null) {
          await communityRepo.deleteShare(previousShareId);
        }
        shareId = await communityRepo.shareAnswer(
            questionDate: today, answerText: text, l10n: l10n);
        isShared = true;
      } catch (_) {
        // Community sharing is optional and best-effort — the answer still
        // saves privately below even if the share request fails.
        isShared = false;
        shareId = null;
      }
    } else if (previousShareId != null) {
      // Toggle turned off, or crisis language overrode sharing — remove any
      // previously shared copy rather than leaving it orphaned.
      await communityRepo.deleteShare(previousShareId);
    }

    await dailyRepo.saveAnswer(
      date: today,
      questionIndex: widget.questionIndex,
      answerText: text,
      isSharedToCommunity: isShared,
      communityShareId: shareId,
    );

    ref.invalidate(communityFeedProvider);

    if (!mounted) return;
    Navigator.of(context)
        .pop(_AnswerSheetResult(triggeredCrisis: triggeredCrisis));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final primary = AstraKit.primary(context, isDark);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 40, 0, 0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15102A) : const Color(0xFFFBF1DD),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
                top: BorderSide(
                    color: primary.withValues(alpha: 0.4), width: 1.2)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.questionText,
                  style: AstraKit.body(context, isDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 3,
                  style: AstraKit.body(context, isDark),
                  cursorColor: primary,
                  onChanged: (_) {
                    if (_showValidationError) {
                      setState(() => _showValidationError = false);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: l10n.dailyQuestionInputHint,
                    hintStyle: AstraKit.mutedText(context, isDark),
                    filled: true,
                    fillColor: primary.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: primary.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: primary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primary, width: 1.6),
                    ),
                  ),
                ),
                if (_showValidationError) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.dailyQuestionValidationEmpty,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: const Color(0xFFE07A7A)),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dailyQuestionShareToggleLabel,
                              style: AstraKit.body(context, isDark,
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(l10n.dailyQuestionShareToggleDesc,
                              style: AstraKit.mutedText(context, isDark,
                                  fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _shareToggle,
                      activeThumbColor: primary,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _shareToggle = value),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AstraGoldButton(
                  isDark: isDark,
                  label: l10n.dailyQuestionSaveButton,
                  enabled: !_saving,
                  isLoading: _saving,
                  onTap: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
