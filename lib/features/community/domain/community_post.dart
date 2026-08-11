/// A free-form, anonymous community post as read from the
/// `community_posts_view` (never carries the author's real identity — only
/// the generated [displayName]).
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.displayName,
    required this.body,
    required this.createdAt,
    required this.heartCount,
    required this.hugCount,
    required this.viewerHearted,
    required this.viewerHugged,
    required this.replyCount,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        heartCount: (json['heart_count'] as num?)?.toInt() ?? 0,
        hugCount: (json['hug_count'] as num?)?.toInt() ?? 0,
        viewerHearted: json['viewer_hearted'] as bool? ?? false,
        viewerHugged: json['viewer_hugged'] as bool? ?? false,
        replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String displayName;
  final String body;
  final DateTime createdAt;
  final int heartCount;
  final int hugCount;
  final bool viewerHearted;
  final bool viewerHugged;
  final int replyCount;
}

/// A short, supportive anonymous reply to a [CommunityPost].
class CommunityReply {
  const CommunityReply({
    required this.id,
    required this.displayName,
    required this.body,
    required this.createdAt,
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) => CommunityReply(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String displayName;
  final String body;
  final DateTime createdAt;
}
