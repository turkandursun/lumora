import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'astra_design_tokens.dart';

/// Shared building blocks for the app's premium "Astra" look — the gold
/// glass-card aesthetic introduced on the journal writing screen (mountain
/// scene, frosted glass cards, gold accents, Playfair Display headings over
/// Outfit body text). Screens that adopt this kit get the exact same colors
/// and shapes as the journal screens, so moving between them feels like one
/// consistent app rather than several bolted together.
class AstraKit {
  AstraKit._();

  static AstraPalette palette(BuildContext context) =>
      AstraThemeTokens.of(context).palette;

  static AstraThemeTokens tokens(BuildContext context) =>
      AstraThemeTokens.of(context);

  /// App-wide accent. With a palette active this is the palette primary;
  /// otherwise the legacy soft violet (moon) / gold (sun) accent.
  static Color primary(BuildContext context, bool isDark) =>
      palette(context).primary;

  /// Always-gold accent, regardless of theme — reserved for the ASTRA
  /// login/signup screens so their branded moon-and-gold look never
  /// switches to the violet accent used everywhere else.
  static Color gold(BuildContext context, bool isDark) =>
      isDark ? const Color(0xFFE3C264) : const Color(0xFFD4AF37);

  // Reading colours. With a palette active, every family is a light pastel, so
  // text is the shared dark tokens (constant readability, never light-on-light).
  // Without a palette, the legacy warm-light-on-moon / deep-brown-on-sun tones.
  static Color ink(BuildContext context, bool isDark) =>
      tokens(context).textSecondary;

  static Color heading(BuildContext context, bool isDark) =>
      tokens(context).textPrimary;

  static Color muted(BuildContext context, bool isDark) =>
      tokens(context).textMuted;

  static Color faint(BuildContext context, bool isDark) =>
      tokens(context).textMuted.withValues(alpha: 0.60);

  /// Big brand wordmark ("ASTRA") — gold on the dark/moon scene; a deep bronze
  /// on the bright sun scene, where literal gold would wash out.
  static TextStyle wordmark(BuildContext context, bool isDark,
          {double fontSize = 44}) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: isDark ? gold(context, isDark) : palette(context).secondary,
      );

  static TextStyle heading1(BuildContext context, bool isDark,
          {double fontSize = 22, FontWeight fontWeight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: heading(context, isDark));

  static TextStyle heading2(BuildContext context, bool isDark,
          {double fontSize = 16, FontWeight fontWeight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: heading(context, isDark));

  static TextStyle label(BuildContext context, bool isDark,
          {double fontSize = 12, Color? color}) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color ?? palette(context).secondary,
        letterSpacing: 0.3,
      );

  static TextStyle body(BuildContext context, bool isDark,
          {double fontSize = 14,
          FontWeight fontWeight = FontWeight.w600,
          double? height,
          Color? color}) =>
      GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color ?? ink(context, isDark),
          height: height);

  static TextStyle mutedText(BuildContext context, bool isDark,
          {double fontSize = 12, FontWeight fontWeight = FontWeight.w500}) =>
      GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: muted(context, isDark));
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
    final palette = AstraKit.palette(context);

    // The main app now uses a soft palette gradient instead of the photo
    // scene. The branded entry journey (login/onboarding) keeps its moon/sun
    // artwork for now.
    final usePalette = !useEntryScene;

    final asset = useEntryScene
        ? (isDark
            ? 'assets/images/astra_dark_plain.png'
            : 'assets/images/astra_sun_bg_g5.png')
        : (isDark
            ? 'assets/images/app_theme_dark.jpeg'
            : 'assets/images/app_theme_light.jpeg');
    // Light pastel palette or the sun scene → dark icons; only the dark moon
    // entry scene needs light icons.
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: ColoredBox(
        color: usePalette
            ? palette.gradientTop
            : (isDark ? const Color(0xFF0F0B1A) : const Color(0xFFFDF6E9)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (usePalette)
              DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: palette.backgroundGradient))
            else
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

/// Frosted glass card. The mountain scene behind it is already softly blurred
/// once, app-wide, by [AstraMountainBackground] — so instead of an expensive
/// per-card [BackdropFilter] (which re-blurs every frame during animations and
/// was the main source of jank), the card uses a translucent tint over that
/// pre-blurred scene. Cheap to composite, so entrances / taps / page
/// transitions stay smooth even with many cards on screen.
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
    final active = AstraKit.palette(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        // With a palette active every card is soft white glass (the pastel
        // gradient shows through); otherwise the legacy dark/light tint.
        color: active.cardBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: active.softBorder, width: 1.2),
      ),
      child: Padding(padding: padding, child: child),
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
    final primary = primaryColor ?? AstraKit.primary(context, isDark);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              AstraKit.palette(context).surfaceElevated.withValues(alpha: 0.9),
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
    // With a palette active (and not a branded gold screen), the primary CTA
    // becomes a soft primary→secondary pill in the theme's colours.
    final palette = AstraKit.palette(context);
    final usePalette = !forceGold;
    final useGold = !usePalette && (forceGold || !isDark);
    final gradient = usePalette
        ? LinearGradient(
            colors: [palette.buttonPrimary, palette.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : useGold
            ? (isDark
                ? const LinearGradient(
                    colors: [
                      Color(0xFFF0D68A),
                      Color(0xFFD4A93F),
                      Color(0xFF8A6A10)
                    ],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFFFFEBA3),
                      Color(0xFFEBB818),
                      Color(0xFFAA7A0A)
                    ],
                    stops: [0.0, 0.55, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ))
            : const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFF9A8D4)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              );
    final primary = usePalette
        ? palette.primary
        : (useGold
            ? AstraKit.gold(context, isDark)
            : AstraKit.primary(context, isDark));
    final contentColor = usePalette
        ? palette.onPrimary
        : (useGold ? const Color(0xFF1A0F00) : Colors.white);
    final active = enabled && !isLoading;
    final radius = height / 2;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.55,
      child: BouncyTap(
        onTap: active ? onTap : null,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: gradient,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.45), width: 1),
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
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.35 : 0.22),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(contentColor),
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
    final primary = primaryColor ?? AstraKit.primary(context, isDark);
    // Translucent glass field in both themes: dark tint on the moon scene, a
    // light cream tint on the bright sun scene.
    final fill = isDark ? const Color(0x33231845) : const Color(0x73FBF1DC);

    OutlineInputBorder border(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
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
            Text(label, style: AstraKit.label(context, isDark)),
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
          style: AstraKit.body(context, isDark, fontSize: 14.5),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color: primary.withValues(alpha: 0.85), size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: border(primary.withValues(alpha: 0.4)),
            enabledBorder: border(primary.withValues(alpha: 0.4)),
            focusedBorder: border(primary, 1.6),
            errorBorder: border(const Color(0xFFE07A7A)),
            focusedErrorBorder: border(const Color(0xFFE07A7A), 1.6),
            errorStyle: GoogleFonts.outfit(
                fontSize: 12, color: const Color(0xFFE07A7A)),
          ),
        ),
      ],
    );
  }
}

/// A thin gold hairline flanking a short label — used to separate sections
/// (e.g. "VEYA" between the sign-in form and the Google button).
class AstraLabeledDivider extends StatelessWidget {
  const AstraLabeledDivider(
      {super.key,
      required this.isDark,
      required this.label,
      this.primaryColor});

  final bool isDark;
  final String label;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AstraKit.primary(context, isDark);
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
              color: AstraKit.muted(context, isDark),
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// Provides a "replay" signal to every [AstraEntrance] beneath it: whenever the
/// given [Listenable] fires, those entrances re-run their cascade. Wrap a screen
/// with this and tick the notifier each time the screen becomes visible again
/// (e.g. on tab switch) so the entrance choreography plays every time, not just
/// on first build.
class AstraEntranceReplay extends InheritedWidget {
  const AstraEntranceReplay(
      {super.key, required this.notifier, required super.child});

  final Listenable notifier;

  static Listenable? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AstraEntranceReplay>()
      ?.notifier;

  @override
  bool updateShouldNotify(AstraEntranceReplay oldWidget) =>
      !identical(notifier, oldWidget.notifier);
}

/// Staggered fade + slide-in entrance with a soft spring settle. The child
/// rises [offset] logical pixels from below while fading 0→1, overshooting a
/// touch (Curves.easeOutBack) so it "springs" into place — the Reflectly-style
/// content cascade. Give siblings an increasing [index] (delay = index ×
/// [intervalMs]) so a screen's cards flow in one after another.
///
/// Usage:
/// ```dart
/// Column(children: [
///   for (var i = 0; i < cards.length; i++)
///     AstraEntrance(index: i, child: cards[i]),
/// ])
/// ```
class AstraEntrance extends StatefulWidget {
  const AstraEntrance({
    super.key,
    required this.child,
    this.index,
    this.intervalMs = 100,
    this.delayMs = 0,
    this.offset = 30,
    this.scaleFrom = 1.0,
    this.duration = const Duration(milliseconds: 360),
  });

  final Widget child;

  /// Position in a staggered group; if set, the start delay is
  /// `index * intervalMs`. Falls back to [delayMs] when null.
  final int? index;
  final int intervalMs;
  final int delayMs;

  /// How far below its resting place the child starts, in logical pixels.
  final double offset;

  /// Starting scale — set below 1.0 (e.g. 0.8 for chips) to have the child
  /// grow into place; the easeOutBack curve makes it spring slightly past 1.0.
  final double scaleFrom;
  final Duration duration;

  @override
  State<AstraEntrance> createState() => _AstraEntranceState();
}

class _AstraEntranceState extends State<AstraEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
  // easeOutBack overshoots past 1.0, giving the gentle spring settle.
  late final Animation<double> _slide =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  Listenable? _replay;

  int get _delay =>
      widget.index != null ? widget.index! * widget.intervalMs : widget.delayMs;

  void _play() {
    _controller.value = 0;
    if (_delay <= 0) {
      _controller.forward(from: 0);
    } else {
      Future<void>.delayed(Duration(milliseconds: _delay), () {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-run the entrance whenever an ancestor [AstraEntranceReplay] ticks — so
    // the choreography replays every time a screen becomes visible again, not
    // only on first build.
    final r = AstraEntranceReplay.maybeOf(context);
    if (!identical(r, _replay)) {
      _replay?.removeListener(_play);
      _replay = r;
      _replay?.addListener(_play);
    }
  }

  @override
  void dispose() {
    _replay?.removeListener(_play);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final t = _slide.value; // may overshoot past 1.0 (spring settle)
        final scale = widget.scaleFrom + (1 - widget.scaleFrom) * t;
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: widget.scaleFrom == 1.0
                ? child
                : Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// A number that counts up from zero to [value] the first time it appears — the
/// "odometer" stat counter for streaks, entries, points, etc. Re-animates from
/// the current value whenever [value] changes.
class AstraCountUp extends StatelessWidget {
  const AstraCountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.textAlign,
  });

  final int value;
  final TextStyle style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$v', style: style, textAlign: textAlign),
    );
  }
}

/// A tap wrapper that gives any card or button a bouncy micro-interaction:
/// it shrinks to [pressedScale] on press, then springs back to full size with
/// real spring physics (overshooting slightly), firing a light haptic on tap.
/// Reusable — wrap any tappable widget:
/// ```dart
/// BouncyTap(onTap: () => context.push(route), child: myCard)
/// ```
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  // Unbounded so the spring can overshoot below 0 (a slight grow-past-100%
  // bounce) on release.
  late final AnimationController _controller =
      AnimationController.unbounded(vsync: this, value: 0);
  // Playful spring (mass 1 · stiffness 250 · damping 20): a small, soft
  // overshoot on release — bouncy without feeling floppy.
  static const _spring =
      SpringDescription(mass: 1, stiffness: 250, damping: 20);

  void _press() {
    _controller.animateTo(1,
        duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
  }

  void _release() {
    _controller.animateWith(
        SpringSimulation(_spring, _controller.value, 0, _controller.velocity));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _press() : null,
      onTapCancel: enabled ? _release : null,
      onTapUp: enabled
          ? (_) {
              _release();
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final scale = 1 -
              (1 - widget.pressedScale) * _controller.value.clamp(-0.6, 1.4);
          return Transform.scale(scale: scale, child: child);
        },
      ),
    );
  }
}

/// Container-transform navigation: tapping the card "morphs" it outward until
/// it fills the destination screen (and shrinks back on pop) instead of a plain
/// page push — the game-like "carried from one place to another" feel. Reusable
/// across the app: give it the card ([closedBuilder] receives an `open`
/// callback to trigger the morph) and the destination ([openBuilder]).
class AstraMorphContainer extends StatelessWidget {
  const AstraMorphContainer({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.borderRadius = 20,
  });

  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final WidgetBuilder openBuilder;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 340),
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius)),
      openBuilder: (context, _) => openBuilder(context),
      closedBuilder: (context, open) => closedBuilder(context, open),
    );
  }
}
