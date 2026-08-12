import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/database/app_database.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/crisis_detection_service.dart';
import '../../../../core/services/journal_tone_service.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/responsive_content.dart';

import '../../../goals/domain/goal_template.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../controllers/journal_tone_feedback_controller.dart';
import '../providers/journal_entries_provider.dart';
import '../providers/journal_streak_provider.dart';
import '../widgets/journal_tone_feedback_sheet.dart';

/// Exact replica of the reference screenshot:
/// Moon background · Date+Title card · Writing card · Voice card ·
/// Action bar (Fotoğraf ekle / Etiket / Duygu / Hatırlatıcı) ·
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
  final _stt = stt.SpeechToText();

  bool _sttInitialized = false;
  // True while a voice-typing (speech-to-text) session is active. Audio note
  // recording was removed — voice input only dictates into the text field.
  bool _isListeningAndRecording = false;

  Timer? _recordingTicker;
  String _preSpeechText = '';
  JournalEntryRow? _editingEntry;
  late final JournalToneFeedbackController _toneFeedbackController;
  bool _isSaving = false;

  /// Optionally attached photo for this entry (local file path or web bytes).
  String? _pickedPhotoPath;
  Uint8List? _pickedPhotoBytes;

  DateTime _selectedDate = DateTime.now();

  // Waveform animation
  late final AnimationController _waveController;
  late final List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _entryController.addListener(_onTextChanged);
    _toneFeedbackController = JournalToneFeedbackController(
      JournalToneService(),
    );

    // Waveform bars (15 bars)
    _barHeights =
        List.generate(15, (i) => 0.2 + math.Random().nextDouble() * 0.5);
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
        onStatus: (v) {
          debugPrint('[STT] status: $v');
          // The recognizer stops itself after a pause; keep the mic button and
          // waveform in sync instead of leaving them stuck in "listening".
          if ((v == 'notListening' || v == 'done') &&
              _isListeningAndRecording) {
            _stopVoiceSession();
          }
        },
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
    _toneFeedbackController.dispose();
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
            primary: Color(0xFFC084FC),
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
    // Voice input is dictation only (speech-to-text) — no audio recording — so
    // the recognizer has sole use of the microphone and transcription works.
    if (!_sttInitialized) await _initSpeechToText();
    if (!_sttInitialized) {
      if (!mounted) return;
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Konuşma tanıma kullanılamıyor. Mikrofon iznini kontrol et.'
              : 'Speech recognition unavailable. Check microphone permission.'),
        ),
      );
      return;
    }

    _preSpeechText = _entryController.text;
    if (_preSpeechText.isNotEmpty && !_preSpeechText.endsWith(' ')) {
      _preSpeechText += ' ';
    }

    if (mounted) {
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
              _entryController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _entryController.text.length));
            });
          },
        );
      } catch (e) {
        debugPrint('[STT] listen error: $e');
      }
    }

    // Animate waveform while listening.
    _waveController.repeat(reverse: true);

    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = 0.15 + math.Random().nextDouble() * 0.85;
        }
      });
    });

    setState(() {
      _isListeningAndRecording = true;
    });
  }

  Future<void> _stopVoiceSession() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _waveController.stop();

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
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedPhotoBytes = bytes;
          _pickedPhotoPath = file.name;
        });
      } else {
        var path = file.path;
        try {
          final dir = await getApplicationDocumentsDirectory();
          final photoDir = Directory(p.join(dir.path, 'journal_photos'));
          if (!await photoDir.exists()) {
            await photoDir.create(recursive: true);
          }
          final ext = p.extension(file.path);
          final dest = p.join(photoDir.path,
              'photo_${DateTime.now().millisecondsSinceEpoch}$ext');
          await File(file.path).copy(dest);
          path = dest;
        } catch (e) {
          debugPrint('[Photo] copy failed, using original path: $e');
        }

        if (!mounted) return;
        setState(() {
          _pickedPhotoBytes = null;
          _pickedPhotoPath = path;
        });
      }
    } catch (e) {
      debugPrint('[Photo] pick failed: $e');
      if (!mounted) return;
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isTr ? 'Fotoğraf seçilemedi.' : 'Could not pick a photo.'),
        ),
      );
    }
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    final content = _entryController.text.trim();
    if (content.isEmpty) return;

    final crisisSupportTriggered =
        CrisisDetectionService.containsCrisisLanguage(content);
    if (crisisSupportTriggered) {
      unawaited(CrisisSupportSheet.show(context));
    }

    final title = _titleController.text.trim();
    final locale = Localizations.localeOf(context).languageCode;
    final repo = ref.read(journalEntriesRepositoryProvider);
    final editing = _editingEntry;
    setState(() => _isSaving = true);

    // Only journal persistence determines save success. Every streak, Goal and
    // AI operation starts after this block behind its own error boundary.
    try {
      if (editing != null) {
        await repo.update(
          editing.id,
          content: content,
          audioPath: editing.audioPath,
          photoUrl: editing.photoUrl,
          supabaseId: editing.supabaseId,
        );
      } else {
        await repo.save(
          content,
          title: title.isEmpty ? null : title,
          photoPath: _pickedPhotoPath,
          photoBytes: _pickedPhotoBytes,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[JournalSave] save failed: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'tr'
                ? 'Günlük kaydedilemedi. Lütfen tekrar dene.'
                : 'The journal could not be saved. Please try again.',
          ),
        ),
      );
      return;
    }

    if (editing != null) {
      // Edits persist but deliberately do not generate a second Goal event.
      debugPrint('[JournalSave] existing entry updated without goal progress');
    }
    if (!mounted) return;
    _entryController.clear();
    _titleController.clear();
    setState(() {
      _pickedPhotoPath = null;
      _pickedPhotoBytes = null;
      _editingEntry = null;
      _isSaving = false;
    });
    FocusScope.of(context).unfocus();
    _showSealedToast(context);

    if (editing == null) {
      unawaited(_runSecondaryJournalEffects());
      if (shouldAnalyzeSavedJournal(
        isNewEntry: true,
        crisisSupportTriggered: crisisSupportTriggered,
      )) {
        unawaited(_analyzeSavedJournal(content: content, locale: locale));
      }
    }
  }

  Future<void> _runSecondaryJournalEffects() async {
    final journalStreak = ref.read(journalStreakProvider.notifier);
    final goalsRepository = ref.read(goalsRepositoryProvider);
    final goalStreak = ref.read(goalStreakProvider.notifier);

    await runJournalSecondaryEffectSafely(
      () async {
        await journalStreak.recordEntrySaved();
      },
      onError: (error) => debugPrint(
        '[JournalSave] journal streak update skipped: ${error.runtimeType}',
      ),
    );
    await runJournalSecondaryEffectSafely(
      () async {
        await goalsRepository.incrementByTemplateKey(
          GoalTemplateKeys.journal,
          1,
        );
      },
      onError: (error) => debugPrint(
        '[JournalSave] journal goal progress skipped: ${error.runtimeType}',
      ),
    );
    await runJournalSecondaryEffectSafely(
      goalStreak.refresh,
      onError: (error) => debugPrint(
        '[JournalSave] goal streak refresh skipped: ${error.runtimeType}',
      ),
    );
  }

  Future<void> _analyzeSavedJournal({
    required String content,
    required String locale,
  }) async {
    try {
      // Present the feedback sheet immediately in a "Luma is reading…" state so
      // the user knows a reflection is on its way, then let it resolve in place.
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final isDark = ref.read(astraThemeProvider) == AstraThemeMode.dark;
      final analysisFuture = _toneFeedbackController.requestAnalysis(
        text: content,
        locale: locale,
      );
      await JournalToneFeedbackSheet.showAndNavigate(
        context: context,
        analysisFuture: analysisFuture,
        isDark: isDark,
      );
    } catch (error) {
      // The controller already isolates expected failures; this final boundary
      // guarantees no future implementation can leak into journal saving.
      debugPrint(
        '[JournalTone] optional feedback skipped: ${error.runtimeType}',
      );
    }
  }

  /// Small "Günlüğü Mühürle" confirmation toast, shown briefly after a
  /// successful save.
  void _showSealedToast(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.read(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isDark ? const Color(0xF01A1233) : const Color(0xF0FFF8EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primary.withValues(alpha: 0.4)),
          ),
          margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
          duration: const Duration(seconds: 2),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Text(
                isTr ? 'Günlük mühürlendi' : 'Journal sealed',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF6ECD2)
                      : const Color(0xFF1A1005),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(astraThemeProvider);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = mode == AstraThemeMode.dark;
    // The app's theme accent, matching the home page: soft lavender on the
    // dark/moon theme, gold on the light/sun theme — flows through the labels,
    // icons, borders, waveform and mic on the glass cards.
    final primary = AstraKit.primary(isDark);

    final localeStr = Localizations.localeOf(context).toString();
    final dateStr =
        DateFormat('d MMMM yyyy, EEEE', localeStr).format(_selectedDate);

    return Scaffold(
      body: _MountainBackground(
        isDark: isDark,
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
                            Row(
                              children: [
                                // Önceki (mühürlü) günlüklere gider.
                                _CircleBtn(
                                  icon: Icons.auto_stories_rounded,
                                  primary: primary,
                                  isDark: isDark,
                                  onTap: () =>
                                      context.push(AppRoutes.sealedJournals),
                                ),
                                const SizedBox(width: 10),
                                _CircleBtn(
                                  icon: Icons.auto_awesome,
                                  primary: primary,
                                  isDark: isDark,
                                  onTap: () {
                                    final next = isDark
                                        ? AstraThemeMode.light
                                        : AstraThemeMode.dark;
                                    ref
                                        .read(astraThemeProvider.notifier)
                                        .setTheme(next);
                                  },
                                ),
                              ],
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
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? const Color(0xFFF6ECD2)
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
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
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
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFFF6ECD2)
                                            : const Color(0xFF1A1005),
                                      ),
                                      cursorColor: primary,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        // Kill the global lavender fill so the
                                        // glass card shows through (no white box).
                                        filled: false,
                                        fillColor: Colors.transparent,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: isTr
                                            ? 'Günün özeti...'
                                            : 'Summary...',
                                        hintStyle: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0x99D9B24A)
                                              : const Color(0x99A07A1E),
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
                                    color: isDark
                                        ? const Color(0xFFF6ECD2)
                                        : const Color(0xFF1A1005),
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: primary,
                                  decoration: InputDecoration(
                                    // Kill the global lavender fill so the
                                    // glass card shows through (no white box).
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.zero,
                                    counterText: '',
                                    hintText: isTr
                                        ? 'Bugün aklından geçenleri yaz...'
                                        : 'Write what is on your mind today...',
                                    hintStyle: GoogleFonts.outfit(
                                      fontSize: 15,
                                      color: isDark
                                          ? const Color(0x99D9B24A)
                                          : const Color(0x99A07A1E),
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
                                      size: 13,
                                      color: primary.withValues(alpha: 0.7)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Optional attached photo preview
                        if (_pickedPhotoPath != null) ...[
                          const SizedBox(height: 12),
                          _PhotoPreviewCard(
                            path: _pickedPhotoPath!,
                            bytes: _pickedPhotoBytes,
                            isDark: isDark,
                            primary: primary,
                            isTr: isTr,
                            onRemove: () => setState(() {
                              _pickedPhotoPath = null;
                              _pickedPhotoBytes = null;
                            }),
                          ),
                        ],

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
                                  Icon(Icons.auto_awesome,
                                      size: 14, color: primary),
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
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isTr
                                    ? 'Konuşarak yazabilirsin; söylediklerin metne dönüşür.'
                                    : 'Speak to write — your words become text.',
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
                                      duration:
                                          const Duration(milliseconds: 300),
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
                                                  primary.withValues(
                                                      alpha: 0.95),
                                                  primary.withValues(
                                                      alpha: 0.6),
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
                    // Add-photo chip — glass background so it reads clearly
                    // against the mountain scene in both themes.
                    _PhotoChip(
                      primary: primary,
                      isDark: isDark,
                      isTr: isTr,
                      hasPhoto: _pickedPhotoPath != null,
                      onTap: _pickPhoto,
                    ),

                    const SizedBox(height: 14),

                    // "Günlüğü Mühürle" gold pill button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _entryController,
                      builder: (ctx, val, _) {
                        final enabled = val.text.trim().isNotEmpty &&
                            !_isSaving &&
                            !_isListeningAndRecording;
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
                            size: 13, color: primary.withValues(alpha: 0.6)),
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
    // Frosted glass: a soft blur of the mountain scene behind each card keeps
    // the writing legible while preserving the premium, airy look. The light
    // (sun) theme uses a warmer, more opaque fill so dark text stays crisp
    // over the bright golden scene.
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x59181026) : const Color(0x9EFBF1DD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: 0.40),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A glass card previewing the photo the user optionally attached to the
/// entry, with a gold-accented header and a remove (×) button.
class _PhotoPreviewCard extends StatelessWidget {
  const _PhotoPreviewCard({
    required this.path,
    this.bytes,
    required this.isDark,
    required this.primary,
    required this.isTr,
    required this.onRemove,
  });

  final String path;
  final Uint8List? bytes;
  final bool isDark;
  final Color primary;
  final bool isTr;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
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
                isTr ? 'Eklenen fotoğraf' : 'Attached photo',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF6ECD2)
                      : const Color(0xFF1A1005),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 18, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: kIsWeb && bytes != null
                  ? Image.memory(bytes!, fit: BoxFit.cover)
                  : Image.file(File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed background for the journal screen: the app's signature mountain
/// scene (moon over the peaks for the dark theme, sun for the light theme),
/// shown vividly and crossfading whenever the user switches themes. A gentle
/// top scrim keeps the app-bar icons readable while the scene stays vivid.
class _MountainBackground extends StatelessWidget {
  const _MountainBackground({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final asset = isDark
        ? 'assets/images/app_theme_dark.jpeg'
        : 'assets/images/app_theme_light.jpeg';
    return ColoredBox(
      color: isDark ? const Color(0xFF0F0B1A) : const Color(0xFFFDF6E9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child: SizedBox.expand(
              key: ValueKey(asset),
              child: Image.asset(
                asset,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Softens the busy scene (rocks, rays, foliage) so it reads as an
          // atmosphere behind the cards rather than competing detail.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [Color(0x55000000), Color(0x00000000)]
                    : const [Color(0x1F000000), Color(0x00000000)],
                stops: const [0.0, 0.30],
              ),
            ),
          ),
          child,
        ],
      ),
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

/// The single "add photo" action above the seal button. Sits on a glass pill
/// (rather than a bare icon+label) so it stays legible against the bright
/// sun scene in the light theme, where a plain gold icon used to wash out.
class _PhotoChip extends StatelessWidget {
  const _PhotoChip({
    required this.primary,
    required this.isDark,
    required this.isTr,
    required this.hasPhoto,
    required this.onTap,
  });

  final Color primary;
  final bool isDark;
  final bool isTr;
  final bool hasPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0x66231845) : const Color(0x88FFF8EE),
            border: Border.all(
              color: (hasPhoto ? Colors.greenAccent : primary)
                  .withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasPhoto
                    ? Icons.check_circle_rounded
                    : Icons.add_a_photo_rounded,
                size: 18,
                color: hasPhoto ? Colors.greenAccent.shade400 : primary,
              ),
              const SizedBox(width: 8),
              Text(
                hasPhoto
                    ? (isTr ? 'Fotoğraf eklendi' : 'Photo added')
                    : (isTr ? 'Fotoğraf ekle' : 'Add photo'),
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF6ECD2)
                      : const Color(0xFF1A1005),
                ),
              ),
            ],
          ),
        ),
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
    // Lavender pill on the dark theme (matching the home page's accent), gold
    // on the light theme.
    final gradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFFC9A7F5), Color(0xFF9B6FE0), Color(0xFF7C4DB8)],
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
                    colors: isDark
                        ? [const Color(0x44C084FC), const Color(0x228B5CF6)]
                        : [const Color(0x44D4AF37), const Color(0x22B8860B)],
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
                child: Icon(
                  Icons.local_florist_rounded,
                  color: isDark ? Colors.white : Colors.black87,
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
                        color: isDark ? Colors.white : const Color(0xFF1A0F00),
                      ),
                    ),
                    Text(
                      isTr
                          ? 'Bu anı sakla ve yolculuğuna devam et.'
                          : 'Preserve this moment and continue.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color:
                            isDark ? Colors.white70 : const Color(0x99331100),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.auto_awesome,
                  color: isDark ? Colors.white : const Color(0xFF1A0F00),
                  size: 18),
              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}
