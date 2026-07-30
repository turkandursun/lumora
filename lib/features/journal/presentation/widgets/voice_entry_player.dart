import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/sakura_home_palette.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Test-only seam (mirrors `debugRainPlayerFactory` in `luma_companion.dart`):
/// when set, [_VoiceEntryPlayerState] uses this instead of constructing a
/// real [AudioPlayer], so widget tests can inject a fake player and assert
/// on play/pause/seek call patterns without touching platform audio
/// channels. Left `null` (real player) in production.
@visibleForTesting
AudioPlayer Function()? debugVoiceEntryPlayerFactory;

/// Makes sure at most one [VoiceEntryPlayer] is audibly playing at a time
/// across the whole app. Starting playback on one instance silently pauses
/// whichever other instance was previously playing — mirrors a single
/// physical speaker, and keeps the recent-entries list and an expanded
/// entry from ever talking over each other.
class _ActiveVoiceNoteRegistry {
  _ActiveVoiceNoteRegistry._();
  static final instance = _ActiveVoiceNoteRegistry._();

  Object? _activeToken;
  VoidCallback? _pauseActive;

  void notifyPlaying(Object token, VoidCallback pause) {
    if (_activeToken != token) {
      _pauseActive?.call();
    }
    _activeToken = token;
    _pauseActive = pause;
  }

  void notifyStopped(Object token) {
    if (_activeToken == token) {
      _activeToken = null;
      _pauseActive = null;
    }
  }
}

enum _PlayerStatus { idle, loading, playing, paused, missing }

/// Reusable playback control for a journal entry's attached voice note:
/// play/pause button, a scrub-able progress bar, and a duration label.
/// Used both in the recent-entries list and an entry's expanded view — same
/// widget, just given a different [audioPath] — so both surfaces share the
/// same single-instance play/pause behavior automatically.
///
/// Handles a missing/corrupted audio file gracefully: shows
/// [AppLocalizations.voiceNoteFileMissing] instead of crashing.
class VoiceEntryPlayer extends StatefulWidget {
  const VoiceEntryPlayer({super.key, required this.audioPath});

  final String audioPath;

  @override
  State<VoiceEntryPlayer> createState() => _VoiceEntryPlayerState();
}

class _VoiceEntryPlayerState extends State<VoiceEntryPlayer> {
  late final AudioPlayer _player;
  final Object _token = Object();

  _PlayerStatus _status = _PlayerStatus.idle;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _player = (debugVoiceEntryPlayerFactory ?? AudioPlayer.new)();
    _durationSub = _player.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });
    _positionSub = _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _status = _PlayerStatus.paused;
        _position = Duration.zero;
      });
      _ActiveVoiceNoteRegistry.instance.notifyStopped(_token);
    });
  }

  @override
  void didUpdateWidget(covariant VoiceEntryPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _player.stop();
      _ActiveVoiceNoteRegistry.instance.notifyStopped(_token);
      setState(() {
        _status = _PlayerStatus.idle;
        _duration = Duration.zero;
        _position = Duration.zero;
      });
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _ActiveVoiceNoteRegistry.instance.notifyStopped(_token);
    _player.dispose();
    super.dispose();
  }

  /// Passed to the registry so a *different* [VoiceEntryPlayer] taking over
  /// playback can silently pause this one without touching its error state.
  void _pauseSilently() {
    _player.pause();
    if (!mounted) return;
    setState(() => _status = _PlayerStatus.paused);
  }

  Future<void> _togglePlayback() async {
    if (_status == _PlayerStatus.playing) {
      await _player.pause();
      if (!mounted) return;
      setState(() => _status = _PlayerStatus.paused);
      return;
    }

    setState(() => _status = _PlayerStatus.loading);
    _ActiveVoiceNoteRegistry.instance.notifyPlaying(_token, _pauseSilently);
   try {
      final source = kIsWeb
          ? UrlSource(widget.audioPath)
          : DeviceFileSource(widget.audioPath);
      await _player.play(source);
      if (!mounted) return;
      setState(() => _status = _PlayerStatus.playing);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _PlayerStatus.missing);
      _ActiveVoiceNoteRegistry.instance.notifyStopped(_token);
    }
  }

  Future<void> _seekToFraction(double fraction) async {
    if (_status == _PlayerStatus.missing || _duration == Duration.zero) return;
    final target = _duration * fraction.clamp(0.0, 1.0);
    await _player.seek(target);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_status == _PlayerStatus.missing) {
      return _VoiceNoteMessage(text: l10n.voiceNoteFileMissing);
    }

    final isPlaying = _status == _PlayerStatus.playing;
    final isLoading = _status == _PlayerStatus.loading;
    final displayDuration = _duration > Duration.zero ? _duration : _position;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: SakuraHomePalette.lavender.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _PlayPauseButton(isPlaying: isPlaying, isLoading: isLoading, onTap: _togglePlayback),
          const SizedBox(width: 10),
          Expanded(
            child: _Scrubber(progress: progress, onSeekToFraction: _seekToFraction),
          ),
          const SizedBox(width: 10),
          Text(
            _formatDuration(displayDuration),
            style: AppTheme.bodyFont(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.isLoading, required this.onTap});

  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: isPlaying ? l10n.voiceNotePauseTooltip : l10n.voiceNotePlayTooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onTap,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: SakuraHomePalette.ctaGradient),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Thin scrubber track: fill animates smoothly as playback position updates
/// (a simple, soft stand-in for a full waveform, consistent with the app's
/// gentle animated aesthetic elsewhere), and tapping/dragging anywhere on
/// it seeks to that fraction of the clip.
class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.progress, required this.onSeekToFraction});

  final double progress;
  final ValueChanged<double> onSeekToFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void handle(Offset localPosition) {
          if (constraints.maxWidth <= 0) return;
          onSeekToFraction(localPosition.dx / constraints.maxWidth);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => handle(details.localPosition),
          onHorizontalDragUpdate: (details) => handle(details.localPosition),
          child: SizedBox(
            height: 20,
            child: Center(
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 4,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: SakuraHomePalette.ctaGradient),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shown instead of the playback control when the attached audio file is
/// missing or fails to load — keeps the entry rendering instead of crashing.
class _VoiceNoteMessage extends StatelessWidget {
  const _VoiceNoteMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: SakuraHomePalette.lavender.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: SakuraHomePalette.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTheme.bodyFont(fontSize: 12, color: SakuraHomePalette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
