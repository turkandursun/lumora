import '../../../l10n/generated/app_localizations.dart';

/// Short, warm relative-time label for a community share's timestamp (e.g.
/// "2 hours ago" / "2 saat önce"), rather than showing a raw date/time.
String communityRelativeTime(AppLocalizations l10n, DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return l10n.communityRelativeTimeJustNow;
  if (diff.inHours < 1) return l10n.communityRelativeTimeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return l10n.communityRelativeTimeHours(diff.inHours);
  return l10n.communityRelativeTimeDays(diff.inDays);
}
