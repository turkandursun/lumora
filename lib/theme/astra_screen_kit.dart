import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared building blocks for the app's premium "Astra" look — the gold
/// glass-card aesthetic introduced on the journal writing screen (mountain
/// scene, frosted glass cards, gold accents, Playfair Display headings over
/// Outfit body text). Screens that adopt this kit get the exact same colors
/// and shapes as the journal screens, so moving between them feels like one
/// consistent app rather than several bolted together.
class AstraKit {
  AstraKit._();

  /// App-wide accent: a soft violet on the dark/moon theme, gold on the
  /// light/sun theme — matches the dream journal's existing purple-on-night
  /// look so every screen (besides the ASTRA-branded auth flow, which is
  /// always gold — see [gold]) shares one consistent, theme-aware accent.
  static Color primary(bool isDark) =>
      isDark ? const Color(0xFFC084FC) : const Color(0xFF95610F);

  /// Always-gold accent, regardless of theme — reserved for the ASTRA
  /// login/signup screens so their branded moon-and-gold look never
  /// switches to the violet accent used everywhere else.
  static Color gold(bool isDark) =>
      isDark ? const Color(0xFFE3C264) : const Color(0xFFD4AF37);

  // Reading colours: warm light on the dark/moon glass, deep brown on the
  // light/sun glass (never yellow/gold text — it washes out on the bright sun
  // scene). Both give strong contrast on their translucent frosted cards.
  static Color ink(bool isDark) =>
      isDark ? const Color(0xFFF6ECD2) : const Color(0xFF2A1B06);

  static Color heading(bool isDark) =>
      isDark ? const Color(0xFFF4EEFF) : const Color(0xFF231402);

  static Color muted(bool isDark) =>
      isDark ? const Color(0xCCD8C8FF) : const Color(0xDE4A3208);

  static Color faint(bool isDark) =>
      isDark ? const Color(0x99C0A8FF) : const Color(0xAA5A420C);

  /// Big brand wordmark ("ASTRA") — gold on the dark/moon scene; a deep bronze
  /// on the bright sun scene, where literal gold would wash out.
  static TextStyle wordmark(bool isDark, {double fontSize = 44}) => GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: isDark ? gold(isDark) : const Color(0xFF5C3E0E),
      );

  static TextStyle heading1(bool isDark, {double fontSize = 22, FontWeight fontWeight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: fontWeight, color: heading(isDark));

  static TextStyle heading2(bool isDark, {double fontSize = 16, FontWeight fontWeight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: fontWeight, color: heading(isDark));

  static TextStyle label(bool isDark, {double fontSize = 12, Color? color}) => GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color ?? (isDark ? primary(isDark) : const Color(0xFF5C3E0E)),
        letterSpacing: 0.3,
      );

  static TextStyle body(bool isDark,
          {double fontSize = 14, FontWeight fontWeight = FontWeight.w600, double? height, Color? color}) =>
      GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: color ?? ink(isDark), height: height);

  static TextStyle mutedText(bool isDark, {double fontSize = 12, FontWeight fontWeight = FontWeight.w500}) =>
      GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: muted(isDark));
}

/// Full-bleed mountain scene background — moon over the peaks in the dark
/// theme, sun in the light theme — with a gentle top scrim so app-bar icons
/// stay legible. Identical to the journal screens' background so switching
/// screens never shows a background "jump".
class AstraMountainBackground extends StatelessWidget {
  const AstraMountainBackground({
    super.key,
    required this.isDark,
    required this.child,
    this.useEntryScene = false,
  });

  final bool isDark;
  final Widget child;

  /// Keeps the original ASTRA moon/sun artwork in the pre-home journey.
  /// All authenticated in-app screens use the calmer, more readable theme
  /// artwork supplied for the main application experience.
  final bool useEntryScene;

  @override
  Widget build(BuildContext context) {
    final asset = useEntryScene
        ? (isDark
            ? 'assets/images/astra_dark_plain.png'
            : 'assets/images/astra_sun_bg_g5.png')
        : (isDark
            ? 'assets/images/app_theme_dark.jpeg'
            : 'assets/images/app_theme_light.jpeg');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: ColoredBox(
        color: isDark ? const Color(0xFF0F0B1A) : const Color(0xFFFDF6E9),
        child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            // Keep both the incoming and outgoing frames constrained to the
            // full viewport while the theme crossfade is in progress.
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
          // A soft mist over the scene — keeps it from competing with the UI
          // without hiding it, so the sun scene stays bright and airy.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: const SizedBox.expand(),
          ),
          // Only a gentle top scrim so status-bar text/greeting stays legible;
          // the sun scene otherwise keeps its brightness.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [Color(0x55000000), Color(0x00000000)]
                    : const [Color(0x2E000000), Color(0x00000000)],
                stops: const [0.0, 0.30],
              ),
            ),
          ),
          child,
        ],
      ),
      ),
    );
  }
}

/// Frosted glass card — a soft blur of the mountain scene behind the card
/// keeps content legible while the scene stays vivid. Same fill/border/blur
/// values as the journal writing and sealed-journals screens.
class AstraGlassCard extends StatelessWidget {
  const AstraGlassCard({
    super.key,
    required this.isDark,
    this.primaryColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    required this.child,
  });

  final bool isDark;
  final Color? primaryColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AstraKit.primary(isDark);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Translucent frosted glass in both themes: a dark tint on the moon
            // scene, a light cream tint on the bright sun scene — the blurred
            // scene shows softly through either.
            color: isDark ? const Color(0x59181026) : const Color(0x8FFBF1DC),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.40 : 0.55),
                width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Circular glass icon button — matches the app-bar buttons on the journal
/// screens (back arrow, theme toggle, archive shortcut).
class AstraCircleIconButton extends StatelessWidget {
  const AstraCircleIconButton({
    super.key,
    required this.icon,
    required this.isDark,
    this.primaryColor,
    required this.onTap,
    this.size = 38,
  });

  final IconData icon;
  final bool isDark;
  final Color? primaryColor;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AstraKit.primary(isDark);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0x44231845) : const Color(0xF2FCF4E2),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: size * 0.47, color: primary),
      ),
    );
  }
}

/// Gold gradient pill button — same treatment as the journal screen's
/// "Günlüğü Mühürle" seal button, reused app-wide as the primary action
/// button so every screen's main CTA matches.
class AstraGoldButton extends StatelessWidget {
  const AstraGoldButton({
    super.key,
    required this.isDark,
    required this.label,
    this.icon,
    this.enabled = true,
    this.isLoading = false,
    required this.onTap,
    this.height = 52,
    this.expand = true,
    this.forceGold = false,
  });

  final bool isDark;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;
  final double height;
  final bool expand;

  /// Keeps the button gold even in the dark theme — set on the ASTRA
  /// login/signup screens, whose branding is always gold. Every other
  /// screen leaves this false and gets the theme's normal accent (gold in
  /// light mode, violet in dark mode, matching [AstraKit.primary]).
  final bool forceGold;

  @override
  Widget build(BuildContext context) {
    // Light theme (and any screen that forces it) keeps the rich 3-stop
    // gold pill; the dark theme's default is a violet-to-pink pill matching
    // the rest of the app's night accent instead.
    final useGold = forceGold || !isDark;
    final gradient = useGold
        ? (isDark
            ? const LinearGradient(
                colors: [Color(0xFFF0D68A), Color(0xFFD4A93F), Color(0xFF8A6A10)],
                stops: [0.0, 0.55, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFEBA3), Color(0xFFEBB818), Color(0xFFAA7A0A)],
                stops: [0.0, 0.55, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ))
        : const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFF9A8D4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );
    final primary = useGold ? AstraKit.gold(isDark) : AstraKit.primary(isDark);
    final contentColor = useGold ? const Color(0xFF1A0F00) : Colors.white;
    final active = enabled && !isLoading;
    final radius = height / 2;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: active ? onTap : null,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: gradient,
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
            boxShadow: enabled
                ? [
                    // Soft ambient glow.
                    BoxShadow(
                      color: primary.withValues(alpha: 0.45),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                    // Tight contact shadow for physical lift off the page.
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.22),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // Glossy sheen across the top half — the "3D pill" highlight.
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.55,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, color: contentColor, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: contentColor,
                                  ),
                                ),
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

/// Gold-outlined input field with a small sparkle-accented label above it —
/// the app-wide text field style, echoing the journal screen's Date/Title
/// fields and the ASTRA sign-in box.
class AstraTextField extends StatelessWidget {
  const AstraTextField({
    super.key,
    required this.isDark,
    required this.label,
    this.primaryColor,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
  });

  final bool isDark;
  final String label;
  final Color? primaryColor;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AstraKit.primary(isDark);
    // Translucent glass field in both themes: dark tint on the moon scene, a
    // light cream tint on the bright sun scene.
    final fill = isDark ? const Color(0x33231845) : const Color(0x73FBF1DC);

    OutlineInputBorder border(Color color, [double width = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: primary),
            const SizedBox(width: 5),
            Text(label, style: AstraKit.label(isDark)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          maxLines: maxLines,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: AstraKit.body(isDark, fontSize: 14.5),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AstraKit.mutedText(isDark, fontSize: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: primary.withValues(alpha: 0.85), size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: border(primary.withValues(alpha: 0.4)),
            enabledBorder: border(primary.withValues(alpha: 0.4)),
            focusedBorder: border(primary, 1.6),
            errorBorder: border(const Color(0xFFE07A7A)),
            focusedErrorBorder: border(const Color(0xFFE07A7A), 1.6),
            errorStyle: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFE07A7A)),
          ),
        ),
      ],
    );
  }
}

/// A thin gold hairline flanking a short label — used to separate sections
/// (e.g. "VEYA" between the sign-in form and the Google button).
class AstraLabeledDivider extends StatelessWidget {
  const AstraLabeledDivider({super.key, required this.isDark, required this.label, this.primaryColor});

  final bool isDark;
  final String label;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AstraKit.primary(isDark);
    final line = Expanded(
      child: Container(height: 1, color: primary.withValues(alpha: 0.35)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AstraKit.muted(isDark),
            ),
          ),
        ),
        line,
      ],
    );
  }
}
