import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'astra_design_tokens.dart';
import 'sakura_home_palette.dart';

/// A tactile, premium-feeling primary button: a soft gradient fill, a gentle
/// glow shadow, and a subtle spring "press" that scales the button down while
/// held. Used for the main call-to-action on a screen.
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final List<Color>? gradient;
  final bool loading;

  /// Whether the button stretches to fill its parent's width.
  final bool expand;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AstraThemeTokens.of(context);
    final gradient = widget.gradient ??
        (tokens.isDark
            ? [tokens.palette.buttonPrimary, tokens.palette.secondary]
            : SakuraHomePalette.ctaGradient);
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.45),
                  blurRadius: _pressed ? 10 : 20,
                  offset: Offset(0, _pressed ? 3 : 9),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation(tokens.textOnAccent),
                    ),
                  )
                else ...[
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: tokens.textOnAccent, size: 19),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTheme.bodyFont(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: tokens.textOnAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
