import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/app_lock_providers.dart';
import '../widgets/pin_keypad.dart';

/// PIN entry stays night-themed regardless of the app's light/dark choice —
/// same reasoning as the dream journal.
const _isDark = true;

/// Two-step "create PIN, then confirm it" flow for a 4-6 digit PIN. Pops
/// `true` once a new PIN has been hashed and persisted via
/// [AppLockService.setPin]; pops `false`/null if the user backs out.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _firstEntry = '';
  String _current = '';
  bool _isConfirmStep = false;
  bool _shake = false;
  bool _mismatch = false;

  bool get _canSubmit => _current.length >= minPinLength && _current.length <= maxPinLength;

  void _onDigit(String digit) {
    if (_current.length >= maxPinLength) return;
    setState(() => _current += digit);
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;

    if (!_isConfirmStep) {
      setState(() {
        _firstEntry = _current;
        _current = '';
        _isConfirmStep = true;
        _mismatch = false;
      });
      return;
    }

    if (_current == _firstEntry) {
      await ref.read(appLockServiceProvider).setPin(_current);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _shake = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _shake = false;
      _current = '';
      _isConfirmStep = false;
      _firstEntry = '';
      _mismatch = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = AstraKit.primary(_isDark);
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AstraMountainBackground(
          isDark: _isDark,
          child: SafeArea(
            child: ResponsiveContent(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: _isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(false),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.lock_outline_rounded, color: primary, size: 40),
                  const SizedBox(height: 20),
                  Text(
                    _isConfirmStep ? l10n.appLockConfirmPinTitle : l10n.appLockCreatePinTitle,
                    style: AstraKit.heading2(_isDark, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mismatch ? l10n.appLockPinMismatchMessage : l10n.appLockPinLengthHint,
                    style: _mismatch
                        ? const TextStyle(fontSize: 13, color: Color(0xFFE07A7A))
                        : AstraKit.mutedText(_isDark, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  PinDots(filledCount: _current.length, shake: _shake),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: PinKeypad(
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                      trailingAction: PinConfirmButton(enabled: _canSubmit, onTap: _onSubmit),
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
