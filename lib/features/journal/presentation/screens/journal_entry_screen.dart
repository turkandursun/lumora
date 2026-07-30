import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/crisis_detection_service.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/gold_glass_theme.dart';
import '../../../../theme/responsive_content.dart';

import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../goals/data/goals_repository.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../providers/journal_entries_provider.dart';
import '../providers/journal_streak_provider.dart';

/// Exact replica of the reference screenshot:
/// Moon background · Date+Title card · Writing card · Voice card ·
/// Action bar (Fotoğraf / Etiket / Duygu / Hatırlatıcı / Yıldızla) ·
/// "Günlüğü Mühürle" gold pill.
class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen>
    with TickerProviderStateMixin {
  final _entryController = TextEditingController();
  final _titleController = TextEditingController();
  final _recorder = AudioRecorder();
  final _stt = stt.SpeechToText();

  bool _sttInitialized = false;
  bool _isListeningAndRecording = false;
  bool _keepVoiceRecording = true;

  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTicker;
  String? _pendingAudioPath;
  String _preSpeechText = '';

  DateTime _selectedDate = DateTime.now();

  // Waveform animation
  late final AnimationController _waveController;
  late final List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _entryController.addListener(_onTextChanged);

    // Waveform bars (15 bars)
    _barHeights = List.generate(15, (i) => 0.2 + math.Random().nextDouble() * 0.5);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
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

  @override
  void dispose() {
    _entryController.removeListener(_onTextChanged);
    _entryController.dispose();
    _titleController.dispose();
    _recordingTicker?.cancel();
    _recorder.dispose();
    _stt.stop();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            onPrimary: Colors.black,
            surface: Color(0xFF1A1233),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _startVoiceSession() async {
    bool hasPermission;
    try {
      hasPermission = await _recorder.hasPermission();
    } catch (_) {
      hasPermission = false;
    }

    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mikrofon izni gerekli.')),
      );
      return;
    }

    if (!_sttInitialized) await _initSpeechToText();

    try {
      if (kIsWeb) {
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: 'entry_${DateTime.now().millisecondsSinceEpoch}.webm',
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final voiceDir = Directory(p.join(dir.path, 'voice_notes'));
        if (!await voiceDir.exists()) await voiceDir.create(recursive: true);
        const candidates = [AudioEncoder.aacLc, AudioEncoder.opus, AudioEncoder.wav];
        var encoder = AudioEncoder.aacLc;
        for (final c in candidates) {
          if (await _recorder.isEncoderSupported(c)) {
            encoder = c;
            break;
          }
        }
        final ext = encoder == AudioEncoder.opus
            ? 'ogg'
            : encoder == AudioEncoder.wav
                ? 'wav'
                : 'm4a';
        await _recorder.start(
          RecordConfig(encoder: encoder),
          path: p.join(voiceDir.path, 'entry_${DateTime.now().millisecondsSinceEpoch}.$ext'),
        );
      }
    } catch (e) {
      debugPrint('[VoiceNote] recorder start failed: $e');
    }

    _preSpeechText = _entryController.text;
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
              _entryController.text = _preSpeechText + result.recognizedWords;
              _entryController.selection =
                  TextSelection.fromPosition(TextPosition(offset: _entryController.text.length));
            });
          },
        );
      } catch (e) {
        debugPrint('[STT] listen error: $e');
      }
    }

    // Animate waveform
    _waveController.repeat(reverse: true);

    final startedAt = DateTime.now();
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _recordingElapsed = DateTime.now().difference(startedAt);
        // Randomly shift bar heights for live waveform effect
        for (var i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = 0.15 + math.Random().nextDouble() * 0.85;
        }
      });
    });

    setState(() {
      _isListeningAndRecording = true;
      _recordingElapsed = Duration.zero;
      _pendingAudioPath = null;
      _keepVoiceRecording = true;
    });
  }

  Future<void> _stopVoiceSession() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _waveController.stop();

    String? audioPath;
    try {
      audioPath = await _recorder.stop();
    } catch (_) {}
    try {
      await _stt.stop();
    } catch (_) {}

    // Reset bars to idle state
    for (var i = 0; i < _barHeights.length; i++) {
      _barHeights[i] = 0.2 + math.Random().nextDouble() * 0.3;
    }

    if (!mounted) return;
    setState(() {
      _isListeningAndRecording = false;
      _pendingAudioPath = audioPath;
    });
  }

  Future<void> _removePendingAudio() async {
    final path = _pendingAudioPath;
    setState(() {
      _pendingAudioPath = null;
      _keepVoiceRecording = false;
    });
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _saveEntry() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) return;

    if (CrisisDetectionService.containsCrisisLanguage(content)) {
      CrisisSupportSheet.show(context);
    }

<<<<<<< HEAD
    final audioPath = _pendingAudioPath;
    if (_editingEntry != null) {
      await ref.read(journalEntriesRepositoryProvider).update(
        _editingEntry!.id,
        content: content,
        audioPath: audioPath,
        supabaseId: _editingEntry!.supabaseId,
      );
    } else {
      await ref.read(journalEntriesRepositoryProvider).save(content, audioPath: audioPath);
      await ref.read(journalStreakProvider.notifier).recordEntrySaved();
      // Auto-advance the "journal" goal when a new entry is written.
      await ref
          .read(goalsRepositoryProvider)
          .incrementByIconKey(DefaultGoalIconKeys.journal, 10);
      ref.read(goalStreakProvider.notifier).refresh();
    }
=======
    final audioPath = _keepVoiceRecording ? _pendingAudioPath : null;
    await ref.read(journalEntriesRepositoryProvider).save(content, audioPath: audioPath);
    await ref.read(journalStreakProvider.notifier).recordEntrySaved();
>>>>>>> 09dd9a024fac84c2547991009d9b25974832f166

    if (!mounted) return;
    _entryController.clear();
    _titleController.clear();
    setState(() {
      _pendingAudioPath = null;
      _keepVoiceRecording = true;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(astraThemeProvider);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = mode == AstraThemeMode.dark;
    final primary = isDark ? AstraGlassTheme.moonPrimary : AstraGlassTheme.sunPrimary;

    final localeStr = Localizations.localeOf(context).toString();
    final dateStr = DateFormat('d MMMM yyyy, EEEE', localeStr).format(_selectedDate);

    return Scaffold(
      body: DynamicAstraBackground(
        mode: mode,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: ResponsiveContent(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── App Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _CircleBtn(
                              icon: Icons.arrow_back_ios_new_rounded,
                              primary: primary,
                              isDark: isDark,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            _CircleBtn(
                              icon: Icons.auto_awesome,
                              primary: primary,
                              isDark: isDark,
                              onTap: () {
                                final next = isDark
                                    ? AstraThemeMode.light
                                    : AstraThemeMode.dark;
                                ref.read(astraThemeProvider.notifier).setTheme(next);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Card 1: Date + Title
                        _GlassCard(
                          isDark: isDark,
                          primary: primary,
                          child: Row(
                            children: [
                              // Date column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.auto_awesome,
                                            size: 13, color: primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          isTr ? 'Tarih' : 'Date',
                                          style: _labelStyle(primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _pickDate,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dateStr,
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFFEDE0FF)
                                                    : const Color(0xFF1A1005),
                                              ),
                                            ),
                                          ),
                                          Icon(Icons.calendar_today_outlined,
                                              size: 16, color: primary),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Divider
                              Container(
                                width: 1,
                                height: 44,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: primary.withValues(alpha: 0.25),
                              ),

                              // Title column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.auto_awesome,
                                            size: 13, color: primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          isTr ? 'Başlık' : 'Title',
                                          style: _labelStyle(primary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _titleController,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      cursorColor: primary,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                        hintText: isTr
                                            ? 'Günün özeti...'
                                            : 'Summary...',
                                        hintStyle: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0x88C0A8FF)
                                              : const Color(0x88996600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Card 2: Main Writing Area
                        _GlassCard(
                          isDark: isDark,
                          primary: primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 200,
                                child: TextField(
                                  controller: _entryController,
                                  maxLines: null,
                                  expands: true,
                                  maxLength: 5000,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: Colors.black,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  cursorColor: primary,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    counterText: '',
                                    hintText: isTr
                                        ? 'Bugün aklından geçenleri yaz...'
                                        : 'Write what is on your mind today...',
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: isDark
                                          ? const Color(0x77C0A8FF)
                                          : const Color(0x77996633),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_entryController.text.length} / 5000',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0x88C0A8FF)
                                          : const Color(0x88996600),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.auto_awesome,
                                      size: 13, color: primary.withValues(alpha: 0.7)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Card 3: Voice Panel
                        _GlassCard(
                          isDark: isDark,
                          primary: primary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 14, color: primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    isTr ? 'Sesle yaz' : 'Voice type',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFFEDE0FF)
                                          : const Color(0xFF1A1005),
                                    ),
                                  ),
                                  if (pendingAudioPath != null) ...[
                                    const Spacer(),
                                    Icon(Icons.check_circle,
                                        size: 16,
                                        color: Colors.greenAccent.withValues(alpha: 0.9)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isTr
                                    ? 'Düşüncelerini sesinle kaydedebilirsin.'
                                    : 'You can record your thoughts with your voice.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0x99C0A8FF)
                                      : const Color(0x99664400),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Waveform + Mic button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left waveform bars
                                  _WaveformBars(
                                    heights: _barHeights.sublist(0, 7),
                                    active: _isListeningAndRecording,
                                    primary: primary,
                                    mirrored: true,
                                  ),

                                  const SizedBox(width: 12),

                                  // Circular mic button
                                  GestureDetector(
                                    onTap: _isListeningAndRecording
                                        ? _stopVoiceSession
                                        : _startVoiceSession,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: _isListeningAndRecording
                                              ? [
                                                  Colors.redAccent.shade100,
                                                  Colors.redAccent,
                                                ]
                                              : [
                                                  primary.withValues(alpha: 0.85),
                                                  isDark
                                                      ? const Color(0xFF7653D9)
                                                      : const Color(0xFFB8860B),
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isListeningAndRecording
                                                    ? Colors.redAccent
                                                    : primary)
                                                .withValues(alpha: 0.55),
                                            blurRadius: 18,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isListeningAndRecording
                                            ? Icons.stop_rounded
                                            : Icons.mic_rounded,
                                        color: Colors.black,
                                        size: 26,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Right waveform bars
                                  _WaveformBars(
                                    heights: _barHeights.sublist(8),
                                    active: _isListeningAndRecording,
                                    primary: primary,
                                    mirrored: false,
                                  ),
                                ],
                              ),

                              // Recording toggle if audio saved
                              if (_pendingAudioPath != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.graphic_eq,
                                        size: 14, color: primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      isTr
                                          ? 'Ses kaydı saklansın mı?'
                                          : 'Keep voice recording?',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xBBC0A8FF)
                                              : const Color(0xBB665544)),
                                    ),
                                    const Spacer(),
                                    Switch.adaptive(
                                      value: _keepVoiceRecording,
                                      activeThumbColor: primary,
                                      onChanged: (val) {
                                        setState(() => _keepVoiceRecording = val);
                                        if (!val) _removePendingAudio();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom Action Bar + Save Button (fixed at bottom)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0x00000000),
                            const Color(0xCC0D0818),
                            const Color(0xFF0B0716),
                          ]
                        : [
                            const Color(0x00000000),
                            const Color(0xCCFAF0D8),
                            const Color(0xFFF5E8C8),
                          ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  children: [
                    // Action toolbar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ActionBtn(icon: Icons.photo_outlined, label: isTr ? 'Fotoğraf' : 'Photo', primary: primary, isDark: isDark, onTap: () {}),
                        _ActionBtn(icon: Icons.local_offer_outlined, label: isTr ? 'Etiket ekle' : 'Tag', primary: primary, isDark: isDark, onTap: () {}),
                        _ActionBtn(icon: Icons.download_outlined, label: isTr ? 'Duygu eki' : 'Mood', primary: primary, isDark: isDark, onTap: () {}),
                        _ActionBtn(icon: Icons.notifications_none_rounded, label: isTr ? 'Hatırlatıcı' : 'Remind', primary: primary, isDark: isDark, onTap: () {}),
                        _ActionBtn(icon: Icons.star_border_rounded, label: isTr ? 'Yıldızla' : 'Star', primary: primary, isDark: isDark, onTap: () {}),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // "Günlüğü Mühürle" gold pill button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _entryController,
                      builder: (ctx, val, _) {
                        final enabled =
                            val.text.trim().isNotEmpty && !_isListeningAndRecording;
                        return _SealButton(
                          isDark: isDark,
                          primary: primary,
                          enabled: enabled,
                          isTr: isTr,
                          onTap: _saveEntry,
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 13,
                            color: primary.withValues(alpha: 0.6)),
                        const SizedBox(width: 5),
                        Text(
                          isTr
                              ? 'Günlüğün sadece seninle güvende.'
                              : 'Your journal is safe & private with you.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0x88C0A8FF)
                                : const Color(0x88664400),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Icon(Icons.auto_awesome,
                        size: 12, color: primary.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get pendingAudioPath => _pendingAudioPath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _labelStyle(Color primary) => GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.3,
    );

// Semi-transparent glass card matching the screenshot
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.isDark,
    required this.primary,
    required this.child,
  });

  final bool isDark;
  final Color primary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x44231845)
            : const Color(0x55FFF8EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

// Circular icon button
class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0x44231845) : const Color(0x55FFF8EE),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: primary),
      ),
    );
  }
}

// Animated waveform bars
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

// Bottom action toolbar button
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: primary.withValues(alpha: 0.85)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xBBC0A8FF)
                  : const Color(0xBB664400),
            ),
          ),
        ],
      ),
    );
  }
}

// Gold "Günlüğü Mühürle" pill button
class _SealButton extends StatelessWidget {
  const _SealButton({
    required this.isDark,
    required this.primary,
    required this.enabled,
    required this.isTr,
    required this.onTap,
  });

  final bool isDark;
  final Color primary;
  final bool enabled;
  final bool isTr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFFD4B860), Color(0xFFB89030), Color(0xFF8A6A10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFD966), Color(0xFFD4A820), Color(0xFFAA8010)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: enabled
                ? gradient
                : LinearGradient(
                    colors: [
                      const Color(0x44D4AF37),
                      const Color(0x22B8860B),
                    ],
                  ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              // Wax seal icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Günlüğü Mühürle' : 'Save Journal',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0F00),
                      ),
                    ),
                    Text(
                      isTr
                          ? 'Bu anı sakla ve yolculuğuna devam et.'
                          : 'Preserve this moment and continue.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0x99331100),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFF1A0F00), size: 18),
              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}
