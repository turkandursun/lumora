import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';

const _rainAsset = 'audio/rain_loop.mp3';

const _guideTr = [
  'Nefesini nazikçe izle.',
  'Omuzlarını gevşet.',
  'Düşünceler gelip geçsin.',
  'Şu ana geri dön.',
  'Bedenini hisset.',
  'Sadece burada ol.',
];
const _guideEn = [
  'Gently follow your breath.',
  'Relax your shoulders.',
  'Let thoughts come and go.',
  'Return to this moment.',
  'Feel your body.',
  'Just be here.',
];

enum _Stage { setup, running, done }

class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  // Rain plays quietly, and ducks even lower while the guide voice speaks so
  // the words stay clear.
  static const double _rainVolume = 0.28;
  static const double _rainDuck = 0.08;

  _Stage _stage = _Stage.setup;
  int _minutes = 5;
  bool _soundOn = true;
  bool _voiceOn = true;

  int _remaining = 0;
  int _total = 0;
  int _guideIndex = 0;
  List<String> _guides = _guideTr;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    // Bring the rain back up once each spoken line finishes.
    _tts.setCompletionHandler(() {
      if (_soundOn && _stage == _Stage.running) {
        _safe(() => _player.setVolume(_rainVolume));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _safe(() => _player.dispose());
    _safe(() => _tts.stop());
    super.dispose();
  }

  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      // Audio / speech are niceties; never let them crash the session.
    }
  }

  Future<void> _configureTts(bool isTr) async {
    try {
      await _tts.setLanguage(isTr ? 'tr-TR' : 'en-US');
      await _selectNiceVoice(isTr);
      await _tts.setSpeechRate(0.44);
      // A slightly higher pitch reads softer / more feminine.
      await _tts.setPitch(1.12);
      await _tts.setVolume(1.0);
    } catch (_) {
      // Fall back to the engine defaults if configuration isn't supported.
    }
  }

  /// Best-effort: pick a voice for the language, preferring one that looks
  /// female, so the guidance sounds warmer than the default.
  Future<void> _selectNiceVoice(bool isTr) async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;
      final prefix = isTr ? 'tr' : 'en';
      final matches = <Map<String, String>>[];
      for (final v in raw) {
        if (v is Map) {
          final name = v['name']?.toString() ?? '';
          final locale = v['locale']?.toString() ?? '';
          if (name.isNotEmpty && locale.toLowerCase().startsWith(prefix)) {
            matches.add({'name': name, 'locale': locale});
          }
        }
      }
      if (matches.isEmpty) return;
      Map<String, String>? chosen;
      for (final v in matches) {
        final n = v['name']!.toLowerCase();
        if (n.contains('female') ||
            n.contains('woman') ||
            n.contains('-fem') ||
            n.contains('#female')) {
          chosen = v;
          break;
        }
      }
      chosen ??= matches.first;
      await _tts.setVoice(chosen);
    } catch (_) {
      // Voice selection isn't available on every engine; that's fine.
    }
  }

  Future<void> _speak(String text) async {
    if (!_voiceOn) return;
    // Duck the rain while speaking so the voice is clearly heard.
    if (_soundOn) _safe(() => _player.setVolume(_rainDuck));
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _start() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    _guides = isTr ? _guideTr : _guideEn;

    await _configureTts(isTr);

    setState(() {
      _stage = _Stage.running;
      _total = _minutes * 60;
      _remaining = _total;
      _guideIndex = 0;
    });

    if (_soundOn) {
      _safe(() => _player.play(AssetSource(_rainAsset), volume: _rainVolume));
    }
    _safe(() => _speak(_guides[0]));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _finish();
        return;
      }
      setState(() => _remaining--);
      final elapsed = _total - _remaining;
      final newIndex = (elapsed ~/ 12) % _guides.length;
      if (newIndex != _guideIndex) {
        setState(() => _guideIndex = newIndex);
        _safe(() => _speak(_guides[newIndex]));
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    _safe(() => _player.stop());
    _safe(() => _tts.stop());
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
  }

  void _stop() {
    _timer?.cancel();
    _safe(() => _player.stop());
    _safe(() => _tts.stop());
    if (!mounted) return;
    setState(() => _stage = _Stage.setup);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AstraCircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    isDark: isDark,
                    primaryColor: primary,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: switch (_stage) {
                      _Stage.setup => _SetupView(
                          key: const ValueKey('setup'),
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          minutes: _minutes,
                          soundOn: _soundOn,
                          voiceOn: _voiceOn,
                          onMinutes: (m) => setState(() => _minutes = m),
                          onToggleSound: (v) => setState(() => _soundOn = v),
                          onToggleVoice: (v) => setState(() => _voiceOn = v),
                          onStart: _start,
                        ),
                      _Stage.running => _RunningView(
                          key: const ValueKey('running'),
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          pulse: _pulse,
                          remaining: _remaining,
                          guideText: _guides[_guideIndex],
                          onStop: _stop,
                        ),
                      _Stage.done => _DoneView(
                          key: const ValueKey('done'),
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          onDone: () => setState(() => _stage = _Stage.setup),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    super.key,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.minutes,
    required this.soundOn,
    required this.voiceOn,
    required this.onMinutes,
    required this.onToggleSound,
    required this.onToggleVoice,
    required this.onStart,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final int minutes;
  final bool soundOn;
  final bool voiceOn;
  final ValueChanged<int> onMinutes;
  final ValueChanged<bool> onToggleSound;
  final ValueChanged<bool> onToggleVoice;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(isTr ? 'Meditasyon' : 'Meditation', style: AstraKit.heading1(isDark, fontSize: 26)),
          const SizedBox(height: 8),
          Text(isTr ? 'Ne kadar süre?' : 'How long?', style: AstraKit.mutedText(isDark, fontSize: 15)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final m in [3, 5, 10])
                _MinutePill(
                  label: isTr ? '$m dk' : '$m min',
                  selected: m == minutes,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => onMinutes(m),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _ToggleRow(
            icon: soundOn ? Icons.water_drop_rounded : Icons.water_drop_outlined,
            label: isTr ? 'Yağmur sesi' : 'Rain sound',
            value: soundOn,
            isDark: isDark,
            primary: primary,
            onChanged: onToggleSound,
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            icon: voiceOn ? Icons.record_voice_over_rounded : Icons.voice_over_off_rounded,
            label: isTr ? 'Sesli rehber' : 'Voice guide',
            value: voiceOn,
            isDark: isDark,
            primary: primary,
            onChanged: onToggleVoice,
          ),
          const SizedBox(height: 30),
          AstraGoldButton(isDark: isDark, label: isTr ? 'Başla' : 'Begin', icon: Icons.play_arrow_rounded, expand: false, onTap: onStart),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MinutePill extends StatelessWidget {
  const _MinutePill({required this.label, required this.selected, required this.isDark, required this.primary, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? primary.withValues(alpha: 0.85) : (isDark ? const Color(0x33231845) : const Color(0x55FFF8EE)),
            border: Border.all(color: selected ? primary : primary.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Text(
            label,
            style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF1A0F00) : null),
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.primary,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final Color primary;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(18, 2, 10, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w600))),
          Switch(value: value, activeThumbColor: primary, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({
    super.key,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.pulse,
    required this.remaining,
    required this.guideText,
    required this.onStop,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final Animation<double> pulse;
  final int remaining;
  final String guideText;
  final VoidCallback onStop;

  String get _time {
    final m = (remaining ~/ 60).toString();
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Text(
            guideText,
            key: ValueKey(guideText),
            textAlign: TextAlign.center,
            style: AstraKit.body(isDark, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 36),
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            final t = pulse.value;
            final size = 150 + t * 46;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? Colors.white : primary).withValues(alpha: 0.92),
                    primary.withValues(alpha: 0.45),
                    primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4 + 0.3 * t),
                    blurRadius: 40 + t * 24,
                    spreadRadius: 6 + t * 6,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 36),
        Text(_time, style: AstraKit.heading1(isDark, fontSize: 34)),
        const SizedBox(height: 30),
        TextButton.icon(
          onPressed: onStop,
          icon: Icon(Icons.stop_rounded, color: AstraKit.muted(isDark)),
          label: Text(isTr ? 'Bitir' : 'End', style: AstraKit.mutedText(isDark, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({super.key, required this.isTr, required this.isDark, required this.primary, required this.onDone});

  final bool isTr;
  final bool isDark;
  final Color primary;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.self_improvement_rounded, color: primary, size: 60),
        const SizedBox(height: 18),
        Text(isTr ? 'Tamamlandı 🌸' : 'Complete 🌸', style: AstraKit.heading1(isDark, fontSize: 24)),
        const SizedBox(height: 10),
        Text(
          isTr ? 'Kendine bu anı ayırdığın için teşekkürler.' : 'Thank you for giving yourself this moment.',
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(isDark, fontSize: 14.5),
        ),
        const SizedBox(height: 30),
        AstraGoldButton(isDark: isDark, label: isTr ? 'Bitir' : 'Done', icon: Icons.play_arrow_rounded, expand: false, onTap: onDone),
      ],
    );
  }
}
