import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../community/domain/content_moderation.dart';
import '../../data/posts_repository.dart';
import '../providers/posts_providers.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _captionController = TextEditingController();
  final List<XFile> _images = [];
  bool _isPublic = true;
  bool _posting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final picked =
          await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 82);
      if (picked.isEmpty || !mounted) return;
      setState(() {
        // Cap at 9 photos, like a typical grid.
        for (final x in picked) {
          if (_images.length < 9) _images.add(x);
        }
      });
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
          source: ImageSource.camera, maxWidth: 1600, imageQuality: 82);
      if (picked == null || !mounted) return;
      setState(() {
        if (_images.length < 9) _images.add(picked);
      });
    } catch (_) {}
  }

  Future<void> _share() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    if (_images.isEmpty) return;

    // Text moderation: block hurtful language and personal contact info in the
    // caption before it's ever published (same on-device filter the community
    // feed uses). An empty caption (photo-only post) is fine.
    final caption = _captionController.text.trim();
    final issue = ContentModeration.check(caption);
    if (issue == ModerationIssue.harmful || issue == ModerationIssue.contact) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            issue == ModerationIssue.harmful
                ? (isTr
                    ? 'Paylaşımın incitici ifadeler içeriyor. Lütfen düzenleyip tekrar dene. 🌸'
                    : 'Your post contains hurtful language. Please edit it and try again. 🌸')
                : (isTr
                    ? 'Güvenliğin için kişisel iletişim bilgisi (telefon, e-posta, link) paylaşılamaz.'
                    : "For your safety, personal contact info (phone, e-mail, links) can't be shared."),
          ),
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    setState(() => _posting = true);
    try {
      final images = <NewPostImage>[];
      for (final x in _images) {
        final bytes = await x.readAsBytes();
        final ext = p.extension(x.path).replaceAll('.', '').toLowerCase();
        images.add(NewPostImage(bytes: bytes, ext: ext.isEmpty ? 'jpg' : ext));
      }
      await ref.read(postsRepositoryProvider).createPost(
            caption: caption,
            images: images,
            isPublic: _isPublic,
            l10n: l10n,
          );
      ref.invalidate(postsFeedProvider);
      ref.invalidate(postLikesProvider);
      if (!mounted) return;
      _captionController.clear();
      setState(() {
        _images.clear();
        _posting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTr ? 'Paylaşıldı 🌸' : 'Shared 🌸')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(isTr ? 'Paylaşılamadı: $e' : "Couldn't share: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final locale = Localizations.localeOf(context).languageCode;
    final feed = ref.watch(postsFeedProvider);
    final moderation = ref.watch(feedModerationProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(isTr ? 'Paylaşımlar' : 'Feed',
                        style:
                            AstraKit.heading1(context, isDark, fontSize: 22)),
                    const Spacer(),
                    AstraCircleIconButton(
                      icon: Icons.refresh_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () {
                        ref.invalidate(postsFeedProvider);
                        ref.invalidate(postLikesProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      _ComposeCard(
                        isTr: isTr,
                        isDark: isDark,
                        primary: primary,
                        controller: _captionController,
                        images: _images,
                        isPublic: _isPublic,
                        posting: _posting,
                        onPickPhotos: _pickPhotos,
                        onTakePhoto: _takePhoto,
                        onRemovePhoto: (i) =>
                            setState(() => _images.removeAt(i)),
                        onVisibilityChanged: (v) =>
                            setState(() => _isPublic = v),
                        onShare: _share,
                      ),
                      const SizedBox(height: 16),
                      feed.when(
                        data: (posts) {
                          final visible = posts
                              .where((p) =>
                                  !moderation.blockedNames
                                      .contains(p.displayName) &&
                                  !moderation.hiddenPostIds.contains(p.id))
                              .toList();
                          return visible.isEmpty
                              ? _hint(
                                  isTr
                                      ? 'Henüz paylaşım yok. İlk sen paylaş!'
                                      : 'No posts yet. Be the first!',
                                  isDark)
                              : Column(
                                  children: [
                                    for (final post in visible)
                                      RepaintBoundary(
                                        child: _PostCard(
                                            post: post,
                                            locale: locale,
                                            isDark: isDark,
                                            primary: primary),
                                      ),
                                  ],
                                );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                              child: CircularProgressIndicator(color: primary)),
                        ),
                        error: (_, __) => _hint(
                            isTr
                                ? 'Akış yüklenemedi. (Sunucu kurulumu gerekebilir.)'
                                : "Couldn't load the feed.",
                            isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint(String text, bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AstraKit.mutedText(context, isDark, fontSize: 13)),
        ),
      );
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.controller,
    required this.images,
    required this.isPublic,
    required this.posting,
    required this.onPickPhotos,
    required this.onTakePhoto,
    required this.onRemovePhoto,
    required this.onVisibilityChanged,
    required this.onShare,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final TextEditingController controller;
  final List<XFile> images;
  final bool isPublic;
  final bool posting;
  final VoidCallback onPickPhotos;
  final VoidCallback onTakePhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty) ...[
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == images.length) {
                    return _AddThumb(
                        onTap: onPickPhotos, isDark: isDark, primary: primary);
                  }
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(images[i].path,
                                width: 84, height: 84, fit: BoxFit.cover)
                            : Image.file(File(images[i].path),
                                width: 84, height: 84, fit: BoxFit.cover),
                      ),
                      GestureDetector(
                        onTap: () => onRemovePhoto(i),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.black54),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ] else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onPickPhotos,
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: Text(isTr ? 'Galeri' : 'Gallery',
                        style: AstraKit.body(context, isDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: primary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onTakePhoto,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(isTr ? 'Kamera' : 'Camera',
                        style: AstraKit.body(context, isDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: primary)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            style: AstraKit.body(context, isDark,
                fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: isTr ? 'Bir şeyler yaz...' : 'Write a caption...',
              hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14),
              filled: true,
              fillColor:
                  isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _VisibilityToggle(
              isTr: isTr,
              isDark: isDark,
              primary: primary,
              isPublic: isPublic,
              onChanged: onVisibilityChanged),
          const SizedBox(height: 12),
          AstraGoldButton(
            isDark: isDark,
            label: isTr ? 'Paylaş' : 'Share',
            icon: Icons.send_rounded,
            isLoading: posting,
            enabled: images.isNotEmpty && !posting,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb(
      {required this.onTap, required this.isDark, required this.primary});
  final VoidCallback onTap;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.5)),
        ),
        child: Icon(Icons.add_rounded, color: primary, size: 26),
      ),
    );
  }
}

/// The public/private choice shown in the compose card.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.isPublic,
    required this.onChanged,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _seg(
            context: context,
            selected: isPublic,
            icon: Icons.public_rounded,
            label: isTr ? 'Herkese görünür' : 'Everyone',
            onTap: () => onChanged(true),
          ),
          _seg(
            context: context,
            selected: !isPublic,
            icon: Icons.lock_outline_rounded,
            label: isTr ? 'Sadece ben' : 'Only me',
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _seg({
    required BuildContext context,
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color:
                selected ? primary.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? primary : AstraKit.muted(context, isDark)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AstraKit.body(context, isDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? null : AstraKit.muted(context, isDark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  const _PostCard(
      {required this.post,
      required this.locale,
      required this.isDark,
      required this.primary});

  final Post post;
  final String locale;
  final bool isDark;
  final Color primary;

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  final _commentController = TextEditingController();
  bool _expanded = false;
  bool _sending = false;
  bool _likeBusy = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Report the post to the server (flags it for everyone) and hide it locally
  /// right away so this device stops seeing it immediately.
  Future<void> _report() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    ref.read(feedModerationProvider.notifier).hidePost(widget.post.id);
    try {
      await ref.read(postsRepositoryProvider).reportPost(widget.post.id);
    } catch (_) {
      // Even if the server call fails, it's hidden locally.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isTr
            ? 'Paylaşım bildirildi ve gizlendi. Teşekkürler. 🌸'
            : 'Post reported and hidden. Thank you. 🌸'),
      ),
    );
  }

  /// Block this (anonymous) author so none of their posts show on this device.
  Future<void> _block() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final name = widget.post.displayName;
    await ref.read(feedModerationProvider.notifier).blockUser(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isTr
            ? '$name engellendi. Paylaşımları artık görünmeyecek.'
            : '$name blocked. Their posts will no longer appear.'),
      ),
    );
  }

  Future<void> _toggleLike(bool currentlyLiked) async {
    if (_likeBusy) return;
    _likeBusy = true;
    try {
      await ref
          .read(postsRepositoryProvider)
          .toggleLike(widget.post.id, currentlyLiked);
      ref.invalidate(postLikesProvider);
    } catch (_) {
      // ignore; leave state unchanged
    }
    _likeBusy = false;
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(postsRepositoryProvider).addComment(
            postId: widget.post.id,
            text: text,
            l10n: l10n,
          );
      ref.invalidate(commentsProvider(widget.post.id));
      if (!mounted) return;
      _commentController.clear();
    } catch (_) {
      // ignore
    }
    if (mounted) setState(() => _sending = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = widget.isDark;
    final primary = widget.primary;
    final post = widget.post;
    final photos = post.photos;
    final likes = ref.watch(postLikesProvider);
    final liked = likes.valueOrNull?.likedBy(post.id) ?? false;
    final likeCount = likes.valueOrNull?.countFor(post.id) ?? 0;
    final comments =
        ref.watch(commentsProvider(post.id)).valueOrNull ?? const [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: EdgeInsets.zero,
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [primary, primary.withValues(alpha: 0.6)]),
                    ),
                    child: Text(
                      post.displayName.isEmpty
                          ? '?'
                          : post.displayName.characters.first.toUpperCase(),
                      style: AstraKit.heading2(context, isDark, fontSize: 15)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(post.displayName,
                        style: AstraKit.body(context, isDark,
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                  Text(
                      DateFormat('d MMM', widget.locale).format(post.createdAt),
                      style: AstraKit.mutedText(context, isDark, fontSize: 11)),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz_rounded,
                        size: 20, color: AstraKit.muted(context, isDark)),
                    padding: EdgeInsets.zero,
                    tooltip: isTr ? 'Seçenekler' : 'Options',
                    onSelected: (v) {
                      if (v == 'report') _report();
                      if (v == 'block') _block();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(
                                isTr ? 'Şikayet et ve gizle' : 'Report & hide'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            const Icon(Icons.block_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(isTr ? 'Kullanıcıyı engelle' : 'Block user'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(post.caption,
                    style: AstraKit.body(context, isDark,
                        fontSize: 13.5, fontWeight: FontWeight.w500)),
              ),
            // Photos
            if (photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _PhotoGrid(urls: photos, isDark: isDark),
              ),
            // Visibility label
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Icon(
                      post.isPublic
                          ? Icons.public_rounded
                          : Icons.lock_outline_rounded,
                      size: 14,
                      color: AstraKit.muted(context, isDark)),
                  const SizedBox(width: 5),
                  Text(
                    post.isPublic
                        ? (isTr ? 'Herkese görünür' : 'Visible to everyone')
                        : (isTr ? 'Sadece sen' : 'Only you'),
                    style: AstraKit.mutedText(context, isDark, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Action row: like + comment
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Row(
                children: [
                  _ActionButton(
                    icon: liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: liked ? primary : AstraKit.muted(context, isDark),
                    label: '$likeCount',
                    isDark: isDark,
                    onTap: () => _toggleLike(liked),
                  ),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    color: AstraKit.muted(context, isDark),
                    label: '${comments.length}',
                    isDark: isDark,
                    onTap: () => setState(() => _expanded = true),
                  ),
                ],
              ),
            ),
            // Comments preview / full list
            _buildComments(isTr, comments, isDark, primary),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildComments(
      bool isTr, List<PostComment> comments, bool isDark, Color primary) {
    final showList =
        _expanded ? comments : comments.take(2).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in showList)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: RichText(
                text: TextSpan(
                  style: AstraKit.body(context, isDark,
                      fontSize: 12.5, fontWeight: FontWeight.w500),
                  children: [
                    TextSpan(
                        text: '${c.displayName}  ',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: c.text),
                  ],
                ),
              ),
            ),
          if (!_expanded && comments.length > 2)
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  isTr
                      ? '${comments.length} yorumun tümünü görüntüle'
                      : 'View all ${comments.length} comments',
                  style: AstraKit.mutedText(context, isDark,
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                  style: AstraKit.body(context, isDark,
                      fontSize: 13, fontWeight: FontWeight.w500),
                  cursorColor: primary,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: isTr ? 'Yorum ekle...' : 'Add a comment...',
                    hintStyle:
                        AstraKit.mutedText(context, isDark, fontSize: 13),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0x33231845)
                        : const Color(0x55FFF8EE),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide:
                          BorderSide(color: primary.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide:
                          BorderSide(color: primary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide(color: primary, width: 1.4),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _sending ? null : _sendComment,
                icon: _sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primary),
                      )
                    : Icon(Icons.send_rounded, color: primary, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: AstraKit.body(context, isDark,
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows 1..N post photos: a single full-width image for one photo, or a
/// 3-column square grid for several. Tapping opens a full-screen viewer.
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.urls, required this.isDark});

  final List<String> urls;
  final bool isDark;

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(urls: urls, initialIndex: index),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _img(BuildContext context, String url, {double? height}) =>
      Image.network(
        url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height ?? 120,
          color: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_rounded,
              color: AstraKit.muted(context, isDark)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _open(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _img(context, urls.first, height: 280),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: urls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => _open(context, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _img(context, urls[i]),
        ),
      ),
    );
  }
}

/// A simple full-screen, swipeable, zoomable photo viewer.
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: urls.length,
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(urls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
