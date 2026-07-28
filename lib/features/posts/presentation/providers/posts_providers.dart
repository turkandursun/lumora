import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/posts_repository.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository();
});

/// The shared feed, newest first. Refresh with
/// `ref.invalidate(postsFeedProvider)` after posting.
final postsFeedProvider = FutureProvider.autoDispose<List<Post>>((ref) {
  return ref.watch(postsRepositoryProvider).fetchPosts();
});

/// Comments for a single post. Refresh with
/// `ref.invalidate(commentsProvider(postId))` after commenting.
final commentsProvider =
    FutureProvider.autoDispose.family<List<PostComment>, String>((ref, postId) {
  return ref.watch(postsRepositoryProvider).fetchComments(postId);
});

/// Like counts + which posts the current user liked, for the whole feed.
/// Refresh with `ref.invalidate(postLikesProvider)` after a like/unlike.
final postLikesProvider = FutureProvider.autoDispose<LikeInfo>((ref) async {
  final posts = await ref.watch(postsFeedProvider.future);
  return ref
      .watch(postsRepositoryProvider)
      .fetchLikes(posts.map((p) => p.id).toList());
});
