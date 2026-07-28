import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/community_repository.dart';
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
