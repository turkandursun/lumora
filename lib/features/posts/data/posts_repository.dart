import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../community/data/community_repository.dart';

/// A single photo the user is about to upload with a post.
class NewPostImage {
  const NewPostImage({required this.bytes, required this.ext});

  final Uint8List bytes;
  final String ext;
}

/// One post in the shared, Instagram-style "Paylaşımlar" feed.
class Post {
  const Post({
    required this.id,
    required this.displayName,
    required this.caption,
    required this.imageUrl,
    required this.imageUrls,
    required this.isPublic,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['image_urls'];
    final urls = <String>[
      if (rawUrls is List)
        for (final u in rawUrls)
          if (u is String && u.isNotEmpty) u,
    ];
    return Post(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      imageUrls: urls,
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String displayName;
  final String caption;
  final String? imageUrl;
  final List<String> imageUrls;
  final bool isPublic;
  final DateTime createdAt;

  /// All photos to show, falling back to the legacy single [imageUrl] for
  /// rows created before multi-photo support.
  List<String> get photos =>
      imageUrls.isNotEmpty ? imageUrls : (imageUrl != null ? [imageUrl!] : []);
}

/// One comment on a post.
class PostComment {
  const PostComment({
    required this.id,
    required this.displayName,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String displayName;
  final String text;
  final DateTime createdAt;
}

/// Like counts + which posts the current user has liked, for a batch of posts.
class LikeInfo {
  const LikeInfo({required this.counts, required this.likedByMe});

  final Map<String, int> counts;
  final Set<String> likedByMe;

  int countFor(String postId) => counts[postId] ?? 0;
  bool likedBy(String postId) => likedByMe.contains(postId);

  static const empty = LikeInfo(counts: {}, likedByMe: {});
}

class PostException implements Exception {
  const PostException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'PostException';
}

/// Talks to the `activity_posts` table + the `activity-posts` Storage bucket.
/// Photos are uploaded to storage and their public URLs stored on the row, so
/// every signed-in user sees the same shared feed.
class PostsRepository {
  PostsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'activity_posts';
  static const _bucket = 'activity-posts';

  Future<List<Post>> fetchPosts() async {
    try {
      final rows = await _client
          .from(_table)
          .select('id, display_name, caption, image_url, image_urls, is_public, created_at')
          .eq('is_flagged', false)
          .order('created_at', ascending: false)
          .limit(100);
      return (rows as List)
          .map((r) => Post.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const PostException();
    }
  }

  Future<void> createPost({
    required String caption,
    required List<NewPostImage> images,
    required bool isPublic,
    required AppLocalizations l10n,
  }) async {
    try {
      final displayName =
          await CommunityRepository(client: _client).ensureDisplayName(l10n);
      final userId = _client.auth.currentUser?.id ?? 'anon';

      final urls = <String>[];
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final ext = image.ext.isEmpty ? 'jpg' : image.ext;
        final path =
            '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        await _client.storage.from(_bucket).uploadBinary(
              path,
              image.bytes,
              fileOptions: FileOptions(
                contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}',
                upsert: true,
              ),
            );
        urls.add(_client.storage.from(_bucket).getPublicUrl(path));
      }

      await _client.from(_table).insert({
        'display_name': displayName,
        'caption': caption,
        'image_url': urls.isNotEmpty ? urls.first : null,
        'image_urls': urls,
        'is_public': isPublic,
      });
    } catch (e) {
      throw PostException(e.toString());
    }
  }

  /// Fetches likes for a batch of posts in a single query.
  Future<LikeInfo> fetchLikes(List<String> postIds) async {
    if (postIds.isEmpty) return LikeInfo.empty;
    try {
      final rows = await _client
          .from('activity_post_likes')
          .select('post_id, user_id')
          .inFilter('post_id', postIds);
      final me = _client.auth.currentUser?.id;
      final counts = <String, int>{};
      final liked = <String>{};
      for (final r in rows as List) {
        final map = r as Map<String, dynamic>;
        final pid = map['post_id'] as String;
        counts[pid] = (counts[pid] ?? 0) + 1;
        if (me != null && map['user_id'] == me) liked.add(pid);
      }
      return LikeInfo(counts: counts, likedByMe: liked);
    } catch (_) {
      return LikeInfo.empty;
    }
  }

  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return;
    try {
      if (currentlyLiked) {
        await _client
            .from('activity_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', me);
      } else {
        await _client.from('activity_post_likes').insert({'post_id': postId});
      }
    } catch (_) {
      throw const PostException();
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final rows = await _client
          .from('activity_post_comments')
          .select('id, display_name, text, created_at')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return (rows as List)
          .map((r) => PostComment.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const PostException();
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
    required AppLocalizations l10n,
  }) async {
    try {
      final displayName =
          await CommunityRepository(client: _client).ensureDisplayName(l10n);
      await _client.from('activity_post_comments').insert({
        'post_id': postId,
        'display_name': displayName,
        'text': text,
      });
    } catch (_) {
      throw const PostException();
    }
  }

  Future<void> reportPost(String postId) async {
    try {
      await _client.rpc('report_activity_post', params: {'post_id': postId});
    } catch (_) {
      throw const PostException();
    }
  }
}
