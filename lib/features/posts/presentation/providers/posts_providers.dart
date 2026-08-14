import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/posts_repository.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository();
});

/// Local moderation state for the feed: users this device has blocked and
/// posts it has reported/hidden. Persisted so it survives restarts. Filtering
/// happens in the UI, on top of the server-side `is_flagged` filter.
class FeedModeration {
  const FeedModeration({
    this.blockedNames = const {},
    this.hiddenPostIds = const {},
  });

  final Set<String> blockedNames;
  final Set<String> hiddenPostIds;

  FeedModeration copyWith({
    Set<String>? blockedNames,
    Set<String>? hiddenPostIds,
  }) =>
      FeedModeration(
        blockedNames: blockedNames ?? this.blockedNames,
        hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      );
}

class FeedModerationNotifier extends StateNotifier<FeedModeration> {
  FeedModerationNotifier() : super(const FeedModeration()) {
    _load();
  }

  static const _blockedKey = 'feed_blocked_names_v1';
  static const _hiddenKey = 'feed_hidden_posts_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = FeedModeration(
      blockedNames: (prefs.getStringList(_blockedKey) ?? const []).toSet(),
      hiddenPostIds: (prefs.getStringList(_hiddenKey) ?? const []).toSet(),
    );
  }

  Future<void> blockUser(String name) async {
    if (name.trim().isEmpty) return;
    final next = {...state.blockedNames, name};
    state = state.copyWith(blockedNames: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_blockedKey, next.toList());
  }

  Future<void> hidePost(String id) async {
    final next = {...state.hiddenPostIds, id};
    state = state.copyWith(hiddenPostIds: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenKey, next.toList());
  }
}

final feedModerationProvider =
    StateNotifierProvider<FeedModerationNotifier, FeedModeration>(
  (ref) => FeedModerationNotifier(),
);

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
