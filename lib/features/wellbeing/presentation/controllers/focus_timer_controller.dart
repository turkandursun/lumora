import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/focus_completion_notifier.dart';
import '../../../../core/services/focus_notification_ids.dart';
import '../../data/focus_active_session_store.dart';
import '../../data/focus_repository.dart';
import '../../domain/active_focus_session.dart';

class FocusTimerController extends StateNotifier<ActiveFocusSession?> {
  FocusTimerController({
    required FocusSessionGateway sessions,
    required FocusLocalStateStore localState,
    required FocusCompletionNotifier notifications,
    DateTime Function()? clock,
    String Function()? uuidGenerator,
  })  : _sessions = sessions,
        _localState = localState,
        _notifications = notifications,
        _clock = clock ?? DateTime.now,
        _uuidGenerator = uuidGenerator ?? _newUuidV4,
        super(null);

  final FocusSessionGateway _sessions;
  final FocusLocalStateStore _localState;
  final FocusCompletionNotifier _notifications;
  final DateTime Function() _clock;
  final String Function() _uuidGenerator;

  int _generation = 0;
  Future<void>? _transitionInFlight;

  Future<void> initialize() async {
    final userId = _sessions.currentUserId;
    final generation = ++_generation;
    if (userId == null) {
      state = null;
      return;
    }
    try {
      await _localState.clearLegacyGlobalPreferences();
    } catch (_) {
      // Legacy cleanup is best effort and must not block timer recovery.
    }
    ActiveFocusSession? restored;
    try {
      restored = await _localState.loadActiveSession(userId);
    } catch (_) {
      restored = null;
    }
    if (!_isCurrent(userId, generation)) return;
    state = restored;
    if (restored == null) return;
    await refreshFromClock();
    final current = state;
    if (current != null &&
        !current.isPaused &&
        current.phase == FocusPhase.focus) {
      await _schedule(current);
    }
  }

  Future<void> onAppResumed() async {
    final userId = _sessions.currentUserId;
    if (userId == null) {
      state = null;
      return;
    }
    if (state?.userId != userId) {
      await initialize();
      return;
    }
    await refreshFromClock();
    unawaited(_sessions.syncForCurrentUser());
  }

  Future<void> start({
    required int focusDurationSeconds,
    required int breakDurationSeconds,
    required String notificationTitle,
    required String notificationBody,
    String? taskLabel,
  }) async {
    final userId = _sessions.currentUserId;
    if (userId == null ||
        focusDurationSeconds <= 0 ||
        breakDurationSeconds <= 0) {
      return;
    }
    final now = _clock().toUtc();
    final next = ActiveFocusSession(
      sessionUuid: _uuidGenerator(),
      userId: userId,
      phase: FocusPhase.focus,
      focusDurationSeconds: focusDurationSeconds,
      breakDurationSeconds: breakDurationSeconds,
      phaseStartedAt: now,
      targetEndAt: now.add(Duration(seconds: focusDurationSeconds)),
      accumulatedPausedSeconds: 0,
      round: 1,
      taskLabel: normalizeFocusTaskLabel(taskLabel),
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
    );
    state = next;
    await _persist(next);
    if (_sessions.currentUserId != userId) return;
    try {
      await _notifications.requestPermission();
    } catch (_) {
      // A denied notification permission must not block the focus timer.
    }
    await _schedule(next);
  }

  Future<void> pause() async {
    var current = state;
    if (current == null || current.isPaused) return;
    await refreshFromClock();
    current = state;
    if (current == null || current.isPaused) return;
    final paused = current.copyWith(pausedAt: _clock().toUtc());
    state = paused;
    await _persist(paused);
    await _cancel(current);
  }

  Future<void> resume() async {
    final current = state;
    final pausedAt = current?.pausedAt;
    if (current == null || pausedAt == null) return;
    final now = _clock().toUtc();
    final pauseDuration = now.difference(pausedAt);
    final resumed = current.copyWith(
      targetEndAt: current.targetEndAt.add(pauseDuration),
      pausedAt: null,
      accumulatedPausedSeconds:
          current.accumulatedPausedSeconds + pauseDuration.inSeconds,
    );
    state = resumed;
    await _persist(resumed);
    if (resumed.phase == FocusPhase.focus) await _schedule(resumed);
  }

  Future<void> skip() async {
    final current = state;
    if (current == null) return;
    await _cancel(current);
    final now = _clock().toUtc();
    final next = current.phase == FocusPhase.focus
        ? _toBreak(current, now)
        : _toFocus(current, now);
    state = next;
    await _persist(next);
    if (next.phase == FocusPhase.focus) await _schedule(next);
  }

  Future<void> finish() async {
    final current = state;
    if (current == null) return;
    state = null;
    await _cancel(current);
    await _clearPersisted(current.userId);
  }

  Future<void> refreshFromClock() {
    final existing = _transitionInFlight;
    if (existing != null) return existing;
    final current = state;
    if (current == null || current.isPaused) return Future.value();
    if (current.remainingSeconds(_clock().toUtc()) > 0) return Future.value();
    late final Future<void> operation;
    operation = _advanceExpired().whenComplete(() {
      if (identical(_transitionInFlight, operation)) {
        _transitionInFlight = null;
      }
    });
    _transitionInFlight = operation;
    return operation;
  }

  Future<void> _advanceExpired() async {
    for (var transition = 0; transition < 3; transition++) {
      final current = state;
      if (current == null || current.isPaused) return;
      final userId = current.userId;
      final now = _clock().toUtc();
      if (current.remainingSeconds(now) > 0) return;
      if (_sessions.currentUserId != userId) {
        state = null;
        return;
      }

      if (current.phase == FocusPhase.focus) {
        var accepted = false;
        try {
          accepted = await _sessions.recordCompletedSession(
            sessionUuid: current.sessionUuid,
            plannedDurationSeconds: current.focusDurationSeconds,
            actualDurationSeconds: current.focusDurationSeconds,
            startedAt: current.phaseStartedAt,
            endedAt: current.targetEndAt,
            taskLabel: current.taskLabel,
          );
        } catch (_) {
          // Keep the expired phase for a later idempotent local insert retry.
        }
        if (_sessions.currentUserId != userId) return;
        if (!accepted) return;
        await _cancel(current);
        final next = _toBreak(current, current.targetEndAt);
        state = next;
        await _persist(next);
        continue;
      }

      final overdue = now.difference(current.targetEndAt);
      final nextStart =
          overdue > const Duration(seconds: 2) ? now : current.targetEndAt;
      final next = _toFocus(current, nextStart);
      state = next;
      await _persist(next);
      await _schedule(next);
      return;
    }
  }

  ActiveFocusSession _toBreak(ActiveFocusSession current, DateTime start) {
    return current.copyWith(
      phase: FocusPhase.breakTime,
      phaseStartedAt: start,
      targetEndAt: start.add(Duration(seconds: current.breakDurationSeconds)),
      pausedAt: null,
      accumulatedPausedSeconds: 0,
    );
  }

  ActiveFocusSession _toFocus(ActiveFocusSession current, DateTime start) {
    return current.copyWith(
      sessionUuid: _uuidGenerator(),
      phase: FocusPhase.focus,
      phaseStartedAt: start,
      targetEndAt: start.add(Duration(seconds: current.focusDurationSeconds)),
      pausedAt: null,
      accumulatedPausedSeconds: 0,
      round: current.round + 1,
    );
  }

  Future<void> _schedule(ActiveFocusSession session) async {
    if (session.phase != FocusPhase.focus ||
        session.isPaused ||
        !session.targetEndAt.isAfter(_clock().toUtc()) ||
        _sessions.currentUserId != session.userId) {
      return;
    }
    try {
      await _notifications.scheduleFocusCompletion(
        id: _notificationId(session),
        title: session.notificationTitle,
        body: session.notificationBody,
        scheduledAt: session.targetEndAt,
      );
    } catch (_) {
      // Notification support is best effort; local recovery remains reliable.
    }
  }

  Future<void> _cancel(ActiveFocusSession session) async {
    try {
      await _notifications.cancelFocusCompletion(_notificationId(session));
    } catch (_) {
      // Missing/already delivered notifications are safe to ignore.
    }
  }

  Future<void> _persist(ActiveFocusSession session) async {
    try {
      await _localState.saveActiveSession(session);
    } catch (_) {
      // The in-memory timer remains usable; the next transition retries state.
    }
  }

  Future<void> _clearPersisted(String userId) async {
    try {
      await _localState.clearActiveSession(userId);
    } catch (_) {
      // A later auth cleanup also removes this user-scoped recovery key.
    }
  }

  int _notificationId(ActiveFocusSession session) =>
      focusNotificationId('${session.userId}:${session.sessionUuid}');

  bool _isCurrent(String userId, int generation) =>
      mounted && generation == _generation && _sessions.currentUserId == userId;

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}

String _newUuidV4() {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
