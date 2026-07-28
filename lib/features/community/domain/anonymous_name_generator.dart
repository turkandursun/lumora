import 'dart:math';

import '../../../l10n/generated/app_localizations.dart';

/// Builds a friendly "adjective + noun" anonymous display name (e.g. "Quiet
/// Star" / "Sessiz Yıldız") for the community feed — generated once per
/// user and persisted in their Supabase account (see
/// `CommunityRepository.ensureDisplayName`), never regenerated afterward, so
/// it stays consistent across every answer they share.
String generateAnonymousName(AppLocalizations l10n) {
  final adjectives = [
    l10n.communityAdjective1,
    l10n.communityAdjective2,
    l10n.communityAdjective3,
    l10n.communityAdjective4,
    l10n.communityAdjective5,
    l10n.communityAdjective6,
    l10n.communityAdjective7,
    l10n.communityAdjective8,
  ];
  final nouns = [
    l10n.communityNoun1,
    l10n.communityNoun2,
    l10n.communityNoun3,
    l10n.communityNoun4,
    l10n.communityNoun5,
    l10n.communityNoun6,
    l10n.communityNoun7,
    l10n.communityNoun8,
  ];

  final random = Random();
  final adjective = adjectives[random.nextInt(adjectives.length)];
  final noun = nouns[random.nextInt(nouns.length)];
  return '$adjective $noun';
}
