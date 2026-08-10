import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';

/// Focus timer — a gentle Pomodoro for ADHD-friendly focus: pick a focus/break
/// length, and the screen guides you through a work sprint and a short rest,
/// counting the sessions you finish today for a small sense of momentum.
class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

enum _Phase { idle, focus, breakTime }

class _Preset {
  const _Preset(this.focus, this.rest);
  final int focus; // minutes
  final int rest; // minutes
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  static const _presets = [_Preset(25, 5), _Preset(15, 3), _Preset(50, 10)];

  late final AnimationController _pulse;
  _Preset _preset = _presets.first;
  _Phase _phase = _Phase.idle;
  bool _running = false;
  int _remaining = 0;
  int _completedToday = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startFocus() {
    setState(() {
      _phase = _Phase.focus;
      _remaining = _preset.focus * 60;
      _running = true;
    });
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _onPhaseComplete();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    if (_phase == _Phase.focus) {
      setState(() {
        _completedToday++;
        _phase = _Phase.breakTime;
        _remaining = _preset.rest * 60;
      });
      _tick();
    } else {
      // Break finished — back to idle, ready for another sprint.
      setState(() {
        _phase = _Phase.idle;
        _running = false;
        _remaining = 0;
      });
    }
  }

  void _togglePause() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _tick();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _running = false;
      _remaining = 0;
    });
  }

  void _skipToBreakOrEnd() => _onPhaseComplete();

  String get _time {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);
    final isBreak = _phase == _Phase.breakTime;

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
                      Text(isTr ? 'Odak' : 'Focus', style: AstraKit.heading1(isDark, fontSize: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: _phase == _Phase.idle ? _buildSetup(isTr, isDark, primary) : _buildRunning(isTr, isDark, primary, isBreak),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetup(bool isTr, bool isDark, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Text(isTr ? 'Ne kadar odaklanalım?' : 'How long to focus?', style: AstraKit.mutedText(isDark, fontSize: 15)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final p in _presets)
                _PresetPill(
                  label: isTr ? '${p.focus} dk odak · ${p.rest} dk mola' : '${p.focus}m focus · ${p.rest}m break',
                  selected: p == _preset,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => setState(() => _preset = p),
                ),
            ],
          ),
          const SizedBox(height: 30),
          if (_completedToday > 0) ...[
            Text(
              isTr ? 'Bugün $_completedToday seans tamamladın 🎉' : 'You finished $_completedToday sessions today 🎉',
              style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w700, color: primary),
            ),
            const SizedBox(height: 20),
          ],
          AstraGoldButton(
            isDark: isDark,
            label: isTr ? 'Başla' : 'Start',
            icon: Icons.play_arrow_rounded,
            expand: false,
            onTap: _startFocus,
          ),
        ],
      ),
    );
  }

  Widget _buildRunning(bool isTr, bool isDark, Color primary, bool isBreak) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isBreak ? (isTr ? 'Mola' : 'Break') : (isTr ? 'Odaklan' : 'Focus'),
          style: AstraKit.body(isDark, fontSize: 16, fontWeight: FontWeight.w700, color: primary),
        ),
        const SizedBox(height: 30),
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            final t = _pulse.value;
            final size = 190 + t * 24;
            return Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isBreak ? const Color(0xFF7FD1B0) : primary).withValues(alpha: 0.9),
                    primary.withValues(alpha: 0.35),
                    primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Text(_time, style: AstraKit.heading1(isDark, fontSize: 40)),
            );
          },
        ),
        const SizedBox(height: 30),
        Text(
          isBreak
              ? (isTr ? 'Gözlerini dinlendir, biraz esne.' : 'Rest your eyes, stretch a little.')
              : (isTr ? 'Tek bir işe odaklan. Yeterince iyi, yeterlidir.' : 'Focus on one thing. Good enough is enough.'),
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(isDark, fontSize: 13.5),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundControl(icon: Icons.refresh_rounded, label: isTr ? 'Sıfırla' : 'Reset', isDark: isDark, primary: primary, onTap: _reset),
            const SizedBox(width: 16),
            _RoundControl(
              icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: _running ? (isTr ? 'Duraklat' : 'Pause') : (isTr ? 'Devam' : 'Resume'),
              isDark: isDark,
              primary: primary,
              filled: true,
              onTap: _togglePause,
            ),
            const SizedBox(width: 16),
            _RoundControl(icon: Icons.skip_next_rounded, label: isTr ? 'Geç' : 'Skip', isDark: isDark, primary: primary, onTap: _skipToBreakOrEnd),
          ],
        ),
      ],
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({required this.label, required this.selected, required this.isDark, required this.primary, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? primary.withValues(alpha: 0.85) : (isDark ? const Color(0x33231845) : const Color(0x99FBF1DD)),
            border: Border.all(color: selected ? primary : primary.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Text(
            label,
            style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF1A0F00) : null),
          ),
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
              color: filled ? primary : (isDark ? const Color(0x33231845) : const Color(0x99FBF1DD)),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: filled ? const Color(0xFF1A0F00) : primary, size: filled ? 30 : 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AstraKit.mutedText(isDark, fontSize: 11.5)),
      ],
    );
  }
}
