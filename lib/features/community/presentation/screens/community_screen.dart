import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../../daily_question/domain/daily_question_bank.dart';
import '../../domain/community_share.dart';
import '../../domain/relative_time.dart';
import '../providers/community_providers.dart';

/// "Safe Space Community" — a simple, anonymous feed of other users' shared
/// answers to today's Daily Question. Everything stays anonymous; concerning
/// entries can be flagged for review.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bank = dailyQuestionBank(l10n);
    final todayIndex = dailyQuestionIndexForDate(DateTime.now(), bank.length);
    final todayQuestionText = bank[todayIndex];
    final feedAsync = ref.watch(communityFeedProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: RefreshIndicator(
              color: primary,
              backgroundColor:
                  isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
              onRefresh: () async {
                ref.invalidate(communityFeedProvider);
                await ref.read(communityFeedProvider.future);
              },
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
                      Text(l10n.communityTitle,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FramingBanner(
                      text: l10n.communityFramingText,
                      isDark: isDark,
                      primary: primary),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(l10n.communityTodayQuestionLabel,
                        style: AstraKit.label(context, isDark, fontSize: 11.5)),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(todayQuestionText,
                        style: AstraKit.body(context, isDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.35)),
                  ),
                  const SizedBox(height: 22),
                  feedAsync.when(
                    data: (shares) => shares.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 8),
                            child: Text(l10n.communityEmptyState,
                                style: AstraKit.mutedText(context, isDark)),
                          )
                        : Column(
                            children: [
                              for (final share in shares)
                                _ShareCard(
                                  share: share,
                                  isDark: isDark,
                                  primary: primary,
                                  onReported: () =>
                                      ref.invalidate(communityFeedProvider),
                                ),
                            ],
                          ),
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: CircularProgressIndicator(color: primary)),
                    ),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(l10n.communityLoadError,
                          style: AstraKit.mutedText(context, isDark)),
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
  const _FramingBanner(
      {required this.text, required this.isDark, required this.primary});

  final String text;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.spa_outlined, size: 16, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AstraKit.body(context, isDark,
                    fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends ConsumerWidget {
  const _ShareCard(
      {required this.share,
      required this.isDark,
      required this.primary,
      required this.onReported});

  final CommunityShare share;
  final bool isDark;
  final Color primary;
  final VoidCallback onReported;

  Future<void> _confirmReport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
        title: Text(l10n.communityReportConfirmTitle,
            style: TextStyle(color: AstraKit.ink(context, isDark))),
        content: Text(l10n.communityReportConfirmBody,
            style: TextStyle(color: AstraKit.muted(context, isDark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.communityReportCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.communityReportConfirmButton,
                style: TextStyle(color: primary)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(share.displayName,
                      style: AstraKit.body(context, isDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primary)),
                ),
                Text(communityRelativeTime(l10n, share.createdAt),
                    style: AstraKit.mutedText(context, isDark, fontSize: 11)),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _confirmReport(context, ref),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: AstraKit.muted(context, isDark),
                      semanticLabel: l10n.communityReportTooltip,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(share.answerText,
                style: AstraKit.body(context, isDark,
                    fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
