import 'package:flutter/material.dart';

import '../../../../core/services/app_lock_service.dart';
import '../../../../theme/astra_screen_kit.dart';

/// PIN entry stays night-themed regardless of the app's light/dark choice —
/// same reasoning as the dream journal.
final _primary = AstraKit.primary(true);

const int minPinLength = AppLockService.minPinLength;
const int maxPinLength = AppLockService.maxPinLength;

/// Row of up to [maxPinLength] dots, filled left-to-right as digits are
/// entered. Shakes briefly (driven by [shake]) to signal a wrong/mismatched
/// PIN. The PIN itself is variable-length (4-6 digits), so trailing slots
/// simply stay empty until typed.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filledCount, this.shake = false});

  final int filledCount;
  final bool shake;

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxPinLength, (index) {
        final filled = index < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _primary : Colors.transparent,
            border: Border.all(
              color: filled ? _primary : Colors.white.withValues(alpha: 0.35),
              width: 1.6,
            ),
          ),
        );
      }),
    );

    if (!shake) return dots;
    return TweenAnimationBuilder<double>(
      key: UniqueKey(),
      tween: Tween(begin: -1, end: 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(value * 12, 0), child: child);
      },
      child: dots,
    );
  }
}

/// 0-9 + backspace numeric keypad used by PIN setup and PIN verify. The
/// bottom-left slot holds an optional trailing action (a confirm/checkmark
/// button, since PINs are variable-length and have no fixed digit count to
/// auto-submit at).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.trailingAction,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  final Widget? trailingAction;

  static const _labels = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '<'];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: _labels.map((label) {
        if (label.isEmpty) {
          return trailingAction ?? const SizedBox.shrink();
        }
        if (label == '<') {
          return _KeypadButton(
            onTap: onBackspace,
            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 22),
          );
        }
        return _KeypadButton(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
          ),
          onTap: () => onDigit(label),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}

/// Checkmark button used as [PinKeypad.trailingAction] to submit a
/// variable-length PIN — dims and disables its tap when [enabled] is false
/// (too few digits, or a cooldown in effect).
class PinConfirmButton extends StatelessWidget {
  const PinConfirmButton({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: enabled ? onTap : null,
        child: Center(
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.white.withValues(alpha: enabled ? 0.95 : 0.25),
            size: 28,
          ),
        ),
      ),
    );
  }
}
