import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/crisis_detection_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/mood_gradient_background.dart';
import '../../../../theme/responsive_content.dart';
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

    return Scaffold(
      backgroundColor: LumoraPalette.nightBackground,
      body: MoodGradientBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Text(
                  l10n.dailyQuestionTitle,
                  style: AppTheme.displayFont(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dailyQuestionSubtitle,
                  style: AppTheme.bodyFont(color: Colors.white.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 20),
                _TodayQuestionCard(questionText: todayQuestionText),
                const SizedBox(height: 16),
                todayAnswerAsync.when(
                  data: (answer) => answer == null
                      ? _AnswerButton(
                          label: l10n.dailyQuestionAnswerButton,
                          onTap: () => _openAnswerSheet(
                            context,
                            questionIndex: todayIndex,
                            questionText: todayQuestionText,
                            existing: null,
                          ),
                        )
                      : _AnsweredState(
                          answer: answer,
                          onEdit: () => _openAnswerSheet(
                            context,
                            questionIndex: todayIndex,
                            questionText: todayQuestionText,
                            existing: answer,
                          ),
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (_, __) => Text(
                    l10n.dailyQuestionLoadError,
                    style: AppTheme.bodyFont(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.dailyQuestionHistoryTitle,
                  style: AppTheme.bodyFont(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 12),
                historyAsync.when(
                  data: (rows) => rows.isEmpty
                      ? Text(
                          l10n.dailyQuestionHistoryEmpty,
                          style: AppTheme.bodyFont(color: Colors.white.withValues(alpha: 0.6)),
                        )
                      : Column(
                          children: [
                            for (final row in rows)
                              _HistoryTile(
                                row: row,
                                questionText: bank[row.questionIndex.clamp(0, bank.length - 1)],
                              ),
                          ],
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  error: (_, __) => Text(
                    l10n.dailyQuestionLoadError,
                    style: AppTheme.bodyFont(color: Colors.white.withValues(alpha: 0.8)),
                  ),
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
  required int questionIndex,
  required String questionText,
  required DailyQuestionAnswerRow? existing,
}) async {
  final result = await showModalBottomSheet<_AnswerSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AnswerSheet(
      questionIndex: questionIndex,
      questionText: questionText,
      existing: existing,
    ),
  );
  if (result?.triggeredCrisis == true && context.mounted) {
    await CrisisSupportSheet.show(context);
  }
}

/// Luma's small avatar dot beside a speech-bubble-style card holding
/// today's question — same avatar visual used in Luma's chat sheet header,
/// scaled up slightly for a standalone card.
class _TodayQuestionCard extends StatelessWidget {
  const _TodayQuestionCard({required this.questionText});

  final String questionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color.lerp(LumoraPalette.warmCream, LumoraPalette.lightPurple, 0.35)!,
                  LumoraPalette.lightPurple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: LumoraPalette.lightPurple.withValues(alpha: 0.5),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                questionText,
                style: AppTheme.bodyFont(fontSize: 14.5, color: Colors.white, letterSpacing: 0.1)
                    .copyWith(fontStyle: FontStyle.italic, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: LumoraPalette.ctaGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: LumoraPalette.primaryPurple.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: LumoraPalette.bodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnsweredState extends StatelessWidget {
  const _AnsweredState({required this.answer, required this.onEdit});

  final DailyQuestionAnswerRow answer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: LumoraPalette.lightPurple, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.dailyQuestionAnsweredToday,
              style: AppTheme.bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            answer.answerText,
            style: AppTheme.bodyFont(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.88)).copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onEdit,
          child: Text(
            l10n.dailyQuestionEditButton,
            style: LumoraPalette.bodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LumoraPalette.lightPurple),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.row, required this.questionText});

  final DailyQuestionAnswerRow row;
  final String questionText;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMd(locale).format(row.date),
            style: AppTheme.bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 6),
          Text(
            questionText,
            style: AppTheme.bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 4),
          Text(
            row.answerText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyFont(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.65)),
          ),
        ],
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
    required this.questionIndex,
    required this.questionText,
    required this.existing,
  });

  final int questionIndex;
  final String questionText;
  final DailyQuestionAnswerRow? existing;

  @override
  ConsumerState<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<_AnswerSheet> {
  late final _controller = TextEditingController(text: widget.existing?.answerText ?? '');
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

    setState(() => _saving = true);

    final l10n = AppLocalizations.of(context);
    final dailyRepo = ref.read(dailyQuestionRepositoryProvider);
    final communityRepo = ref.read(communityRepositoryProvider);
    final today = DateTime.now();
    final previousShareId = widget.existing?.communityShareId;
    final triggeredCrisis = _shareToggle && CrisisDetectionService.containsCrisisLanguage(text);

    var isShared = false;
    String? shareId;

    if (_shareToggle && !triggeredCrisis) {
      try {
        if (previousShareId != null) {
          await communityRepo.deleteShare(previousShareId);
        }
        shareId = await communityRepo.shareAnswer(questionDate: today, answerText: text, l10n: l10n);
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
    Navigator.of(context).pop(_AnswerSheetResult(triggeredCrisis: triggeredCrisis));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 40, 0, 0),
          decoration: const BoxDecoration(
            color: LumoraPalette.nightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.questionText,
                  style: AppTheme.bodyFont(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)
                      .copyWith(fontStyle: FontStyle.italic, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  minLines: 3,
                  style: AppTheme.bodyFont(color: Colors.white),
                  onChanged: (_) {
                    if (_showValidationError) setState(() => _showValidationError = false);
                  },
                  decoration: InputDecoration(
                    hintText: l10n.dailyQuestionInputHint,
                    hintStyle: AppTheme.bodyFont(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_showValidationError) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.dailyQuestionValidationEmpty,
                    style: AppTheme.bodyFont(fontSize: 12, color: LumoraPalette.accentPink),
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
                          Text(
                            l10n.dailyQuestionShareToggleLabel,
                            style: AppTheme.bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.dailyQuestionShareToggleDesc,
                            style: AppTheme.bodyFont(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _shareToggle,
                      activeThumbColor: LumoraPalette.primaryPurple,
                      onChanged: _saving ? null : (value) => setState(() => _shareToggle = value),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SaveAnswerButton(
                  label: l10n.dailyQuestionSaveButton,
                  loading: _saving,
                  onTap: _saving ? null : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveAnswerButton extends StatelessWidget {
  const _SaveAnswerButton({required this.label, required this.onTap, required this.loading});

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: LumoraPalette.ctaGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: LumoraPalette.primaryPurple.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(
                    label,
                    style: LumoraPalette.bodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
