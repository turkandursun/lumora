import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_repository.dart';
import '../../domain/community_post.dart';
import '../../domain/community_share.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

/// Today's shared answers, most recent first. A plain one-shot fetch rather
/// than a realtime stream, matching the "simple, read-only feed" scope —
/// refresh via `ref.invalidate(communityFeedProvider)` (e.g. pull-to-refresh,
/// or right after this user shares/reports one).
final communityFeedProvider = FutureProvider.autoDispose<List<CommunityShare>>((ref) {
  return ref.watch(communityRepositoryProvider).fetchSharesForDate(DateTime.now());
});

/// Free-form anonymous posts, newest first. Refresh via
/// `ref.invalidate(communityPostsProvider)` after posting / reacting / reporting.
final communityPostsProvider =
    FutureProvider.autoDispose<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).fetchPosts();
});

/// Replies for a single post, keyed by post id.
final communityRepliesProvider = FutureProvider.autoDispose
    .family<List<CommunityReply>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).fetchReplies(postId);
});
