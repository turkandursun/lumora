import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/dreams_providers.dart';

/// Full-screen dream entry form: a large free-form text area, a voice-to-
/// text panel (same dictation flow as the journal writing screen, minus the
/// saved audio file — dreams don't have an audio column), and a save
/// button. Pushed from [DreamJournalScreen]'s "Write a Dream" button.
/// Saving hands off to [DreamReflectionScreen] for its short optional
/// follow-up questions, replacing this screen in the stack so a later
/// "Skip"/"Finish" there pops straight back to the dream list.
class NewDreamScreen extends ConsumerStatefulWidget {
  const NewDreamScreen({super.key});

  @override
  ConsumerState<NewDreamScreen> createState() => _NewDreamScreenState();
}

class _NewDreamScreenState extends ConsumerState<NewDreamScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _stt = stt.SpeechToText();
  bool _isSaving = false;
  String? _error;

  bool _sttInitialized = false;
  bool _isListening = false;
  String _preSpeechText = '';
  Timer? _waveTicker;

  late final AnimationController _waveController;
  late final List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _barHeights =
        List.generate(15, (i) => 0.2 + math.Random().nextDouble() * 0.5);
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
  }

  Future<void> _initSpeechToText() async {
    try {
      _sttInitialized = await _stt.initialize(
        onError: (v) => debugPrint('[STT] error: $v'),
        onStatus: (v) => debugPrint('[STT] status: $v'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[STT] init failed: $e');
    }
  }

  Future<void> _startVoiceSession() async {
    if (!_sttInitialized) await _initSpeechToText();

    _preSpeechText = _controller.text;
    if (_preSpeechText.isNotEmpty && !_preSpeechText.endsWith(' ')) {
      _preSpeechText += ' ';
    }

    if (_sttInitialized && mounted) {
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      try {
        await _stt.listen(
          listenOptions: stt.SpeechListenOptions(
            cancelOnError: false,
            partialResults: true,
            listenMode: stt.ListenMode.dictation,
            localeId: isTr ? 'tr_TR' : 'en_US',
          ),
          onResult: (result) {
            if (!mounted) return;
            setState(() {
              if (_error != null) _error = null;
              _controller.text = _preSpeechText + result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length));
            });
          },
        );
      } catch (e) {
        debugPrint('[STT] listen error: $e');
      }
    }

    _waveController.repeat(reverse: true);
    _waveTicker?.cancel();
    _waveTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = 0.15 + math.Random().nextDouble() * 0.85;
        }
      });
    });

    setState(() => _isListening = true);
  }

  Future<void> _stopVoiceSession() async {
    _waveTicker?.cancel();
    _waveTicker = null;
    _waveController.stop();
    try {
      await _stt.stop();
    } catch (_) {}
    for (var i = 0; i < _barHeights.length; i++) {
      _barHeights[i] = 0.2 + math.Random().nextDouble() * 0.3;
    }
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _waveTicker?.cancel();
    _controller.dispose();
    _stt.stop();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = l10n.dreamEntryValidationEmpty);
      return;
    }
    if (_isListening) await _stopVoiceSession();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final id = await ref.read(dreamsRepositoryProvider).addDream(text);

    if (!mounted) return;
    context.pushReplacement(AppRoutes.dreamReflection, extra: id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.dreamEntryTitle,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 220,
                          child: AstraGlassCard(
                            isDark: isDark,
                            primaryColor: _error != null
                                ? const Color(0xFFE07A7A)
                                : primary,
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: AstraKit.body(context, isDark),
                              cursorColor: primary,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                filled: false,
                                hintText: l10n.dreamEntryPlaceholder,
                                hintStyle: AstraKit.mutedText(context, isDark),
                              ),
                              onChanged: (_) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!,
                              style: const TextStyle(
                                  fontSize: 12.5, color: Color(0xFFE07A7A))),
                        ],
                        const SizedBox(height: 12),

                        // ── Voice panel — same dictation flow as the
                        // journal writing screen.
                        AstraGlassCard(
                          isDark: isDark,
                          primaryColor: primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 14, color: primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    isTr ? 'Sesle yaz' : 'Voice type',
                                    style: AstraKit.body(context, isDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isTr
                                    ? 'Rüyanı sesinle anlatabilirsin.'
                                    : 'You can describe your dream with your voice.',
                                style: AstraKit.mutedText(context, isDark,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _WaveformBars(
                                    heights: _barHeights.sublist(0, 7),
                                    active: _isListening,
                                    primary: primary,
                                    mirrored: true,
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: _isListening
                                        ? _stopVoiceSession
                                        : _startVoiceSession,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: _isListening
                                              ? [
                                                  Colors.redAccent.shade100,
                                                  Colors.redAccent
                                                ]
                                              : [
                                                  primary.withValues(
                                                      alpha: 0.95),
                                                  primary.withValues(alpha: 0.6)
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isListening
                                                    ? Colors.redAccent
                                                    : primary)
                                                .withValues(alpha: 0.55),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isListening
                                            ? Icons.stop_rounded
                                            : Icons.mic_rounded,
                                        color: Colors.black,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _WaveformBars(
                                    heights: _barHeights.sublist(8),
                                    active: _isListening,
                                    primary: primary,
                                    mirrored: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        AstraGoldButton(
                          isDark: isDark,
                          label: l10n.dreamEntrySaveButton,
                          isLoading: _isSaving,
                          enabled: !_isSaving,
                          height: 56,
                          onTap: _save,
                        ),
                      ],
                    ),
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

/// Animated waveform bars — same look as the journal writing screen's.
class _WaveformBars extends StatelessWidget {
  const _WaveformBars({
    required this.heights,
    required this.active,
    required this.primary,
    required this.mirrored,
  });

  final List<double> heights;
  final bool active;
  final Color primary;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final bars = mirrored ? heights.reversed.toList() : heights;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: bars.map((h) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: (active ? h * 36.0 : 8.0).clamp(4.0, 36.0),
          decoration: BoxDecoration(
            color: active
                ? primary.withValues(alpha: 0.7 + h * 0.3)
                : primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}
