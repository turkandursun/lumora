import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/app_lock_providers.dart';
import '../widgets/pin_keypad.dart';

/// PIN verification screen — used both inline by [SectionLockGate] (as the
/// "show this instead of the real content" widget, [dismissible] false,
/// [onSuccess] swaps the gate's content) and pushed as a route before an
/// imperative action like opening Luma's chat (pops `true` on success).
///
/// Shares [AppLockService]'s attempt-cooldown: after
/// [AppLockService.maxAttempts] wrong guesses in a row, entry is disabled
/// for [AppLockService.lockoutDuration] with a live countdown, since a
/// wrong guess here is a wrong guess against the same underlying PIN
/// everywhere else.
class PinVerifyScreen extends ConsumerStatefulWidget {
  const PinVerifyScreen({
    super.key,
    required this.title,
    this.dismissible = true,
    this.onSuccess,
  });

  final String title;
  final bool dismissible;

  /// Called instead of popping the route when verification succeeds — used
  /// by section gates, which render this screen inline rather than pushing
  /// it.
  final VoidCallback? onSuccess;

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  String _current = '';
  bool _shake = false;
  int? _attemptsRemaining;
  Duration? _lockoutRemaining;
  Timer? _lockoutTicker;

  bool get _locked => _lockoutRemaining != null;

  bool get _canSubmit =>
      !_locked && _current.length >= minPinLength && _current.length <= maxPinLength;

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_locked || _current.length >= maxPinLength) return;
    setState(() => _current += digit);
  }

  void _onBackspace() {
    if (_locked || _current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _onSuccess() {
    HapticFeedback.selectionClick();
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final result = await ref.read(appLockServiceProvider).attemptUnlock(_current);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _attemptsRemaining = null;
        _lockoutRemaining = null;
      });
      _onSuccess();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _shake = true;
      _current = '';
      _attemptsRemaining = result.attemptsRemaining;
      _lockoutRemaining = result.lockoutRemaining;
    });
    if (result.isLockedOut) _startLockoutTicker();

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _shake = false);
  }

  void _startLockoutTicker() {
    _lockoutTicker?.cancel();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = ref.read(appLockServiceProvider).lockoutRemaining;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remaining == null) {
        timer.cancel();
        setState(() => _lockoutRemaining = null);
      } else {
        setState(() => _lockoutRemaining = remaining);
      }
    });
  }

  String? _statusMessage(AppLocalizations l10n) {
    final lockout = _lockoutRemaining;
    if (lockout != null) {
      final seconds = lockout.inSeconds < 1 ? 1 : lockout.inSeconds;
      return l10n.appLockLockoutMessage(seconds);
    }
    final remaining = _attemptsRemaining;
    if (remaining != null) {
      return l10n.appLockAttemptsRemainingMessage(remaining);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = _statusMessage(l10n);

    return PopScope(
      canPop: widget.dismissible,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: LumoraPalette.backgroundGradient,
            ),
          ),
          child: SafeArea(
            child: ResponsiveContent(
              child: Column(
                children: [
                  if (widget.dismissible)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(false),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                  const Spacer(),
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 40,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: LumoraPalette.bodyStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: LumoraPalette.bodyStyle(
                          fontSize: 13,
                          color: LumoraPalette.accentPink,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PinDots(filledCount: _current.length, shake: _shake),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: PinKeypad(
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                      trailingAction: PinConfirmButton(enabled: _canSubmit, onTap: _submit),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
