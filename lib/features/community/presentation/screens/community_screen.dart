import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../daily_question/domain/daily_question_bank.dart';
import '../../domain/community_share.dart';
import '../../domain/relative_time.dart';
import '../providers/community_providers.dart';

/// "Safe Space Community" — a simple, read-only, anonymous feed of other
/// users' shared answers to today's Daily Question (see
/// `features/daily_question`). No likes/comments/replies in this version;
/// the only interaction besides reading is flagging a concerning entry via
/// [_ReportButton].
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bank = dailyQuestionBank(l10n);
    final todayIndex = dailyQuestionIndexForDate(DateTime.now(), bank.length);
    final todayQuestionText = bank[todayIndex];
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: RefreshIndicator(
              color: SakuraHomePalette.blossomPink,
              backgroundColor: SakuraHomePalette.cardWhite,
              onRefresh: () async {
                ref.invalidate(communityFeedProvider);
                await ref.read(communityFeedProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  Text(
                    l10n.communityTitle,
                    style: AppTheme.displayFont(
                        fontSize: 24, color: SakuraHomePalette.textDeep),
                  ),
                  const SizedBox(height: 12),
                  _FramingBanner(text: l10n.communityFramingText),
                  const SizedBox(height: 20),
                  Text(
                    l10n.communityTodayQuestionLabel,
                    style: AppTheme.bodyFont(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: SakuraHomePalette.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    todayQuestionText,
                    style: AppTheme.bodyFont(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: SakuraHomePalette.textDeep)
                        .copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 22),
                  feedAsync.when(
                    data: (shares) => shares.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              l10n.communityEmptyState,
                              style: AppTheme.bodyFont(
                                  color: SakuraHomePalette.textMuted),
                            ),
                          )
                        : Column(
                            children: [
                              for (final share in shares)
                                _ShareCard(
                                  share: share,
                                  onReported: () =>
                                      ref.invalidate(communityFeedProvider),
                                ),
                            ],
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: SakuraHomePalette.blossomPink)),
                    ),
                    error: (_, __) => Text(
                      l10n.communityLoadError,
                      style:
                          AppTheme.bodyFont(color: SakuraHomePalette.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FramingBanner extends StatelessWidget {
  const _FramingBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SakuraHomePalette.blossomPink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: SakuraHomePalette.blossomPink.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined,
              size: 16, color: SakuraHomePalette.blossomPink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyFont(
                      fontSize: 12.5, color: SakuraHomePalette.textDeep)
                  .copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends ConsumerWidget {
  const _ShareCard({required this.share, required this.onReported});

  final CommunityShare share;
  final VoidCallback onReported;

  Future<void> _confirmReport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SakuraHomePalette.cardWhite,
        title: Text(l10n.communityReportConfirmTitle,
            style: const TextStyle(color: SakuraHomePalette.textDeep)),
        content: Text(
          l10n.communityReportConfirmBody,
          style: const TextStyle(color: SakuraHomePalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.communityReportCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.communityReportConfirmButton,
                style: const TextStyle(color: SakuraHomePalette.blossomPink)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(communityRepositoryProvider).reportShare(share.id);
      onReported();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityReportSuccessMessage)),
        );
      }
    } catch (_) {
      // Reporting is best-effort; a failed report simply leaves the entry
      // visible, which is safe to retry.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  share.displayName,
                  style: AppTheme.bodyFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SakuraHomePalette.blossomPink),
                ),
              ),
              Text(
                communityRelativeTime(l10n, share.createdAt),
                style: AppTheme.bodyFont(
                    fontSize: 11, color: SakuraHomePalette.textMuted),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _confirmReport(context, ref),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: SakuraHomePalette.textMuted,
                    semanticLabel: l10n.communityReportTooltip,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            share.answerText,
            style: AppTheme.bodyFont(
                    fontSize: 13.5, color: SakuraHomePalette.textDeep)
                .copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
