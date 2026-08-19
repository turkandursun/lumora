enum FocusPhase { focus, breakTime }

/// Device-local state for one running focus/break cycle.
///
/// This state is never uploaded. Persisting only transitions lets a killed app
/// reconstruct the countdown from timestamps without writing every second.
class ActiveFocusSession {
  const ActiveFocusSession({
    required this.sessionUuid,
    required this.userId,
    required this.phase,
    required this.focusDurationSeconds,
    required this.breakDurationSeconds,
    required this.phaseStartedAt,
    required this.targetEndAt,
    required this.accumulatedPausedSeconds,
    required this.round,
    required this.notificationTitle,
    required this.notificationBody,
    this.pausedAt,
    this.taskLabel,
  });

  final String sessionUuid;
  final String userId;
  final FocusPhase phase;
  final int focusDurationSeconds;
  final int breakDurationSeconds;
  final DateTime phaseStartedAt;
  final DateTime targetEndAt;
  final DateTime? pausedAt;
  final int accumulatedPausedSeconds;
  final int round;
  final String? taskLabel;
  final String notificationTitle;
  final String notificationBody;

  bool get isPaused => pausedAt != null;
  int get plannedDurationSeconds =>
      phase == FocusPhase.focus ? focusDurationSeconds : breakDurationSeconds;

  int remainingSeconds(DateTime now) {
    final reference = pausedAt ?? now;
    final milliseconds = targetEndAt.difference(reference).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / Duration.millisecondsPerSecond).ceil();
  }

  ActiveFocusSession copyWith({
    String? sessionUuid,
    FocusPhase? phase,
    DateTime? phaseStartedAt,
    DateTime? targetEndAt,
    Object? pausedAt = _unset,
    int? accumulatedPausedSeconds,
    int? round,
  }) {
    return ActiveFocusSession(
      sessionUuid: sessionUuid ?? this.sessionUuid,
      userId: userId,
      phase: phase ?? this.phase,
      focusDurationSeconds: focusDurationSeconds,
      breakDurationSeconds: breakDurationSeconds,
      phaseStartedAt: phaseStartedAt ?? this.phaseStartedAt,
      targetEndAt: targetEndAt ?? this.targetEndAt,
      pausedAt:
          identical(pausedAt, _unset) ? this.pausedAt : pausedAt as DateTime?,
      accumulatedPausedSeconds:
          accumulatedPausedSeconds ?? this.accumulatedPausedSeconds,
      round: round ?? this.round,
      taskLabel: taskLabel,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionUuid': sessionUuid,
        'userId': userId,
        'phase': phase.name,
        'focusDurationSeconds': focusDurationSeconds,
        'breakDurationSeconds': breakDurationSeconds,
        'phaseStartedAt': phaseStartedAt.toUtc().toIso8601String(),
        'targetEndAt': targetEndAt.toUtc().toIso8601String(),
        if (pausedAt != null) 'pausedAt': pausedAt!.toUtc().toIso8601String(),
        'accumulatedPausedSeconds': accumulatedPausedSeconds,
        'round': round,
        if (taskLabel != null) 'taskLabel': taskLabel,
        'notificationTitle': notificationTitle,
        'notificationBody': notificationBody,
      };

  static ActiveFocusSession? fromJson(Object? value) {
    if (value is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(value);
      final sessionUuid = map['sessionUuid'] as String?;
      final userId = map['userId'] as String?;
      final phaseName = map['phase'] as String?;
      final focusSeconds = (map['focusDurationSeconds'] as num?)?.toInt();
      final breakSeconds = (map['breakDurationSeconds'] as num?)?.toInt();
      final phaseStartedAt = DateTime.tryParse(
        map['phaseStartedAt'] as String? ?? '',
      );
      final targetEndAt = DateTime.tryParse(
        map['targetEndAt'] as String? ?? '',
      );
      if (sessionUuid == null ||
          sessionUuid.isEmpty ||
          userId == null ||
          userId.isEmpty ||
          focusSeconds == null ||
          focusSeconds <= 0 ||
          breakSeconds == null ||
          breakSeconds <= 0 ||
          phaseStartedAt == null ||
          targetEndAt == null) {
        return null;
      }
      final phase = FocusPhase.values.firstWhere(
        (candidate) => candidate.name == phaseName,
      );
      final pausedRaw = map['pausedAt'] as String?;
      final pausedAt = pausedRaw == null ? null : DateTime.tryParse(pausedRaw);
      if (pausedRaw != null && pausedAt == null) return null;
      return ActiveFocusSession(
        sessionUuid: sessionUuid,
        userId: userId,
        phase: phase,
        focusDurationSeconds: focusSeconds,
        breakDurationSeconds: breakSeconds,
        phaseStartedAt: phaseStartedAt.toUtc(),
        targetEndAt: targetEndAt.toUtc(),
        pausedAt: pausedAt?.toUtc(),
        accumulatedPausedSeconds:
            (map['accumulatedPausedSeconds'] as num?)?.toInt() ?? 0,
        round: (map['round'] as num?)?.toInt() ?? 1,
        taskLabel: normalizeFocusTaskLabel(map['taskLabel'] as String?),
        notificationTitle: map['notificationTitle'] as String? ?? 'ASTRA',
        notificationBody: map['notificationBody'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

const _unset = Object();
const focusTaskLabelMaxLength = 120;

String? normalizeFocusTaskLabel(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed.length <= focusTaskLabelMaxLength) return trimmed;
  return trimmed.substring(0, focusTaskLabelMaxLength);
}
