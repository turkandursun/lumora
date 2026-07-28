/// Pure cycle math derived from the set of days the user marked as
/// menstruation days. Kept UI-free so it can be unit-tested on its own.
class PeriodInsights {
  const PeriodInsights({
    required this.periodsTracked,
    this.lastPeriodStart,
    this.averageCycleDays,
    this.predictedNextStart,
    this.daysUntilNext,
  });

  /// How many distinct periods (runs of consecutive days) were found.
  final int periodsTracked;

  /// Start date of the most recent tracked period.
  final DateTime? lastPeriodStart;

  /// Average number of days between period starts (null until at least two
  /// periods are tracked; a 28-day default is used for the prediction when
  /// only one period exists).
  final int? averageCycleDays;

  /// Estimated start date of the next period.
  final DateTime? predictedNextStart;

  /// Whole days from today until [predictedNextStart] (negative if overdue).
  final int? daysUntilNext;

  bool get hasData => periodsTracked > 0;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Groups [days] into consecutive runs and derives cycle stats. Each run's
/// first day is treated as a "period start"; cycle length is the average gap
/// between consecutive starts.
PeriodInsights computePeriodInsights(Set<DateTime> days, {DateTime? now}) {
  if (days.isEmpty) return const PeriodInsights(periodsTracked: 0);

  final today = _dateOnly(now ?? DateTime.now());
  final sorted = days.map(_dateOnly).toList()..sort();

  // Collect the first day of each consecutive run.
  final starts = <DateTime>[];
  for (final day in sorted) {
    final prev = day.subtract(const Duration(days: 1));
    if (!days.map(_dateOnly).contains(prev)) {
      starts.add(day);
    }
  }

  final lastStart = starts.isNotEmpty ? starts.last : null;

  int? averageCycle;
  if (starts.length >= 2) {
    var totalGap = 0;
    for (var i = 1; i < starts.length; i++) {
      totalGap += starts[i].difference(starts[i - 1]).inDays;
    }
    averageCycle = (totalGap / (starts.length - 1)).round();
  }

  // Predict using the measured cycle, or a gentle 28-day default when there's
  // only a single period to go on.
  DateTime? predictedNext;
  final cycleForPrediction = averageCycle ?? 28;
  if (lastStart != null) {
    predictedNext = lastStart.add(Duration(days: cycleForPrediction));
    // If that prediction is already in the past, roll it forward so the
    // estimate always points at the next upcoming date.
    while (predictedNext!.isBefore(today)) {
      predictedNext = predictedNext.add(Duration(days: cycleForPrediction));
    }
  }

  final daysUntil =
      predictedNext == null ? null : predictedNext.difference(today).inDays;

  return PeriodInsights(
    periodsTracked: starts.length,
    lastPeriodStart: lastStart,
    averageCycleDays: averageCycle,
    predictedNextStart: predictedNext,
    daysUntilNext: daysUntil,
  );
}
