import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../data/meditation_voice_service.dart';
import '../../domain/meditation_voices.dart';
import '../../../goals/domain/goal_template.dart';
import '../../../goals/presentation/providers/goals_providers.dart';

const _rainAsset = 'audio/rain_loop.mp3';

// ── Meditation focus themes ────────────────────────────────────────────────
// Informed by how leading meditation apps (Calm, Headspace, Insight Timer,
// Balance, Medito) structure their libraries: the user first picks an
// intention, then a length. Affirmations follow evidence-informed style —
// first person, present tense, positive framing, self-compassion — rather than
// terse commands, so they land warmer and feel personally reassuring.
enum _Focus { calm, selfLove, confidence, sleep }

class _FocusData {
  const _FocusData({
    required this.icon,
    required this.labelTr,
    required this.labelEn,
    required this.tr,
    required this.en,
  });

  final IconData icon;
  final String labelTr;
  final String labelEn;
  final List<String> tr;
  final List<String> en;
}

const Map<_Focus, _FocusData> _focusData = {
  _Focus.calm: _FocusData(
    icon: Icons.spa_rounded,
    labelTr: 'Sakinlik',
    labelEn: 'Calm',
    tr: [
      'Bu an güvendeyim ve huzurluyum.',
      'Her nefeste biraz daha sakinleşiyorum.',
      'Zihnim, durulan bir göl gibi berrak.',
      'Acele edecek hiçbir yer yok; sadece buradayım.',
      'Gerginliği bırakıyorum, yerini huzur alıyor.',
      'Bedenim yumuşuyor, omuzlarım gevşiyor.',
      'Şu an, olduğu haliyle bana yetiyor.',
    ],
    en: [
      'In this moment, I am safe and at peace.',
      'With every breath, I grow a little calmer.',
      'My mind is clear, like a lake growing still.',
      'There is nowhere to rush; I am simply here.',
      'I release tension and let calm take its place.',
      'My body softens and my shoulders relax.',
      'This moment, just as it is, is enough.',
    ],
  ),
  _Focus.selfLove: _FocusData(
    icon: Icons.favorite_rounded,
    labelTr: 'Öz-şefkat',
    labelEn: 'Self-love',
    tr: [
      'Olduğum halimle yeterliyim.',
      'Kendime nazik davranmayı hak ediyorum.',
      'Kalbime şefkatle yer açıyorum.',
      'Hatalarım beni insan yapar, değersiz değil.',
      'Kendimi olduğum gibi kabul ediyorum.',
      'Bugün kendime iyi bakıyorum.',
      'Sevgiyi hak ediyorum; önce kendimden.',
    ],
    en: [
      'I am enough, exactly as I am.',
      'I deserve to treat myself with kindness.',
      'I make gentle space for my own heart.',
      'My mistakes make me human, not unworthy.',
      'I accept myself just as I am.',
      'Today, I take good care of myself.',
      'I am worthy of love, starting with my own.',
    ],
  ),
  _Focus.confidence: _FocusData(
    icon: Icons.bolt_rounded,
    labelTr: 'Özgüven',
    labelEn: 'Confidence',
    tr: [
      'İhtiyacım olan güç zaten içimde.',
      'Zorlukların üstesinden gelebilirim.',
      'Kendime ve seçimlerime güveniyorum.',
      'Her adımda biraz daha güçleniyorum.',
      'Sesim değerli, söyleyeceklerim önemli.',
      'Yeterliyim ve yeteneklerime güveniyorum.',
      'Bugün cesaretle ileriye adım atıyorum.',
    ],
    en: [
      'The strength I need is already within me.',
      'I can rise to meet any challenge.',
      'I trust myself and my choices.',
      'With every step, I grow stronger.',
      'My voice matters, and so do my words.',
      'I am capable, and I trust my abilities.',
      'Today, I step forward with courage.',
    ],
  ),
  _Focus.sleep: _FocusData(
    icon: Icons.bedtime_rounded,
    labelTr: 'Uyku',
    labelEn: 'Sleep',
    tr: [
      'Günü geride bırakıyorum, dinlenmeye hazırım.',
      'Bedenim ağırlaşıyor ve derinden gevşiyor.',
      'Her nefes beni uykuya biraz daha yaklaştırıyor.',
      'Bugün elimden geleni yaptım; bu yeterli.',
      'Zihnim yavaşça sessizleşiyor.',
      'Kendimi huzurla teslim ediyorum.',
      'Yarın yeni bir gün; şimdi sadece dinleniyorum.',
    ],
    en: [
      'I let the day go and I am ready to rest.',
      'My body grows heavy and deeply relaxed.',
      'Each breath carries me closer to sleep.',
      'I did my best today, and that is enough.',
      'My mind grows quiet, slowly and softly.',
      'I surrender myself to peace.',
      'Tomorrow is a new day; for now, I simply rest.',
    ],
  ),
};

enum _Stage { setup, running, done }

class MeditationScreen extends ConsumerStatefulWidget {
  const MeditationScreen({super.key});

  @override
  ConsumerState<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends ConsumerState<MeditationScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final MeditationVoiceService _voice = MeditationVoiceService();

  // Ambient sound plays softly, and ducks even lower while the guide voice
  // speaks so the words stay clear. A gentle fade in/out avoids an abrupt,
  // jarring start — the old hard cut was part of what read as "harsh".
  static const double _ambientVolume = 0.22;
  static const double _ambientDuck = 0.06;
  double _ambientCurrent = 0; // ramps toward _ambientVolume (fade-in)
  bool _speaking = false;
  Timer? _fadeTimer;

  _Stage _stage = _Stage.setup;
  bool _completionHandled = false;
  _Focus _focus = _Focus.calm;
  int _minutes = 5;
  bool _soundOn = true;
  bool _voiceOn = true;
  static const _voicePrefKey = 'meditation_voice_key';
  String _voiceKey = meditationVoiceOptions.first.key;
  bool _breathIn = true;

  int _remaining = 0;
  int _total = 0;
  int _lineIndex = 0;
  List<String> _lines = const [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // ~5s in / ~5s out ≈ 6 breaths per minute — a calming "coherent breathing"
    // pace. The orb expands on the in-breath and contracts on the out-breath.
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _pulse!.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.forward && !_breathIn) {
        setState(() => _breathIn = true);
      } else if (status == AnimationStatus.reverse && _breathIn) {
        setState(() => _breathIn = false);
      }
    });
    _player.setReleaseMode(ReleaseMode.loop);
    // Bring the ambient sound back up once each spoken line finishes.
    _tts.setCompletionHandler(() {
      _speaking = false;
      if (_soundOn && _stage == _Stage.running) {
        _safe(() => _player.setVolume(_ambientCurrent));
      }
    });
    // Bring ambient back up when an ElevenLabs voice clip finishes too.
    _voicePlayer.onPlayerComplete.listen((_) {
      _speaking = false;
      if (_soundOn && _stage == _Stage.running) {
        _safe(() => _player.setVolume(_ambientCurrent));
      }
    });
    // Restore the previously chosen guide voice.
    SharedPreferences.getInstance().then((prefs) {
      final k = prefs.getString(_voicePrefKey);
      if (k != null &&
          meditationVoiceOptions.any((v) => v.key == k) &&
          mounted) {
        setState(() => _voiceKey = k);
      }
    });
  }

  void _selectVoice(String key) {
    setState(() => _voiceKey = key);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_voicePrefKey, key));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _pulse?.dispose();
    _safe(() => _player.dispose());
    _safe(() => _voicePlayer.dispose());
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
      await _selectFemaleVoice(isTr);
      // Slow, unhurried delivery with a soft, warm timbre.
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
      await _tts.setVolume(1.0);
    } catch (_) {
      // Fall back to the engine defaults if configuration isn't supported.
    }
  }

  /// Robustly pick a female voice for the language. The previous heuristic
  /// only matched literal "female" in the name, which most desktop/browser
  /// voices don't expose — so it fell through to the first (often male) voice.
  /// This scores every candidate against curated female/male name lists and
  /// retries a few times, since web (browser SpeechSynthesis) loads its voice
  /// list asynchronously and is empty on the first call.
  Future<void> _selectFemaleVoice(bool isTr) async {
    try {
      List<dynamic> raw = const [];
      for (var attempt = 0; attempt < 6; attempt++) {
        final v = await _tts.getVoices;
        if (v is List && v.isNotEmpty) {
          raw = v;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (raw.isEmpty) return;

      final prefix = isTr ? 'tr' : 'en';
      final exactLocale = isTr ? 'tr-tr' : 'en-us';

      // Substrings that strongly indicate a female voice across Android,
      // iOS/macOS, and Chrome/Edge browser voices.
      const femaleHints = [
        'female', '#female', '-fem', 'woman',
        // English
        'samantha', 'karen', 'moira', 'tessa', 'fiona', 'serena', 'allison',
        'ava', 'susan', 'zira', 'jenny', 'aria', 'michelle', 'sonia', 'libby',
        'natasha', 'clara', 'emily', 'joanna', 'salli', 'kimberly',
        'google us english', 'google uk english female',
        // Turkish
        'yelda', 'filiz', 'emel', 'seda', 'google türkçe', 'google turkce',
      ];
      // Substrings that indicate a male voice. Note: 'male' is a substring of
      // 'female', so any female match cancels male scoring below.
      const maleHints = [
        'male',
        '#male',
        'daniel',
        'alex',
        'fred',
        'aaron',
        'arthur',
        'david',
        'mark',
        'oliver',
        'george',
        'ryan',
        'thomas',
        'matthew',
        'tolga',
        'erkek',
        'google uk english male',
      ];

      Map<String, String>? best;
      var bestScore = -1 << 20;
      for (final item in raw) {
        if (item is! Map) continue;
        final name = (item['name']?.toString() ?? '');
        final locale = (item['locale']?.toString() ?? '');
        final ll = locale.toLowerCase();
        if (!ll.startsWith(prefix)) continue;

        final n = name.toLowerCase();
        final isFemale = femaleHints.any(n.contains);
        // 'female' contains 'male' — don't let that count against a female voice.
        final isMale = !isFemale && maleHints.any(n.contains);

        var score = 0;
        if (isFemale) score += 100;
        if (isMale) score -= 100;
        if (ll == exactLocale) score += 3;
        if (n.contains('google') ||
            n.contains('natural') ||
            n.contains('neural')) {
          score += 2; // richer network/neural voices sound warmer
        }

        if (score > bestScore) {
          bestScore = score;
          best = {'name': name, 'locale': locale};
        }
      }
      if (best != null) await _tts.setVoice(best);
    } catch (_) {
      // Voice selection isn't available on every engine; that's fine.
    }
  }

  Future<void> _speak(String text) async {
    if (!_voiceOn) return;
    _speaking = true;
    // Duck the ambient sound while speaking so the voice is clearly heard.
    if (_soundOn) _safe(() => _player.setVolume(_ambientDuck));

    // Try the natural ElevenLabs voice; fall back to the device's built-in
    // text-to-speech if it's unavailable (no key, offline, quota, etc.).
    final bytes =
        await _voice.voiceBytes(text, voiceId: voiceIdForKey(_voiceKey));
    if (!mounted || _stage != _Stage.running) return;
    if (bytes != null) {
      try {
        await _tts.stop();
        await _voicePlayer.stop();
        await _voicePlayer.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
        return;
      } catch (_) {
        // fall through to device TTS
      }
    }
    await _voicePlayer.stop();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Gentle fade-in of the ambient bed (0 → target over ~2.5s) so the session
  /// eases in instead of snapping on.
  void _startAmbientFadeIn() {
    _fadeTimer?.cancel();
    _ambientCurrent = 0;
    _safe(() => _player.setVolume(0));
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      _ambientCurrent = (_ambientCurrent + 0.015).clamp(0.0, _ambientVolume);
      if (!_speaking) _safe(() => _player.setVolume(_ambientCurrent));
      if (_ambientCurrent >= _ambientVolume) t.cancel();
    });
  }

  /// Quick fade-out, then stop — a soft landing instead of a hard cut.
  void _stopAmbient() {
    _fadeTimer?.cancel();
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _ambientCurrent = (_ambientCurrent - 0.03).clamp(0.0, _ambientVolume);
      _safe(() => _player.setVolume(_ambientCurrent));
      if (_ambientCurrent <= 0) {
        t.cancel();
        _safe(() => _player.stop());
      }
    });
  }

  Future<void> _start() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final data = _focusData[_focus]!;
    final source = List<String>.from(isTr ? data.tr : data.en);
    source.shuffle(math.Random()); // fresh order each session
    _lines = source;

    await _configureTts(isTr);

    setState(() {
      _completionHandled = false;
      _stage = _Stage.running;
      _total = _minutes * 60;
      _remaining = _total;
      _lineIndex = 0;
    });

    if (_soundOn) {
      _safe(() => _player.play(AssetSource(_rainAsset), volume: 0));
      _startAmbientFadeIn();
    }
    // Let the scene settle for a beat before the first affirmation.
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _stage == _Stage.running) _safe(() => _speak(_lines[0]));
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        unawaited(_finish());
        return;
      }
      setState(() => _remaining--);
      final elapsed = _total - _remaining;
      // A new affirmation every ~16s — unhurried, with room to breathe.
      final newIndex = (elapsed ~/ 16) % _lines.length;
      if (newIndex != _lineIndex) {
        setState(() => _lineIndex = newIndex);
        _safe(() => _speak(_lines[newIndex]));
      }
    });
  }

  Future<void> _finish() async {
    if (_completionHandled) return;
    _completionHandled = true;
    _timer?.cancel();
    _stopAmbient();
    _safe(() => _tts.stop());
    _safe(() => _voicePlayer.stop());
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
    // Auto-advance the "meditation" goal by the minutes just completed.
    await ref.read(goalsRepositoryProvider).incrementByTemplateKey(
          GoalTemplateKeys.meditation,
          _minutes,
        );
    await ref.read(goalStreakProvider.notifier).refresh();
  }

  void _stop() {
    _timer?.cancel();
    _stopAmbient();
    _safe(() => _tts.stop());
    _safe(() => _voicePlayer.stop());
    if (!mounted) return;
    setState(() => _stage = _Stage.setup);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

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
                          focus: _focus,
                          minutes: _minutes,
                          soundOn: _soundOn,
                          voiceOn: _voiceOn,
                          voiceKey: _voiceKey,
                          onFocus: (f) => setState(() => _focus = f),
                          onMinutes: (m) => setState(() => _minutes = m),
                          onToggleSound: (v) => setState(() => _soundOn = v),
                          onToggleVoice: (v) => setState(() => _voiceOn = v),
                          onVoice: _selectVoice,
                          onStart: _start,
                        ),
                      _Stage.running => _RunningView(
                          key: const ValueKey('running'),
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          pulse: _pulse!,
                          remaining: _remaining,
                          affirmation: _lines.isEmpty ? '' : _lines[_lineIndex],
                          breathIn: _breathIn,
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
    required this.focus,
    required this.minutes,
    required this.soundOn,
    required this.voiceOn,
    required this.voiceKey,
    required this.onFocus,
    required this.onMinutes,
    required this.onToggleSound,
    required this.onToggleVoice,
    required this.onVoice,
    required this.onStart,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final _Focus focus;
  final int minutes;
  final bool soundOn;
  final bool voiceOn;
  final String voiceKey;
  final ValueChanged<_Focus> onFocus;
  final ValueChanged<int> onMinutes;
  final ValueChanged<bool> onToggleSound;
  final ValueChanged<bool> onToggleVoice;
  final ValueChanged<String> onVoice;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(isTr ? 'Meditasyon' : 'Meditation',
              style: AstraKit.heading1(context, isDark, fontSize: 26)),
          const SizedBox(height: 8),
          Text(
            isTr ? 'Bugün neye ihtiyacın var?' : 'What do you need today?',
            style: AstraKit.mutedText(context, isDark, fontSize: 15),
          ),
          const SizedBox(height: 18),
          // Focus / intention picker.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final f in _Focus.values)
                _FocusChip(
                  data: _focusData[f]!,
                  label: isTr ? _focusData[f]!.labelTr : _focusData[f]!.labelEn,
                  selected: f == focus,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => onFocus(f),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text(isTr ? 'Ne kadar süre?' : 'How long?',
              style: AstraKit.mutedText(context, isDark, fontSize: 15)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final m in [3, 5, 10, 15])
                _MinutePill(
                  label: isTr ? '$m dk' : '$m min',
                  selected: m == minutes,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => onMinutes(m),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _ToggleRow(
            icon: soundOn ? Icons.graphic_eq_rounded : Icons.volume_off_rounded,
            label: isTr ? 'Ortam sesi' : 'Ambient sound',
            value: soundOn,
            isDark: isDark,
            primary: primary,
            onChanged: onToggleSound,
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            icon: voiceOn
                ? Icons.record_voice_over_rounded
                : Icons.voice_over_off_rounded,
            label: isTr ? 'Sesli rehber' : 'Voice guide',
            value: voiceOn,
            isDark: isDark,
            primary: primary,
            onChanged: onToggleVoice,
          ),
          // Named guide-voice picker (only when the voice guide is on).
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: voiceOn
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        Text(isTr ? 'Rehber sesi' : 'Guide voice',
                            style: AstraKit.mutedText(context, isDark,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final v in meditationVoiceOptions)
                              _VoiceChip(
                                label: v.name,
                                selected: v.key == voiceKey,
                                isDark: isDark,
                                primary: primary,
                                onTap: () => onVoice(v.key),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),
          AstraGoldButton(
              isDark: isDark,
              label: isTr ? 'Başla' : 'Begin',
              icon: Icons.play_arrow_rounded,
              expand: false,
              onTap: onStart),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({
    required this.data,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final _FocusData data;
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? primary.withValues(alpha: 0.85)
                : (isDark ? const Color(0x33231845) : const Color(0x99FBF1DD)),
            border: Border.all(
                color: selected ? primary : primary.withValues(alpha: 0.25),
                width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                size: 16,
                color: selected ? const Color(0xFF1A0F00) : primary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AstraKit.body(
                  context,
                  isDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFF1A0F00) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceChip extends StatelessWidget {
  const _VoiceChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? primary.withValues(alpha: 0.85)
                : (isDark ? const Color(0x33231845) : const Color(0x99FBF1DD)),
            border: Border.all(
                color: selected ? primary : primary.withValues(alpha: 0.25),
                width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.graphic_eq_rounded,
                  size: 15,
                  color: selected
                      ? const Color(0xFF1A0F00)
                      : primary.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AstraKit.body(context, isDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF1A0F00) : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinutePill extends StatelessWidget {
  const _MinutePill(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF1A0F00) : null),
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
      width: 260,
      padding: const EdgeInsets.fromLTRB(18, 2, 10, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0x33231845) : const Color(0x99FBF1DD),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: AstraKit.body(context, isDark,
                      fontSize: 14, fontWeight: FontWeight.w600))),
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
    required this.affirmation,
    required this.breathIn,
    required this.onStop,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final Animation<double> pulse;
  final int remaining;
  final String affirmation;
  final bool breathIn;
  final VoidCallback onStop;

  String get _time {
    final m = (remaining ~/ 60).toString();
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final breathLabel = breathIn
        ? (isTr ? 'Nefes al' : 'Breathe in')
        : (isTr ? 'Ver' : 'Breathe out');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Affirmation (spoken + shown), gently swapping every ~16s.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Padding(
            key: ValueKey(affirmation),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              affirmation,
              textAlign: TextAlign.center,
              style: AstraKit.body(context, isDark,
                  fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Breathing orb + breath cue.
        AnimatedBuilder(
          animation: pulse,
          builder: (context, _) {
            final t = pulse.value;
            final size = 150 + t * 46;
            return SizedBox(
              width: 242,
              height: 242,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? Colors.white : primary)
                            .withValues(alpha: 0.92),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      breathLabel,
                      key: ValueKey(breathLabel),
                      style: AstraKit.body(
                        context,
                        isDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF1A0F00) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        Text(_time, style: AstraKit.heading1(context, isDark, fontSize: 34)),
        const SizedBox(height: 26),
        TextButton.icon(
          onPressed: onStop,
          icon:
              Icon(Icons.stop_rounded, color: AstraKit.muted(context, isDark)),
          label: Text(isTr ? 'Bitir' : 'End',
              style: AstraKit.mutedText(context, isDark,
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView(
      {super.key,
      required this.isTr,
      required this.isDark,
      required this.primary,
      required this.onDone});

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
        Text(isTr ? 'Tamamlandı 🌸' : 'Complete 🌸',
            style: AstraKit.heading1(context, isDark, fontSize: 24)),
        const SizedBox(height: 10),
        Text(
          isTr
              ? 'Kendine bu anı ayırdığın için teşekkürler. Bu huzuru yanında taşı.'
              : 'Thank you for giving yourself this moment. Carry this calm with you.',
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(context, isDark, fontSize: 14.5),
        ),
        const SizedBox(height: 30),
        AstraGoldButton(
            isDark: isDark,
            label: isTr ? 'Bitir' : 'Done',
            icon: Icons.check_rounded,
            expand: false,
            onTap: onDone),
      ],
    );
  }
}
