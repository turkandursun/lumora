import '../../../l10n/generated/app_localizations.dart';

/// One quote in the local, hand-written motivational quote deck shown on
/// the Home screen's carousel. [id] is stable across app runs (used as the
/// favorite key), independent of display order.
class MotivationalQuote {
  const MotivationalQuote({required this.id, required this.text});

  final String id;
  final String text;
}

/// The home screen's small, original quote deck — six warm lines per
/// language, written for Lumora rather than sourced externally. Rotates
/// daily (see [dailyStartIndex]) but stays fully swipeable through the
/// whole deck either way.
List<MotivationalQuote> motivationalQuotes(AppLocalizations l10n) {
  return [
    MotivationalQuote(id: 'quote_1', text: l10n.quoteOfTheDay1),
    MotivationalQuote(id: 'quote_2', text: l10n.quoteOfTheDay2),
    MotivationalQuote(id: 'quote_3', text: l10n.quoteOfTheDay3),
    MotivationalQuote(id: 'quote_4', text: l10n.quoteOfTheDay4),
    MotivationalQuote(id: 'quote_5', text: l10n.quoteOfTheDay5),
    MotivationalQuote(id: 'quote_6', text: l10n.quoteOfTheDay6),
  ];
}

/// Which quote should be front-and-center today — a stable rotation driven
/// by the day of the year, so every user sees the same "quote of the day"
/// without needing a server round trip.
int dailyStartIndex(DateTime now, int deckLength) {
  final dayOfYear = int.parse(
    '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}',
  );
  return dayOfYear % deckLength;
}
