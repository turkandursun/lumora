import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../domain/community_post.dart';
import '../../domain/content_moderation.dart';
import '../../domain/relative_time.dart';
import '../providers/community_providers.dart';

/// The "Akış / Feed" tab: free-form anonymous posts with gentle heart/hug
/// reactions and supportive replies. Every write passes through
/// [ContentModeration] first (no phone numbers, links or hurtful language).
class CommunityFeedTab extends ConsumerStatefulWidget {
  const CommunityFeedTab(
      {super.key, required this.isDark, required this.primary});

  final bool isDark;
  final Color primary;

  @override
  ConsumerState<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends ConsumerState<CommunityFeedTab> {
  final _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _moderationSnack(ModerationIssue issue) {
    final l10n = AppLocalizations.of(context);
    final msg = switch (issue) {
      ModerationIssue.contact => l10n.communityModerationContact,
      ModerationIssue.harmful => l10n.communityModerationHarmful,
      _ => l10n.communityModerationEmpty,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitPost() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    final issue = ContentModeration.check(text);
    if (issue != ModerationIssue.none) {
      _moderationSnack(issue);
      return;
    }
    setState(() => _posting = true);
    try {
      await ref.read(communityRepositoryProvider).createPost(text, l10n);
      _controller.clear();
      FocusScope.of(context).unfocus();
      ref.invalidate(communityPostsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityLoadError)),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleReaction(
      CommunityPost post, String kind, bool isOn) async {
    try {
      await ref.read(communityRepositoryProvider).toggleReaction(
            postId: post.id,
            kind: kind,
            isOn: isOn,
          );
      ref.invalidate(communityPostsProvider);
    } catch (_) {/* best-effort */}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final primary = widget.primary;
    final postsAsync = ref.watch(communityPostsProvider);

    return RefreshIndicator(
      color: primary,
      backgroundColor:
          isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
      onRefresh: () async {
        ref.invalidate(communityPostsProvider);
        await ref.read(communityPostsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Composer(
            controller: _controller,
            isDark: isDark,
            primary: primary,
            posting: _posting,
            hint: l10n.communityComposerHint,
            buttonLabel: l10n.communityComposerButton,
            onSubmit: _submitPost,
          ),
          const SizedBox(height: 18),
          postsAsync.when(
            data: (posts) => posts.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
                    child: Text(l10n.communityPostEmpty,
                        style: AstraKit.mutedText(context, isDark)),
                  )
                : Column(
                    children: [
                      for (final post in posts)
                        RepaintBoundary(
                          child: _PostCard(
                            post: post,
                            isDark: isDark,
                            primary: primary,
                            onReact: _toggleReaction,
                            onOpenReplies: () => _openReplies(post),
                            onReport: () => _reportPost(post),
                          ),
                        ),
                    ],
                  ),
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(color: primary)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Text(l10n.communityLoadError,
                  style: AstraKit.mutedText(context, isDark)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportPost(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmReport(context, l10n);
    if (confirmed != true) return;
    try {
      await ref.read(communityRepositoryProvider).reportPost(post.id);
      ref.invalidate(communityPostsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityReportSuccessMessage)),
        );
      }
    } catch (_) {/* best-effort */}
  }

  Future<bool?> _confirmReport(BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            widget.isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
        title: Text(l10n.communityReportConfirmTitle,
            style: TextStyle(color: AstraKit.ink(context, widget.isDark))),
        content: Text(l10n.communityReportConfirmBody,
            style: TextStyle(color: AstraKit.muted(context, widget.isDark))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.communityReportCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.communityReportConfirmButton,
                style: TextStyle(color: widget.primary)),
          ),
        ],
      ),
    );
  }

  void _openReplies(CommunityPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RepliesSheet(
        post: post,
        isDark: widget.isDark,
        primary: widget.primary,
        parentRef: ref,
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isDark,
    required this.primary,
    required this.posting,
    required this.hint,
    required this.buttonLabel,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isDark;
  final Color primary;
  final bool posting;
  final String hint;
  final String buttonLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 6,
            maxLength: 500,
            style: AstraKit.body(context, isDark, fontSize: 14),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AstraKit.mutedText(context, isDark),
              border: InputBorder.none,
              counterStyle: AstraKit.mutedText(context, isDark, fontSize: 10),
            ),
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: posting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            child: posting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(buttonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isDark,
    required this.primary,
    required this.onReact,
    required this.onOpenReplies,
    required this.onReport,
  });

  final CommunityPost post;
  final bool isDark;
  final Color primary;
  final void Function(CommunityPost post, String kind, bool isOn) onReact;
  final VoidCallback onOpenReplies;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
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
                  child: Text(post.displayName,
                      style: AstraKit.body(context, isDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primary)),
                ),
                Text(communityRelativeTime(l10n, post.createdAt),
                    style: AstraKit.mutedText(context, isDark, fontSize: 11)),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onReport,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.flag_outlined,
                        size: 16,
                        color: AstraKit.muted(context, isDark),
                        semanticLabel: l10n.communityReportTooltip),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.body,
                style: AstraKit.body(context, isDark,
                    fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                _ReactionChip(
                  icon: post.viewerHearted
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  count: post.heartCount,
                  active: post.viewerHearted,
                  primary: primary,
                  isDark: isDark,
                  onTap: () => onReact(post, 'heart', post.viewerHearted),
                ),
                const SizedBox(width: 10),
                _ReactionChip(
                  icon: post.viewerHugged
                      ? Icons.volunteer_activism_rounded
                      : Icons.volunteer_activism_outlined,
                  count: post.hugCount,
                  active: post.viewerHugged,
                  primary: primary,
                  isDark: isDark,
                  onTap: () => onReact(post, 'hug', post.viewerHugged),
                ),
                const Spacer(),
                InkWell(
                  onTap: onOpenReplies,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.mode_comment_outlined,
                            size: 16, color: AstraKit.muted(context, isDark)),
                        const SizedBox(width: 6),
                        Text(l10n.communityReplyCountLabel(post.replyCount),
                            style: AstraKit.mutedText(context, isDark,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.icon,
    required this.count,
    required this.active,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool active;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active
              ? primary.withValues(alpha: 0.16)
              : (isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: active ? primary : AstraKit.muted(context, isDark)),
            const SizedBox(width: 6),
            Text('$count',
                style: AstraKit.body(context, isDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? primary : AstraKit.muted(context, isDark))),
          ],
        ),
      ),
    );
  }
}

class _RepliesSheet extends ConsumerStatefulWidget {
  const _RepliesSheet({
    required this.post,
    required this.isDark,
    required this.primary,
    required this.parentRef,
  });

  final CommunityPost post;
  final bool isDark;
  final Color primary;
  final WidgetRef parentRef;

  @override
  ConsumerState<_RepliesSheet> createState() => _RepliesSheetState();
}

class _RepliesSheetState extends ConsumerState<_RepliesSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    final issue = ContentModeration.check(text);
    if (issue != ModerationIssue.none) {
      final msg = switch (issue) {
        ModerationIssue.contact => l10n.communityModerationContact,
        ModerationIssue.harmful => l10n.communityModerationHarmful,
        _ => l10n.communityModerationEmpty,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .createReply(widget.post.id, text, l10n);
      _controller.clear();
      ref.invalidate(communityRepliesProvider(widget.post.id));
      widget.parentRef.invalidate(communityPostsProvider);
    } catch (_) {/* best-effort */} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final primary = widget.primary;
    final repliesAsync = ref.watch(communityRepliesProvider(widget.post.id));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF150E2B) : const Color(0xFFFFF8EE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color:
                        AstraKit.muted(context, isDark).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(l10n.communityRepliesTitle,
                  style: AstraKit.heading2(context, isDark, fontSize: 16)),
              const SizedBox(height: 8),
              Flexible(
                child: repliesAsync.when(
                  data: (replies) => replies.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(l10n.communityRepliesEmpty,
                              style: AstraKit.mutedText(context, isDark)),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final r in replies)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(r.displayName,
                                            style: AstraKit.body(
                                                context, isDark,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: primary)),
                                        const SizedBox(width: 8),
                                        Text(
                                            communityRelativeTime(
                                                l10n, r.createdAt),
                                            style: AstraKit.mutedText(
                                                context, isDark,
                                                fontSize: 10.5)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(r.body,
                                        style: AstraKit.body(context, isDark,
                                            fontSize: 13, height: 1.35)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: CircularProgressIndicator(color: primary)),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.communityLoadError,
                        style: AstraKit.mutedText(context, isDark)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 300,
                      style: AstraKit.body(context, isDark, fontSize: 13.5),
                      cursorColor: primary,
                      decoration: InputDecoration(
                        hintText: l10n.communityReplyHint,
                        hintStyle: AstraKit.mutedText(context, isDark),
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: primary),
                          )
                        : Icon(Icons.send_rounded, color: primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
