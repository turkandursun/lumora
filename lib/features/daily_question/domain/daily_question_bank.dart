import '../../../l10n/generated/app_localizations.dart';

/// Ordered bank of warm, reflective daily questions (gratitude,
/// self-reflection, small joys, growth, gentle challenges — nothing
/// clinical), resolved through [AppLocalizations] so both languages stay in
/// lockstep by index. [dailyQuestionIndexForDate] picks which one is "today".
List<String> dailyQuestionBank(AppLocalizations l10n) => [
      l10n.dailyQuestion1,
      l10n.dailyQuestion2,
      l10n.dailyQuestion3,
      l10n.dailyQuestion4,
      l10n.dailyQuestion5,
      l10n.dailyQuestion6,
      l10n.dailyQuestion7,
      l10n.dailyQuestion8,
      l10n.dailyQuestion9,
      l10n.dailyQuestion10,
      l10n.dailyQuestion11,
      l10n.dailyQuestion12,
      l10n.dailyQuestion13,
      l10n.dailyQuestion14,
      l10n.dailyQuestion15,
      l10n.dailyQuestion16,
      l10n.dailyQuestion17,
      l10n.dailyQuestion18,
      l10n.dailyQuestion19,
      l10n.dailyQuestion20,
      l10n.dailyQuestion21,
      l10n.dailyQuestion22,
      l10n.dailyQuestion23,
      l10n.dailyQuestion24,
      l10n.dailyQuestion25,
      l10n.dailyQuestion26,
      l10n.dailyQuestion27,
      l10n.dailyQuestion28,
      l10n.dailyQuestion29,
      l10n.dailyQuestion30,
      l10n.dailyQuestion31,
      l10n.dailyQuestion32,
      l10n.dailyQuestion33,
      l10n.dailyQuestion34,
      l10n.dailyQuestion35,
      l10n.dailyQuestion36,
      l10n.dailyQuestion37,
      l10n.dailyQuestion38,
      l10n.dailyQuestion39,
      l10n.dailyQuestion40,
      l10n.dailyQuestion41,
      l10n.dailyQuestion42,
      l10n.dailyQuestion43,
      l10n.dailyQuestion44,
      l10n.dailyQuestion45,
    ];

/// Picks a stable index for [date]: consecutive calendar days map to
/// consecutive indices (wrapping modulo [bankLength]), so today's question
/// is guaranteed to differ from both yesterday's and tomorrow's, the pick is
/// stable no matter how many times it's checked the same day, and the full
/// bank cycles through before any question repeats.
int dailyQuestionIndexForDate(DateTime date, int bankLength) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final epoch = DateTime.utc(2024, 1, 1);
  final daysSinceEpoch = day.difference(epoch).inDays;
  return daysSinceEpoch % bankLength;
}
