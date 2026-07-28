/// One other user's anonymous, shared answer to a given day's Daily
/// Question, as read from Supabase's `daily_question_shares` table. Never
/// carries `user_id` — the feed only ever shows [displayName].
class CommunityShare {
  const CommunityShare({
    required this.id,
    required this.displayName,
    required this.answerText,
    required this.createdAt,
  });

  factory CommunityShare.fromJson(Map<String, dynamic> json) => CommunityShare(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        answerText: json['answer_text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String displayName;
  final String answerText;
  final DateTime createdAt;
}
