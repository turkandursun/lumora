import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/crisis_detection_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../providers/journal_entries_provider.dart';
import '../providers/journal_streak_provider.dart';
import '../../../../theme/app_background.dart';
import '../widgets/voice_entry_player.dart';

/// Dedicated Journal Writing screen — previously an inline writing area on
/// Home; moved to its own route so it can be individually PIN-gated (see
/// `AppRoutes.journalEntry`'s `SectionLockGate` wrapping) without locking
/// the rest of Home behind it. Visually stays in Home's pastel/photo world
/// ([HomeMoodBackground]) since the content itself didn't change, only
/// where it lives.
class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _entryController = TextEditingController();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTicker;
  String? _pendingAudioPath;

  @override
  void dispose() {
    _entryController.dispose();
    _recordingTicker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final l10n = AppLocalizations.of(context);
    bool hasPermission;
    try {
      hasPermission = await _recorder.hasPermission();
    } catch (_) {
      hasPermission = false;
    }
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.voiceNotePermissionDenied)),
      );
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final voiceNotesDir = Directory(p.join(documentsDir.path, 'voice_notes'));
      if (!await voiceNotesDir.exists()) {
        await voiceNotesDir.create(recursive: true);
      }

      // Pick an encoder the current platform actually supports. Web, for
      // example, can't encode AAC — it needs opus/webm — so falling back
      // here keeps recording working across platforms instead of failing
      // silently.
      const candidates = [
        AudioEncoder.aacLc,
        AudioEncoder.opus,
        AudioEncoder.wav,
      ];
      var encoder = AudioEncoder.aacLc;
      for (final candidate in candidates) {
        if (await _recorder.isEncoderSupported(candidate)) {
          encoder = candidate;
          break;
        }
      }
      final ext = switch (encoder) {
        AudioEncoder.opus => 'ogg',
        AudioEncoder.wav => 'wav',
        _ => 'm4a',
      };

      final path = p.join(
        voiceNotesDir.path,
        'entry_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await _recorder.start(RecordConfig(encoder: encoder), path: path);
    } catch (e) {
      debugPrint('[VoiceNote] recording failed to start: $e');
      if (!mounted) return;
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isTr
              ? 'Ses kaydı başlatılamadı: $e'
              : "Couldn't start recording: $e"),
        ),
      );
      return;
    }

    final startedAt = DateTime.now();
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _recordingElapsed = DateTime.now().difference(startedAt));
    });

    setState(() {
      _isRecording = true;
      _recordingElapsed = Duration.zero;
      _pendingAudioPath = null;
    });
  }

  Future<void> _stopRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _pendingAudioPath = path;
    });
  }

  Future<void> _removePendingAudio() async {
    final path = _pendingAudioPath;
    setState(() => _pendingAudioPath = null);
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {
      // Best-effort cleanup of the discarded recording; nothing to recover.
    }
  }

  Future<void> _saveEntry() async {
    final content = _entryController.text.trim();
    if (content.isEmpty) return;

    // Local, offline keyword check — shown immediately, before the (fast
    // but still async) save completes, so it never waits on anything.
    if (CrisisDetectionService.containsCrisisLanguage(content)) {
      CrisisSupportSheet.show(context);
    }

    final audioPath = _pendingAudioPath;
    await ref.read(journalEntriesRepositoryProvider).save(content, audioPath: audioPath);
    await ref.read(journalStreakProvider.notifier).recordEntrySaved();
    if (!mounted) return;
    _entryController.clear();
    setState(() => _pendingAudioPath = null);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: SakuraHomePalette.cream,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeFeatureJournalTitle,
                    style: AppTheme.displayFont(fontSize: 22, color: SakuraHomePalette.textDeep),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.homeWritingSectionTitle,
                    style: AppTheme.displayFont(fontSize: 16, color: SakuraHomePalette.textDeep),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 260,
                    child: _WritingArea(
                      controller: _entryController,
                      onSave: _saveEntry,
                      isRecording: _isRecording,
                      recordingElapsed: _recordingElapsed,
                      pendingAudioPath: _pendingAudioPath,
                      onStartRecording: _startRecording,
                      onStopRecording: _stopRecording,
                      onRemovePendingAudio: _removePendingAudio,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.homeRecentEntriesTitle,
                    style: AppTheme.displayFont(fontSize: 16, color: SakuraHomePalette.textDeep),
                  ),
                  const SizedBox(height: 10),
                  const _RecentEntriesList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws faint ruled lines and a dusty-pink left margin behind the writing
/// area, giving it the feel of a paper notebook page.
class _NotebookLinesPainter extends CustomPainter {
  const _NotebookLinesPainter();

  static const double _lineHeight = 30;
  static const double _topPad = 2;
  static const double _marginX = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = const Color(0xFFC9B79A).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var y = _topPad + _lineHeight; y < size.height; y += _lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
    final margin = Paint()
      ..color = const Color(0xFFE39BAE).withValues(alpha: 0.6)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(_marginX, 0), Offset(_marginX, size.height), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WritingArea extends StatelessWidget {
  const _WritingArea({
    required this.controller,
    required this.onSave,
    required this.isRecording,
    required this.recordingElapsed,
    required this.pendingAudioPath,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onRemovePendingAudio,
  });

  final TextEditingController controller;
  final VoidCallback onSave;
  final bool isRecording;
  final Duration recordingElapsed;
  final String? pendingAudioPath;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onRemovePendingAudio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF5E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7D9BE)),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _NotebookLinesPainter()),
                ),
                TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: GoogleFonts.kalam(
                    fontSize: 16,
                    color: SakuraHomePalette.textDeep,
                    height: 30 / 16,
                  ),
                  cursorColor: SakuraHomePalette.blossomPink,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.only(left: 30, top: 2),
                    hintText: l10n.homeWritingPlaceholder,
                    hintStyle: GoogleFonts.kalam(
                      fontSize: 16,
                      color: SakuraHomePalette.textMuted,
                      height: 30 / 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _VoiceAttachmentRow(
            isRecording: isRecording,
            recordingElapsed: recordingElapsed,
            pendingAudioPath: pendingAudioPath,
            onStartRecording: onStartRecording,
            onStopRecording: onStopRecording,
            onRemovePendingAudio: onRemovePendingAudio,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                final enabled = hasText && !isRecording;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: enabled ? 1 : 0.4,
                  child: _SaveEntryButton(
                    label: l10n.homeSaveEntryButton,
                    enabled: enabled,
                    onTap: onSave,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Sits between the text field and the Save button: a mic button when
/// idle, a pulsing "Recording… 0:07" row with a stop button while
/// recording, or a small "Voice note attached" chip once one's been
/// captured and is waiting to be saved with the entry.
class _VoiceAttachmentRow extends StatelessWidget {
  const _VoiceAttachmentRow({
    required this.isRecording,
    required this.recordingElapsed,
    required this.pendingAudioPath,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onRemovePendingAudio,
  });

  final bool isRecording;
  final Duration recordingElapsed;
  final String? pendingAudioPath;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onRemovePendingAudio;

  String _formatElapsed(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isRecording) {
      return Row(
        children: [
          const _RecordingPulseDot(),
          const SizedBox(width: 8),
          Text(
            '${l10n.voiceNoteRecordingLabel} ${_formatElapsed(recordingElapsed)}',
            style: AppTheme.bodyFont(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const Spacer(),
          _RoundIconButton(
            icon: Icons.stop_rounded,
            tooltip: l10n.voiceNoteStopRecordingTooltip,
            onTap: onStopRecording,
            filled: true,
          ),
        ],
      );
    }

    if (pendingAudioPath != null) {
      return Row(
        children: [
          const Icon(Icons.graphic_eq_rounded, size: 16, color: SakuraHomePalette.branchMauve),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.voiceNoteAttachedLabel,
              style: AppTheme.bodyFont(fontSize: 12, color: SakuraHomePalette.textMuted),
            ),
          ),
          _RoundIconButton(
            icon: Icons.close_rounded,
            tooltip: l10n.voiceNoteRemoveTooltip,
            onTap: onRemovePendingAudio,
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: _RoundIconButton(
        icon: Icons.mic_none_rounded,
        tooltip: l10n.voiceNoteRecordTooltip,
        onTap: onStartRecording,
      ),
    );
  }
}

/// Small red dot that gently pulses in opacity while a voice note is being
/// recorded — enough motion to read as "live" without being distracting.
class _RecordingPulseDot extends StatefulWidget {
  const _RecordingPulseDot();

  @override
  State<_RecordingPulseDot> createState() => _RecordingPulseDotState();
}

class _RecordingPulseDotState extends State<_RecordingPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: const DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
        child: SizedBox(width: 8, height: 8),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? SakuraHomePalette.blossomPink : SakuraHomePalette.lavender,
            ),
            child: Icon(
              icon,
              size: 16,
              color: filled ? Colors.white : SakuraHomePalette.branchMauve,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveEntryButton extends StatelessWidget {
  const _SaveEntryButton({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumButton(
      label: label,
      icon: Icons.auto_awesome_rounded,
      expand: false,
      onPressed: enabled ? onTap : null,
    );
  }
}

/// The list of previously saved journal entries, right under the writing
/// area — without this, saved entries were persisted but never surfaced
/// anywhere in the app.
class _RecentEntriesList extends ConsumerWidget {
  const _RecentEntriesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(recentJournalEntriesProvider);

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) {
          return Text(
            l10n.homeRecentEntriesEmpty,
            style: AppTheme.bodyFont(fontSize: 13, color: SakuraHomePalette.textMuted),
          );
        }
        return Column(
          children: [
            for (final entry in entries) _RecentEntryCard(entry: entry),
          ],
        );
      },
    );
  }
}

/// A single saved entry. Tapping it expands/collapses the full text (the
/// entry's "detail view" — this app has no separate detail screen, so
/// expanding in place fills that role); an attached voice note's playback
/// control is shown either way via the shared [VoiceEntryPlayer] widget.
class _RecentEntryCard extends StatefulWidget {
  const _RecentEntryCard({required this.entry});

  final JournalEntryRow entry;

  @override
  State<_RecentEntryCard> createState() => _RecentEntryCardState();
}

class _RecentEntryCardState extends State<_RecentEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final entry = widget.entry;
    final audioPath = entry.audioPath;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: SakuraHomePalette.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SakuraHomePalette.branchMauve.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMd(locale).add_jm().format(entry.createdAt),
                style: AppTheme.bodyFont(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SakuraHomePalette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.content,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: AppTheme.bodyFont(fontSize: 14, color: SakuraHomePalette.textDeep),
              ),
              if (audioPath != null) ...[
                const SizedBox(height: 10),
                VoiceEntryPlayer(audioPath: audioPath),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
