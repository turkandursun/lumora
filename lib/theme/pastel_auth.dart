import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/theme_choice/presentation/screens/theme_choice_screen.dart';
import 'photo_ken_burns.dart';

/// Soft pastel "cherry-blossom dawn" design system for Lumora's first-touch
/// screens (login, sign up). A bright pastel photo backdrop with an airy
/// frosted-glass card and plum/lavender ink — deliberately light, unlike
/// [LumoraPalette]'s dark night-sky auth theme.
class PastelAuthPalette {
  PastelAuthPalette._();

  // --- Ink (reads on the light frosted card / bright sky) ---
  static const Color plumDeep = Color(0xFF5D4F86); // wordmark, headings
  static const Color plum = Color(0xFF6E5F97); // body
  static const Color plumMuted = Color(0xFF9C8FBE); // hints, captions

  // --- Surfaces ---
  static const Color cardFill = Color(0x94FFFFFF); // ~0.58 white, frosted
  static const Color cardBorder = Color(0xA6FFFFFF); // ~0.65 white
  static const Color fieldFill = Color(0x80FFFFFF); // ~0.5 white
  static const Color fieldBorder = Color(0x8FFFFFFF);

  // --- Accents ---
  static const Color accent = Color(0xFF8E72C6); // links
  static const Color accentPink = Color(0xFFE0A6C8);
  static const List<Color> buttonGradient = [Color(0xFFAB93DE), Color(0xFF8E72C6)];

  static TextStyle wordmark({double fontSize = 46, Color color = plumDeep}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 2,
      color: color,
    );
  }

  static TextStyle heading({double fontSize = 26, Color color = plumDeep}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: color,
    );
  }

  static TextStyle tagline({double fontSize = 13.5, Color color = plum}) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.2,
      color: color,
    );
  }

  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = plum,
    double letterSpacing = 0.1,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle overline({double fontSize = 12, Color color = plumMuted}) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.5,
      color: color,
    );
  }
}

/// Full-bleed pastel photo backdrop with a slow Ken Burns drift and a gentle
/// light veil — bright and airy, so the frosted card and plum text read
/// clearly without darkening the scene.
class PastelAuthBackground extends StatefulWidget {
  const PastelAuthBackground({super.key, this.child, this.bottomOverlay});

  final Widget? child;

  /// Optional widget pinned near the bottom of the screen, above [child]
  /// (e.g. a self-dismissing disclaimer banner).
  final Widget? bottomOverlay;

  static const asset = 'assets/images/signup_background.png';

  @override
  State<PastelAuthBackground> createState() => _PastelAuthBackgroundState();
}

class _PastelAuthBackgroundState extends State<PastelAuthBackground>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(seconds: 28);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Alignment> _alignment;

  /// The chosen theme's scene, loaded async; falls back to the pastel photo.
  String? _themedAsset;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _alignment =
        AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight)
            .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(astraThemeKey);
    if (mounted) {
      setState(() => _themedAsset = theme == 'light'
          ? 'assets/images/astra_sun_bg_g5.png'
          : 'assets/images/astra_dark_plain.png');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        KenBurnsPhoto(
          asset: _themedAsset ?? PastelAuthBackground.asset,
          scale: _scale,
          alignment: _alignment,
          imageAlignment: Alignment.topCenter,
        ),
        // Readability veil over the themed scene so the wordmark, footer and
        // form all stay legible on both the sunset and moon backgrounds.
        Container(color: Colors.white.withValues(alpha: 0.4)),
        if (widget.child != null) widget.child!,
        if (widget.bottomOverlay != null)
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: SafeArea(top: false, child: widget.bottomOverlay!),
          ),
      ],
    );
  }
}

/// Frosted-glass card — a blurred, semi-transparent white sheet the form
/// sits on.
class PastelCard extends StatelessWidget {
  const PastelCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.fromLTRB(22, 28, 22, 26),
          decoration: BoxDecoration(
            color: PastelAuthPalette.cardFill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: PastelAuthPalette.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E5F97).withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Sage/purple pill button with a sparkle flourish.
class PastelButton extends StatefulWidget {
  const PastelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<PastelButton> createState() => _PastelButtonState();
}

class _PastelButtonState extends State<PastelButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (!_enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            gradient: const LinearGradient(
              colors: PastelAuthPalette.buttonGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: PastelAuthPalette.accent.withValues(alpha: 0.4),
                blurRadius: _pressed ? 10 : 18,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: PastelAuthPalette.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Labelled divider ("veya") flanked by soft lavender hairlines.
class PastelLabeledDivider extends StatelessWidget {
  const PastelLabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: PastelAuthPalette.plumMuted.withValues(alpha: 0.5),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label.toUpperCase(), style: PastelAuthPalette.overline()),
        ),
        line,
      ],
    );
  }
}

/// Shared pastel field decoration — translucent white fill, lavender
/// hairline warming to purple on focus, plum icon and hint.
InputDecoration pastelFieldDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1.0]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: PastelAuthPalette.body(fontSize: 15, color: PastelAuthPalette.plumMuted),
    prefixIcon: Icon(icon, color: PastelAuthPalette.accent.withValues(alpha: 0.75), size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: PastelAuthPalette.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(PastelAuthPalette.fieldBorder),
    enabledBorder: border(PastelAuthPalette.fieldBorder),
    focusedBorder: border(PastelAuthPalette.accent, 1.5),
    errorBorder: border(PastelAuthPalette.accentPink),
    focusedErrorBorder: border(PastelAuthPalette.accentPink, 1.5),
    errorStyle: PastelAuthPalette.body(fontSize: 12, color: PastelAuthPalette.accent),
  );
}

/// A small, always-visible "crisis support" link — a quiet, persistent way
/// to reach help, separate from the self-dismissing disclaimer banner.
class PastelCrisisLink extends StatelessWidget {
  const PastelCrisisLink({
    super.key,
    required this.label,
    required this.onTap,
    this.accentColor = PastelAuthPalette.accent,
    this.textStyle,
  });

  final String label;
  final VoidCallback onTap;

  /// Override for callers using a different auth palette (e.g. the gold
  /// ASTRA theme) than this file's default pastel purple.
  final Color accentColor;
  final TextStyle Function({double fontSize, FontWeight fontWeight, Color color})? textStyle;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? PastelAuthPalette.body;
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        icon: Icon(Icons.favorite_border_rounded, size: 16, color: accentColor),
        label: Text(
          label,
          style: style(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
        ),
      ),
    );
  }
}

/// A brief, self-dismissing disclaimer that slides up from the bottom of
/// the auth screens, rests for a few seconds, then fades away — used to
/// gently note that Lumora isn't a substitute for professional care.
class AuthDisclaimerBanner extends StatefulWidget {
  const AuthDisclaimerBanner({
    super.key,
    required this.message,
    this.highlight,
    this.icon = Icons.favorite,
    this.onTap,
    this.accentColor = PastelAuthPalette.accent,
    this.textColor = PastelAuthPalette.plumDeep,
    this.fillColor = PastelAuthPalette.cardFill,
    this.borderColor = PastelAuthPalette.cardBorder,
    this.textStyle,
  });

  /// The full disclaimer text.
  final String message;

  /// Optional substring within [message] to emphasise in the accent colour
  /// (e.g. a phone number).
  final String? highlight;

  final IconData icon;

  /// If provided, the banner becomes tappable (e.g. to open the crisis
  /// support sheet) and shows a subtle chevron affordance.
  final VoidCallback? onTap;

  /// Overrides for callers using a different auth palette (e.g. the gold
  /// ASTRA theme) than this file's default pastel purple.
  final Color accentColor;
  final Color textColor;
  final Color fillColor;
  final Color borderColor;
  final TextStyle Function({double fontSize, Color color})? textStyle;

  @override
  State<AuthDisclaimerBanner> createState() => _AuthDisclaimerBannerState();
}

class _AuthDisclaimerBannerState extends State<AuthDisclaimerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  Timer? _dismissTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(_fade);
    _controller.forward();
    // ~450ms in + ~3.3s hold + ~450ms out ≈ 3–4s on screen.
    _dismissTimer = Timer(const Duration(milliseconds: 3300), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<InlineSpan> _spans() {
    final highlight = widget.highlight;
    if (highlight == null || highlight.isEmpty) {
      return [TextSpan(text: widget.message)];
    }
    final index = widget.message.indexOf(highlight);
    if (index < 0) return [TextSpan(text: widget.message)];
    return [
      TextSpan(text: widget.message.substring(0, index)),
      TextSpan(
        text: highlight,
        style: TextStyle(
          color: widget.accentColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      TextSpan(text: widget.message.substring(index + highlight.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final bodyStyle = widget.textStyle ??
        ({double fontSize = 12.5, Color color = PastelAuthPalette.plumDeep}) =>
            PastelAuthPalette.body(fontSize: fontSize, color: color);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.fillColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: widget.borderColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 17, color: widget.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: bodyStyle(fontSize: 12.5, color: widget.textColor),
                        children: _spans(),
                      ),
                    ),
                  ),
                  if (widget.onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: widget.accentColor.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final animated = FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: card),
    );

    // Only intercept taps when there's an action; otherwise let touches
    // pass through to whatever is behind the banner.
    return widget.onTap == null ? IgnorePointer(child: animated) : animated;
  }
}
