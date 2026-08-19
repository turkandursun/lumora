import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../data/focus_repository.dart';
import '../../domain/active_focus_session.dart';
import '../providers/focus_providers.dart';

/// Focus timer — a gentle Pomodoro for ADHD-friendly focus. Pick a focus/break
/// length (quick presets or your own custom minutes) and the screen guides you
/// through a work sprint and a short rest. Instead of a plain countdown circle,
/// progress is shown as a JOURNEY: two lines set out from each end and travel
/// toward a destination star in the middle, meeting exactly when the session
/// completes — a small, motivating "arrival" (goal-gradient effect).
class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _Preset {
  const _Preset(this.focus, this.rest);
  final int focus; // minutes
  final int rest; // minutes
}

const _breakColor = Color(0xFF7FD1B0);

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _presets = [_Preset(25, 5), _Preset(15, 3), _Preset(50, 10)];

  late final AnimationController _twinkle;
  final _task = TextEditingController();

  // Chosen durations (minutes). Presets just fill these; the steppers are the
  // single source of truth, so a custom length works exactly like a preset.
  int _focusMin = 25;
  int _breakMin = 5;

  bool _justArrived = false; // brief bloom when a phase completes
  Timer? _uiTicker;

  @override
  void initState() {
    super.initState();
    _twinkle =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      unawaited(
        ref.read(activeFocusSessionProvider.notifier).refreshFromClock(),
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _twinkle.dispose();
    _task.dispose();
    super.dispose();
  }

  double _progress(ActiveFocusSession session, int remaining) {
    final total = session.plannedDurationSeconds;
    return total <= 0 ? 0 : ((total - remaining) / total).clamp(0.0, 1.0);
  }

  Future<void> _startFocus(AppLocalizations l10n) async {
    FocusScope.of(context).unfocus();
    await ref.read(activeFocusSessionProvider.notifier).start(
          focusDurationSeconds: _focusMin * 60,
          breakDurationSeconds: _breakMin * 60,
          taskLabel: _task.text,
          notificationTitle: l10n.focusNotificationTitle,
          notificationBody: l10n.focusNotificationBody,
        );
  }

  void _clearArrivalSoon() {
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _justArrived = false);
    });
  }

  String _time(int remaining) {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final stats = ref.watch(focusStatsProvider);
    final active = ref.watch(activeFocusSessionProvider);
    ref.listen<ActiveFocusSession?>(activeFocusSessionProvider,
        (previous, next) {
      final identity = next == null
          ? null
          : '${next.sessionUuid}:${next.phase.name}:${next.round}';
      final previousIdentity = previous == null
          ? null
          : '${previous.sessionUuid}:${previous.phase.name}:${previous.round}';
      if (previousIdentity != null &&
          identity != null &&
          previousIdentity != identity) {
        HapticFeedback.mediumImpact();
        setState(() => _justArrived = true);
        _clearArrivalSoon();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.focusTitle,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: active == null
                      ? _buildSetup(l10n, isDark, primary, stats)
                      : _buildRunning(l10n, isDark, primary, active),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Setup ──────────────────────────────────────────────────────────────────

  Widget _buildSetup(
    AppLocalizations l10n,
    bool isDark,
    Color primary,
    FocusStats stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          // Today's progress + streak — the "don't break the chain" nudge.
          _StatsBanner(
            l10n: l10n,
            isDark: isDark,
            primary: primary,
            stats: stats,
          ),
          const SizedBox(height: 22),
          Text(l10n.focusHowLong,
              style: AstraKit.mutedText(context, isDark, fontSize: 15)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final p in _presets)
                _PresetPill(
                  label: '${p.focus} · ${p.rest} ${l10n.focusMinutesShort}',
                  selected: p.focus == _focusMin && p.rest == _breakMin,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => setState(() {
                    _focusMin = p.focus;
                    _breakMin = p.rest;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _DurationStepper(
            label: l10n.focusTitle,
            icon: Icons.center_focus_strong_rounded,
            value: _focusMin,
            unit: l10n.focusMinutesShort,
            min: 5,
            max: 120,
            step: 5,
            isDark: isDark,
            primary: primary,
            onChanged: (v) => setState(() => _focusMin = v),
          ),
          const SizedBox(height: 12),
          _DurationStepper(
            label: l10n.focusBreakLabel,
            icon: Icons.local_cafe_rounded,
            value: _breakMin,
            unit: l10n.focusMinutesShort,
            min: 1,
            max: 30,
            step: 1,
            isDark: isDark,
            primary: primary,
            onChanged: (v) => setState(() => _breakMin = v),
          ),
          const SizedBox(height: 12),
          _DurationStepper(
            label: l10n.focusDailyGoalLabel,
            icon: Icons.flag_rounded,
            value: stats.goal,
            unit: l10n.focusSessionUnitShort,
            min: 1,
            max: 12,
            step: 1,
            isDark: isDark,
            primary: primary,
            onChanged: (v) => ref.read(focusStatsProvider.notifier).setGoal(v),
          ),
          const SizedBox(height: 20),
          // Task label.
          _FocusField(
            controller: _task,
            hint: l10n.focusTaskHint,
            isDark: isDark,
            primary: primary,
          ),
          const SizedBox(height: 26),
          AstraGoldButton(
            isDark: isDark,
            label: l10n.focusStartButton,
            icon: Icons.play_arrow_rounded,
            expand: false,
            onTap: () => _startFocus(l10n),
          ),
        ],
      ),
    );
  }

  // ── Running ─────────────────────────────────────────────────────────────────

  Widget _buildRunning(
    AppLocalizations l10n,
    bool isDark,
    Color primary,
    ActiveFocusSession active,
  ) {
    final isBreak = active.phase == FocusPhase.breakTime;
    final accent = isBreak ? _breakColor : primary;
    final task = active.taskLabel ?? '';
    final remaining = active.remainingSeconds(DateTime.now().toUtc());
    final running = !active.isPaused;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isBreak ? l10n.focusBreakLabel : l10n.focusPhaseFocus,
          style: AstraKit.body(context, isDark,
              fontSize: 16, fontWeight: FontWeight.w700, color: accent),
        ),
        const SizedBox(height: 4),
        Text(l10n.focusRoundLabel(active.round),
            style: AstraKit.mutedText(context, isDark, fontSize: 12.5)),
        const SizedBox(height: 24),
        // A glowing progress ring wrapping the time: a luminous line winds
        // clockwise from the top and closes the circle exactly as the session
        // completes — a soft, feminine "arrival".
        SizedBox(
          width: 268,
          height: 268,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _twinkle,
                  builder: (context, _) => CustomPaint(
                    size: const Size(268, 268),
                    painter: _RingPainter(
                      progress: _progress(active, remaining),
                      twinkle: _twinkle.value,
                      color: accent,
                      arrived: _justArrived,
                      trackColor: AstraKit.muted(context, isDark)
                          .withValues(alpha: 0.16),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isBreak && task.isNotEmpty) ...[
                    SizedBox(
                      width: 180,
                      child: Text(
                        task,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AstraKit.mutedText(context, isDark,
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _time(remaining),
                    style: GoogleFonts.fredoka(
                      fontSize: 58,
                      fontWeight: FontWeight.w600,
                      color: AstraKit.heading(context, isDark),
                      letterSpacing: 1,
                      height: 1.0,
                      shadows: [
                        Shadow(
                            color: accent.withValues(alpha: 0.4),
                            blurRadius: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.focusTimeLeft,
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: AstraKit.muted(context, isDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Text(
          isBreak ? l10n.focusRestMessage : l10n.focusWorkMessage,
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(context, isDark, fontSize: 13.5),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundControl(
                icon: Icons.stop_rounded,
                label: l10n.focusFinishButton,
                isDark: isDark,
                primary: primary,
                onTap: () =>
                    ref.read(activeFocusSessionProvider.notifier).finish()),
            const SizedBox(width: 16),
            _RoundControl(
              icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: running ? l10n.focusPauseButton : l10n.focusResumeButton,
              isDark: isDark,
              primary: primary,
              filled: true,
              onTap: () {
                final controller =
                    ref.read(activeFocusSessionProvider.notifier);
                running ? controller.pause() : controller.resume();
              },
            ),
            const SizedBox(width: 16),
            _RoundControl(
                icon: Icons.skip_next_rounded,
                label: l10n.focusSkipButton,
                isDark: isDark,
                primary: primary,
                onTap: () =>
                    ref.read(activeFocusSessionProvider.notifier).skip()),
          ],
        ),
      ],
    );
  }
}

/// Draws a glowing circular progress ring around the timer: a luminous line
/// winds clockwise from the top (12 o'clock) and closes the circle exactly as
/// the session completes, with a travelling glow head and a soft bloom at the
/// finish — a calm, feminine "arrival".
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.twinkle,
    required this.color,
    required this.arrived,
    required this.trackColor,
  });

  final double progress; // 0..1
  final double twinkle; // 0..1 ambient
  final Color color;
  final bool arrived;
  final Color trackColor;

  static const _stroke = 9.0;
  static const _start = -pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - _stroke - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = progress.clamp(0.0, 1.0) * 2 * pi;
    // One consistent DEEP tone derived from the theme accent (3–4 shades darker
    // than the light background) — the ring never lightens/whitens as it fills.
    final deep = Color.lerp(color, Colors.black, 0.34)!;
    final headColor = Color.lerp(deep, color, 0.5)!;

    // Faint full track — the circle waiting to be closed.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = trackColor,
    );

    if (sweep > 0.0005) {
      // Soft glow underlay.
      canvas.drawArc(
        rect,
        _start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke + 7
          ..strokeCap = StrokeCap.round
          ..color = deep.withValues(alpha: 0.26)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
      );
      // Crisp arc — a single deep colour, end to end.
      canvas.drawArc(
        rect,
        _start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round
          ..color = deep,
      );
    }

    // Travelling head at the leading edge — a touch brighter than the arc so
    // it reads as the moving tip, but still dark (never white).
    final headAngle = _start + sweep;
    final headPos = center + Offset(cos(headAngle), sin(headAngle)) * radius;
    final hr = 5.5 + (arrived ? 3.0 : 0.0);
    canvas.drawCircle(
        headPos, hr * 2.6, Paint()..color = deep.withValues(alpha: 0.26));
    canvas.drawCircle(headPos, hr, Paint()..color = headColor);
    _sparkle(canvas, headPos, hr * 1.3 * (0.9 + 0.12 * twinkle),
        headColor.withValues(alpha: 0.9));

    // A soft bloom at the top when the circle closes.
    if (arrived) {
      final top = center + Offset(cos(_start), sin(_start)) * radius;
      canvas.drawCircle(
        top,
        24,
        Paint()
          ..color = deep.withValues(alpha: 0.32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), p);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), p);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.twinkle != twinkle ||
      old.arrived != arrived ||
      old.color != color;
}

// ── Setup widgets ────────────────────────────────────────────────────────────

/// Today's progress toward the daily goal + the streak — the stickiness nudge.
class _StatsBanner extends StatelessWidget {
  const _StatsBanner({
    required this.l10n,
    required this.isDark,
    required this.primary,
    required this.stats,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final Color primary;
  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final done = stats.completedSessionsToday;
    final goal = stats.goal;
    final ratio = goal <= 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final reached = done >= goal;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0x33231845) : const Color(0x80FBF1DD),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.focusSessionsProgress(done, goal),
                style: AstraKit.heading1(context, isDark, fontSize: 20)
                    .copyWith(color: primary),
              ),
              const Spacer(),
              if (stats.streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '🔥 ${l10n.focusStreakDays(stats.streak)}',
                    style: AstraKit.body(context, isDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: primary.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          if (reached) ...[
            const SizedBox(height: 8),
            Text(
              l10n.focusDailyGoalReached,
              style: AstraKit.mutedText(context, isDark,
                  fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

/// Optional "what are you focusing on?" label.
class _FocusField extends StatelessWidget {
  const _FocusField({
    required this.controller,
    required this.hint,
    required this.isDark,
    required this.primary,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: focusTaskLabelMaxLength,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              textInputAction: TextInputAction.done,
              style: AstraKit.body(context, isDark, fontSize: 14.5),
              cursorColor: primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                hintText: hint,
                hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14)
                    .copyWith(color: AstraKit.faint(context, isDark)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill(
      {required this.label,
      required this.selected,
      required this.isDark,
      required this.primary,
      required this.onTap});

  final String label;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? primary.withValues(alpha: 0.85)
                : (isDark ? const Color(0x33231845) : const Color(0x99FBF1DD)),
            border: Border.all(
                color: selected ? primary : primary.withValues(alpha: 0.25),
                width: 1.2),
          ),
          child: Text(
            label,
            style: AstraKit.body(context, isDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF1A0F00) : null),
          ),
        ),
      ),
    );
  }
}

/// A labelled −/+ stepper for choosing a custom duration in minutes.
class _DurationStepper extends StatelessWidget {
  const _DurationStepper({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.isDark,
    required this.primary,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int value;
  final String unit;
  final int min;
  final int max;
  final int step;
  final bool isDark;
  final Color primary;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0x33231845) : const Color(0x80FBF1DD),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Text(label,
              style: AstraKit.body(context, isDark,
                  fontSize: 14.5, fontWeight: FontWeight.w700)),
          const Spacer(),
          _StepBtn(
            icon: Icons.remove_rounded,
            enabled: value > min,
            primary: primary,
            isDark: isDark,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          SizedBox(
            width: 74,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.center,
              style: AstraKit.heading1(context, isDark, fontSize: 18),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            enabled: value < max,
            primary: primary,
            isDark: isDark,
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: isDark ? 0.22 : 0.14),
            border: Border.all(color: primary.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 20, color: primary),
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.primary,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: filled ? 64 : 52,
            height: filled ? 64 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? primary
                  : (isDark
                      ? const Color(0x33231845)
                      : const Color(0x99FBF1DD)),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
            ),
            child: Icon(icon,
                color: filled ? const Color(0xFF1A0F00) : primary,
                size: filled ? 30 : 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AstraKit.mutedText(context, isDark, fontSize: 11.5)),
      ],
    );
  }
}
