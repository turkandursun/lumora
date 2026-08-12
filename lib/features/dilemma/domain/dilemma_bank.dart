import '../../../l10n/generated/app_localizations.dart';

/// A single "this or that" dilemma. [id] is a stable identifier used to store
/// and aggregate real votes in Supabase (independent of the daily selection /
/// shuffle). [fallbackLeftPct] is only used if live vote counts can't load.
class Dilemma {
  const Dilemma({
    required this.id,
    required this.left,
    required this.right,
    required this.fallbackLeftPct,
  });

  final int id;
  final String left;
  final String right;
  final int fallbackLeftPct;
}

/// The full pool of dilemmas. [dailyDilemmas] picks a rotating subset so the
/// questions change every day.
List<Dilemma> dilemmaBank(AppLocalizations l10n) => [
      Dilemma(id: 1, left: l10n.dilemma1A, right: l10n.dilemma1B, fallbackLeftPct: 58),
      Dilemma(id: 2, left: l10n.dilemma2A, right: l10n.dilemma2B, fallbackLeftPct: 46),
      Dilemma(id: 3, left: l10n.dilemma3A, right: l10n.dilemma3B, fallbackLeftPct: 71),
      Dilemma(id: 4, left: l10n.dilemma4A, right: l10n.dilemma4B, fallbackLeftPct: 34),
      Dilemma(id: 5, left: l10n.dilemma5A, right: l10n.dilemma5B, fallbackLeftPct: 41),
      Dilemma(id: 6, left: l10n.dilemma6A, right: l10n.dilemma6B, fallbackLeftPct: 52),
      Dilemma(id: 7, left: l10n.dilemma7A, right: l10n.dilemma7B, fallbackLeftPct: 63),
      Dilemma(id: 8, left: l10n.dilemma8A, right: l10n.dilemma8B, fallbackLeftPct: 29),
      Dilemma(id: 9, left: l10n.dilemma9A, right: l10n.dilemma9B, fallbackLeftPct: 22),
      Dilemma(id: 10, left: l10n.dilemma10A, right: l10n.dilemma10B, fallbackLeftPct: 55),
      Dilemma(id: 11, left: l10n.dilemma11A, right: l10n.dilemma11B, fallbackLeftPct: 66),
      Dilemma(id: 12, left: l10n.dilemma12A, right: l10n.dilemma12B, fallbackLeftPct: 54),
      Dilemma(id: 13, left: l10n.dilemma13A, right: l10n.dilemma13B, fallbackLeftPct: 38),
      Dilemma(id: 14, left: l10n.dilemma14A, right: l10n.dilemma14B, fallbackLeftPct: 61),
      Dilemma(id: 15, left: l10n.dilemma15A, right: l10n.dilemma15B, fallbackLeftPct: 57),
      Dilemma(id: 16, left: l10n.dilemma16A, right: l10n.dilemma16B, fallbackLeftPct: 44),
      Dilemma(id: 17, left: l10n.dilemma17A, right: l10n.dilemma17B, fallbackLeftPct: 69),
      Dilemma(id: 18, left: l10n.dilemma18A, right: l10n.dilemma18B, fallbackLeftPct: 52),
      Dilemma(id: 19, left: l10n.dilemma19A, right: l10n.dilemma19B, fallbackLeftPct: 43),
      Dilemma(id: 20, left: l10n.dilemma20A, right: l10n.dilemma20B, fallbackLeftPct: 48),
      Dilemma(id: 21, left: l10n.dilemma21A, right: l10n.dilemma21B, fallbackLeftPct: 59),
      Dilemma(id: 22, left: l10n.dilemma22A, right: l10n.dilemma22B, fallbackLeftPct: 47),
      Dilemma(id: 23, left: l10n.dilemma23A, right: l10n.dilemma23B, fallbackLeftPct: 36),
      Dilemma(id: 24, left: l10n.dilemma24A, right: l10n.dilemma24B, fallbackLeftPct: 64),
      Dilemma(id: 25, left: l10n.dilemma25A, right: l10n.dilemma25B, fallbackLeftPct: 49),
      Dilemma(id: 26, left: l10n.dilemma26A, right: l10n.dilemma26B, fallbackLeftPct: 72),
      Dilemma(id: 27, left: l10n.dilemma27A, right: l10n.dilemma27B, fallbackLeftPct: 33),
      Dilemma(id: 28, left: l10n.dilemma28A, right: l10n.dilemma28B, fallbackLeftPct: 45),
      Dilemma(id: 29, left: l10n.dilemma29A, right: l10n.dilemma29B, fallbackLeftPct: 26),
      Dilemma(id: 30, left: l10n.dilemma30A, right: l10n.dilemma30B, fallbackLeftPct: 56),
    ];

/// Picks a rotating set of [count] dilemmas for [date], so the deck differs
/// every day but stays consistent throughout a single day.
List<Dilemma> dailyDilemmas(AppLocalizations l10n,
    {DateTime? date, int count = 6}) {
  final all = dilemmaBank(l10n);
  final day = date ?? DateTime.now();
  final daysSinceEpoch = DateTime(day.year, day.month, day.day)
      .difference(DateTime(2020, 1, 1))
      .inDays;
  final start = (daysSinceEpoch * count) % all.length;
  return List.generate(count, (i) => all[(start + i) % all.length]);
}
