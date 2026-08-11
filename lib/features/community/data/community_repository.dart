import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/anonymous_name_generator.dart';
import '../domain/community_post.dart';
import '../domain/community_share.dart';

/// Failure signal for [CommunityRepository] calls — kept string-free so the
/// presentation layer maps it to a warm, localized message rather than
/// showing anything Supabase returned directly.
class CommunityShareException implements Exception {
  const CommunityShareException();
}

/// Talks to Supabase's `daily_question_shares` table: the optional,
/// anonymous "Safe Space Community" layer on top of the Daily Question
/// feature. Never touches the user's real identity beyond `user_id` (which
/// RLS needs and the client never reads back) — everything shown in the
/// feed is the generated [displayName].
class CommunityRepository {
  CommunityRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _displayNameMetadataKey = 'community_display_name';
  static const _table = 'daily_question_shares';

  /// This user's anonymous display name, generating and persisting one
  /// (via Supabase auth user metadata) the first time it's needed. Stable
  /// across every future share once set.
  Future<String> ensureDisplayName(AppLocalizations l10n) async {
    final existing = _client.auth.currentUser?.userMetadata?[_displayNameMetadataKey] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = generateAnonymousName(l10n);
    await _client.auth.updateUser(UserAttributes(data: {_displayNameMetadataKey: generated}));
    return generated;
  }

  /// Publishes [answerText] anonymously for [questionDate] and returns the
  /// new row's id (to cache locally against the Daily Question answer, so
  /// it can be deleted later if the user un-shares or edits their answer).
  Future<String> shareAnswer({
    required DateTime questionDate,
    required String answerText,
    required AppLocalizations l10n,
  }) async {
    try {
      final displayName = await ensureDisplayName(l10n);
      final row = await _client.from(_table).insert({
        'display_name': displayName,
        'question_date': _dateOnlyString(questionDate),
        'answer_text': answerText,
      }).select().single();
      return row['id'] as String;
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  /// Every non-flagged share for [questionDate], most recent first.
  Future<List<CommunityShare>> fetchSharesForDate(DateTime questionDate) async {
    try {
      final rows = await _client
          .from(_table)
          // Only what the feed shows — never user_id, even though RLS
          // would allow reading it back.
          .select('id, display_name, answer_text, created_at')
          .eq('question_date', _dateOnlyString(questionDate))
          .eq('is_flagged', false)
          .order('created_at', ascending: false);
      return (rows as List).map((row) => CommunityShare.fromJson(row as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  /// Removes a share the local user made — used when they turn the share
  /// toggle back off while editing an already-shared answer.
  Future<void> deleteShare(String shareId) async {
    try {
      await _client.from(_table).delete().eq('id', shareId);
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  /// Flags a share as reported via the `report_daily_question_share`
  /// Postgres function — a `SECURITY DEFINER` RPC rather than a raw
  /// `UPDATE` policy, so any authenticated user can flag any row without
  /// also being able to rewrite its `answer_text`/`display_name`.
  Future<void> reportShare(String shareId) async {
    try {
      await _client.rpc('report_daily_question_share', params: {'share_id': shareId});
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  // ─────────────────── Free-form community feed ───────────────────

  static const _postsView = 'community_posts_view';
  static const _postsTable = 'community_posts';
  static const _reactionsTable = 'community_post_reactions';
  static const _repliesTable = 'community_post_replies';

  /// The most recent free-form posts (non-flagged), newest first.
  Future<List<CommunityPost>> fetchPosts({int limit = 50}) async {
    try {
      final rows = await _client
          .from(_postsView)
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .map((r) => CommunityPost.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  /// Publishes a new anonymous post.
  Future<void> createPost(String body, AppLocalizations l10n) async {
    try {
      final displayName = await ensureDisplayName(l10n);
      await _client.from(_postsTable).insert({
        'display_name': displayName,
        'body': body,
      });
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  /// Adds or removes the current user's [kind] ('heart' | 'hug') reaction.
  Future<void> toggleReaction({
    required String postId,
    required String kind,
    required bool isOn,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      if (isOn) {
        await _client
            .from(_reactionsTable)
            .delete()
            .eq('post_id', postId)
            .eq('kind', kind)
            .eq('user_id', uid);
      } else {
        await _client
            .from(_reactionsTable)
            .insert({'post_id': postId, 'kind': kind});
      }
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  Future<void> reportPost(String postId) async {
    try {
      await _client.rpc('report_community_post', params: {'post_id': postId});
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  /// Non-flagged replies for [postId], oldest first (conversational order).
  Future<List<CommunityReply>> fetchReplies(String postId) async {
    try {
      final rows = await _client
          .from(_repliesTable)
          .select('id, display_name, body, created_at')
          .eq('post_id', postId)
          .eq('is_flagged', false)
          .order('created_at', ascending: true);
      return (rows as List)
          .map((r) => CommunityReply.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  Future<void> createReply(
      String postId, String body, AppLocalizations l10n) async {
    try {
      final displayName = await ensureDisplayName(l10n);
      await _client.from(_repliesTable).insert({
        'post_id': postId,
        'display_name': displayName,
        'body': body,
      });
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  Future<void> reportReply(String replyId) async {
    try {
      await _client.rpc('report_community_reply', params: {'reply_id': replyId});
    } catch (_) {
      throw const CommunityShareException();
    }
  }

  String _dateOnlyString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
