import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindful_journal/core/services/focus_completion_notifier.dart';
import 'package:mindful_journal/features/wellbeing/data/focus_active_session_store.dart';
import 'package:mindful_journal/features/wellbeing/data/focus_repository.dart';
import 'package:mindful_journal/features/wellbeing/domain/active_focus_session.dart';
import 'package:mindful_journal/features/wellbeing/presentation/controllers/focus_timer_controller.dart';

void main() {
  late DateTime now;
  late _FakeSessionGateway gateway;
  late _FakeLocalStateStore localState;
  late _FakeFocusNotifier notifications;
  late int uuidSequence;

  FocusTimerController createController() => FocusTimerController(
        sessions: gateway,
        localState: localState,
        notifications: notifications,
        clock: () => now,
        uuidGenerator: () => 'session-${++uuidSequence}',
      );

  Future<void> start(FocusTimerController controller) => controller.start(
        focusDurationSeconds: 60,
        breakDurationSeconds: 15,
        taskLabel: '  Read  ',
        notificationTitle: 'Focus complete',
        notificationBody: 'Break time',
      );

  setUp(() {
    now = DateTime.utc(2026, 8, 19, 10);
    gateway = _FakeSessionGateway()..currentUserId = 'user-a';
    localState = _FakeLocalStateStore();
    notifications = _FakeFocusNotifier();
    uuidSequence = 0;
  });

  test('natural focus completion records exactly one completed session',
      () async {
    final controller = createController();
    await start(controller);

    now = now.add(const Duration(seconds: 60));
    await controller.refreshFromClock();
    await controller.refreshFromClock();

    expect(gateway.completed, hasLength(1));
    expect(gateway.completed.single.actualDurationSeconds, 60);
    expect(gateway.completed.single.taskLabel, 'Read');
    expect(controller.state?.phase, FocusPhase.breakTime);
  });

  test('skip never records a completed focus session', () async {
    final controller = createController();
    await start(controller);

    await controller.skip();

    expect(gateway.completed, isEmpty);
    expect(controller.state?.phase, FocusPhase.breakTime);
    expect(notifications.cancelled, isNotEmpty);
  });

  test('early finish never records and clears active recovery state', () async {
    final controller = createController();
    await start(controller);

    now = now.add(const Duration(seconds: 20));
    await controller.finish();

    expect(gateway.completed, isEmpty);
    expect(controller.state, isNull);
    expect(localState.sessions['user-a'], isNull);
  });

  test('break completion starts the next round without history', () async {
    final controller = createController();
    await start(controller);
    await controller.skip();

    now = now.add(const Duration(seconds: 15));
    await controller.refreshFromClock();

    expect(gateway.completed, isEmpty);
    expect(controller.state?.phase, FocusPhase.focus);
    expect(controller.state?.round, 2);
  });

  test('paused wall-clock time is excluded and resume shifts targetEndAt',
      () async {
    final controller = createController();
    await start(controller);
    final originalEnd = controller.state!.targetEndAt;

    now = now.add(const Duration(seconds: 10));
    await controller.pause();
    now = now.add(const Duration(seconds: 100));
    expect(controller.state!.remainingSeconds(now), 50);

    await controller.resume();
    expect(
      controller.state!.targetEndAt,
      originalEnd.add(const Duration(seconds: 100)),
    );
    expect(controller.state!.accumulatedPausedSeconds, 100);

    now = now.add(const Duration(seconds: 50));
    await controller.refreshFromClock();
    expect(gateway.completed, hasLength(1));
  });

  test('active session restores after restart from timestamps', () async {
    final first = createController();
    await start(first);
    now = now.add(const Duration(seconds: 10));

    final restored = createController();
    await restored.initialize();

    expect(restored.state?.phase, FocusPhase.focus);
    expect(restored.state?.remainingSeconds(now), 50);
  });

  test('expired restored session completes once and recovers into break',
      () async {
    final first = createController();
    await start(first);
    now = now.add(const Duration(seconds: 65));

    final restored = createController();
    await restored.initialize();
    final secondRestore = createController();
    await secondRestore.initialize();

    expect(gateway.completed, hasLength(1));
    expect(restored.state?.phase, FocusPhase.breakTime);
    expect(secondRestore.state?.phase, FocusPhase.breakTime);
  });

  test('start and resume schedule; pause skip and finish cancel', () async {
    final controller = createController();
    await start(controller);
    expect(notifications.scheduled, hasLength(1));

    now = now.add(const Duration(seconds: 5));
    await controller.pause();
    expect(notifications.cancelled, hasLength(1));

    now = now.add(const Duration(seconds: 20));
    await controller.resume();
    expect(notifications.scheduled, hasLength(2));

    await controller.skip();
    expect(notifications.cancelled, hasLength(2));
    await controller.finish();
    expect(notifications.cancelled, hasLength(3));
  });

  test('late user A restore cannot overwrite user B state', () async {
    final delayed = Completer<ActiveFocusSession?>();
    localState.delayedLoads['user-a'] = delayed;
    final controller = createController();
    final loadA = controller.initialize();

    gateway.currentUserId = 'user-b';
    await controller.initialize();
    delayed.complete(_sessionFor('user-a', now));
    await loadA;

    expect(controller.state, isNull);
  });

  test('task labels are blank-normalized and capped at 120 characters', () {
    expect(normalizeFocusTaskLabel('   '), isNull);
    expect(normalizeFocusTaskLabel('  task  '), 'task');
    expect(
      normalizeFocusTaskLabel(List.filled(150, 'x').join()),
      hasLength(120),
    );
  });
}

ActiveFocusSession _sessionFor(String userId, DateTime now) =>
    ActiveFocusSession(
      sessionUuid: 'restored-id',
      userId: userId,
      phase: FocusPhase.focus,
      focusDurationSeconds: 60,
      breakDurationSeconds: 15,
      phaseStartedAt: now,
      targetEndAt: now.add(const Duration(seconds: 60)),
      accumulatedPausedSeconds: 0,
      round: 1,
      notificationTitle: 'title',
      notificationBody: 'body',
    );

class _RecordedSession {
  const _RecordedSession({
    required this.id,
    required this.actualDurationSeconds,
    required this.taskLabel,
  });

  final String id;
  final int actualDurationSeconds;
  final String? taskLabel;
}

class _FakeSessionGateway implements FocusSessionGateway {
  @override
  String? currentUserId;

  final completed = <_RecordedSession>[];
  final _ids = <String>{};
  int syncCount = 0;

  @override
  Future<bool> recordCompletedSession({
    required String sessionUuid,
    required int plannedDurationSeconds,
    required int actualDurationSeconds,
    required DateTime startedAt,
    required DateTime endedAt,
    String? taskLabel,
  }) async {
    if (!_ids.add(sessionUuid)) return false;
    completed.add(
      _RecordedSession(
        id: sessionUuid,
        actualDurationSeconds: actualDurationSeconds,
        taskLabel: taskLabel,
      ),
    );
    return true;
  }

  @override
  Future<void> syncForCurrentUser() async => syncCount++;
}

class _FakeLocalStateStore implements FocusLocalStateStore {
  final sessions = <String, ActiveFocusSession>{};
  final goals = <String, int>{};
  final delayedLoads = <String, Completer<ActiveFocusSession?>>{};
  int legacyClearCount = 0;

  @override
  Future<void> clearActiveSession(String userId) async {
    sessions.remove(userId);
  }

  @override
  Future<void> clearLegacyGlobalPreferences() async => legacyClearCount++;

  @override
  Future<ActiveFocusSession?> loadActiveSession(String userId) async {
    final delayed = delayedLoads.remove(userId);
    if (delayed != null) return delayed.future;
    return sessions[userId];
  }

  @override
  Future<int> loadDailyGoal(String userId) async => goals[userId] ?? 5;

  @override
  Future<void> saveActiveSession(ActiveFocusSession session) async {
    sessions[session.userId] = session;
  }

  @override
  Future<void> saveDailyGoal(String userId, int goal) async {
    goals[userId] = goal;
  }
}

class _ScheduledNotification {
  const _ScheduledNotification(this.id, this.at);
  final int id;
  final DateTime at;
}

class _FakeFocusNotifier implements FocusCompletionNotifier {
  final scheduled = <_ScheduledNotification>[];
  final cancelled = <int>[];

  @override
  Future<void> cancelFocusCompletion(int id) async => cancelled.add(id);

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> scheduleFocusCompletion({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    scheduled.add(_ScheduledNotification(id, scheduledAt));
  }
}
