import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
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
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 82);
      if (picked == null || !mounted) return;
      setState(() {
        if (_images.length < 9) _images.add(picked);
      });
    } catch (_) {}
  }

  Future<void> _share() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    if (_images.isEmpty) return;
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
            caption: _captionController.text.trim(),
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
          content: Text(isTr
              ? 'Paylaşılamadı: $e'
              : "Couldn't share: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final locale = Localizations.localeOf(context).languageCode;
    final feed = ref.watch(postsFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: SakuraHomePalette.textDeep),
                    ),
                    Text(
                      isTr ? 'Paylaşımlar' : 'Feed',
                      style: AppTheme.displayFont(
                          fontSize: 22, color: SakuraHomePalette.textDeep),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ref.invalidate(postsFeedProvider);
                        ref.invalidate(postLikesProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded,
                          color: SakuraHomePalette.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      _ComposeCard(
                        isTr: isTr,
                        controller: _captionController,
                        images: _images,
                        isPublic: _isPublic,
                        posting: _posting,
                        onPickPhotos: _pickPhotos,
                        onTakePhoto: _takePhoto,
                        onRemovePhoto: (i) => setState(() => _images.removeAt(i)),
                        onVisibilityChanged: (v) => setState(() => _isPublic = v),
                        onShare: _share,
                      ),
                      const SizedBox(height: 16),
                      feed.when(
                        data: (posts) => posts.isEmpty
                            ? _hint(isTr
                                ? 'Henüz paylaşım yok. İlk sen paylaş!'
                                : 'No posts yet. Be the first!')
                            : Column(
                                children: [
                                  for (final post in posts)
                                    _PostCard(post: post, locale: locale),
                                ],
                              ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => _hint(isTr
                            ? 'Akış yüklenemedi. (Sunucu kurulumu gerekebilir.)'
                            : "Couldn't load the feed."),
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

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppTheme.bodyFont(
                  fontSize: 13, color: SakuraHomePalette.textMuted)),
        ),
      );
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.isTr,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
                    return _AddThumb(onTap: onPickPhotos);
                  }
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(images[i].path),
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
                      foregroundColor: SakuraHomePalette.blossomPink,
                      side: const BorderSide(color: SakuraHomePalette.blossomPink),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onPickPhotos,
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: Text(isTr ? 'Galeri' : 'Gallery',
                        style: AppTheme.bodyFont(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: SakuraHomePalette.blossomPink)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SakuraHomePalette.blossomPink,
                      side: const BorderSide(color: SakuraHomePalette.blossomPink),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onTakePhoto,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: Text(isTr ? 'Kamera' : 'Camera',
                        style: AppTheme.bodyFont(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: SakuraHomePalette.blossomPink)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 2,
            style:
                AppTheme.bodyFont(fontSize: 14, color: SakuraHomePalette.textDeep),
            cursorColor: SakuraHomePalette.blossomPink,
            decoration: InputDecoration(
              hintText: isTr ? 'Bir şeyler yaz...' : 'Write a caption...',
              hintStyle:
                  AppTheme.bodyFont(fontSize: 14, color: SakuraHomePalette.textMuted),
              filled: true,
              fillColor: SakuraHomePalette.lavender,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _VisibilityToggle(
            isTr: isTr,
            isPublic: isPublic,
            onChanged: onVisibilityChanged,
          ),
          const SizedBox(height: 12),
          PremiumButton(
            label: isTr ? 'Paylaş' : 'Share',
            icon: Icons.send_rounded,
            loading: posting,
            onPressed: (images.isEmpty || posting) ? null : onShare,
          ),
        ],
      ),
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: SakuraHomePalette.lavender,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: SakuraHomePalette.blossomPink.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.add_rounded,
            color: SakuraHomePalette.blossomPink, size: 26),
      ),
    );
  }
}

/// The public/private choice shown in the compose card.
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.isTr,
    required this.isPublic,
    required this.onChanged,
  });

  final bool isTr;
  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SakuraHomePalette.lavender,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _seg(
            selected: isPublic,
            icon: Icons.public_rounded,
            label: isTr ? 'Herkese görünür' : 'Everyone',
            onTap: () => onChanged(true),
          ),
          _seg(
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
            color: selected ? SakuraHomePalette.cardWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected
                      ? SakuraHomePalette.blossomPink
                      : SakuraHomePalette.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyFont(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? SakuraHomePalette.textDeep
                        : SakuraHomePalette.textMuted,
                  ),
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
  const _PostCard({required this.post, required this.locale});

  final Post post;
  final String locale;

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
    final post = widget.post;
    final photos = post.photos;
    final likes = ref.watch(postLikesProvider);
    final liked = likes.valueOrNull?.likedBy(post.id) ?? false;
    final likeCount = likes.valueOrNull?.countFor(post.id) ?? 0;
    final comments = ref.watch(commentsProvider(post.id)).valueOrNull ?? const [];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      SakuraHomePalette.blossomPink,
                      SakuraHomePalette.petalPink,
                    ]),
                  ),
                  child: Text(
                    post.displayName.isEmpty
                        ? '?'
                        : post.displayName.characters.first.toUpperCase(),
                    style:
                        AppTheme.displayFont(fontSize: 15, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(post.displayName,
                      style: AppTheme.bodyFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: SakuraHomePalette.textDeep)),
                ),
                Text(DateFormat('d MMM', widget.locale).format(post.createdAt),
                    style: AppTheme.bodyFont(
                        fontSize: 11, color: SakuraHomePalette.textMuted)),
              ],
            ),
          ),
          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(post.caption,
                  style: AppTheme.bodyFont(
                      fontSize: 13.5, color: SakuraHomePalette.textDeep)),
            ),
          // Photos
          if (photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _PhotoGrid(urls: photos),
            ),
          // Visibility label
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Icon(post.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                    size: 14, color: SakuraHomePalette.textMuted),
                const SizedBox(width: 5),
                Text(
                  post.isPublic
                      ? (isTr ? 'Herkese görünür' : 'Visible to everyone')
                      : (isTr ? 'Sadece sen' : 'Only you'),
                  style: AppTheme.bodyFont(
                      fontSize: 11, color: SakuraHomePalette.textMuted),
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
                  color: liked
                      ? SakuraHomePalette.blossomPink
                      : SakuraHomePalette.textMuted,
                  label: '$likeCount',
                  onTap: () => _toggleLike(liked),
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  color: SakuraHomePalette.textMuted,
                  label: '${comments.length}',
                  onTap: () => setState(() => _expanded = true),
                ),
              ],
            ),
          ),
          // Comments preview / full list
          _buildComments(isTr, comments),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildComments(bool isTr, List<PostComment> comments) {
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
                  style: AppTheme.bodyFont(
                      fontSize: 12.5, color: SakuraHomePalette.textDeep),
                  children: [
                    TextSpan(
                      text: '${c.displayName}  ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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
                  style: AppTheme.bodyFont(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: SakuraHomePalette.textMuted),
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
                  style: AppTheme.bodyFont(
                      fontSize: 13, color: SakuraHomePalette.textDeep),
                  cursorColor: SakuraHomePalette.blossomPink,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: isTr ? 'Yorum ekle...' : 'Add a comment...',
                    hintStyle: AppTheme.bodyFont(
                        fontSize: 13, color: SakuraHomePalette.textMuted),
                    filled: true,
                    fillColor: SakuraHomePalette.lavender,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _sending ? null : _sendComment,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded,
                        color: SakuraHomePalette.blossomPink, size: 20),
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
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
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
                  style: AppTheme.bodyFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SakuraHomePalette.textDeep)),
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
  const _PhotoGrid({required this.urls});

  final List<String> urls;

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(urls: urls, initialIndex: index),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _img(String url, {double? height}) => Image.network(
        url,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height ?? 120,
          color: SakuraHomePalette.lavender,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded,
              color: SakuraHomePalette.textMuted),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _open(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _img(urls.first, height: 280),
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
          child: _img(urls[i]),
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
