import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

  /// App-wide accent — the single, fixed "Luma" healing-pink tint used
  /// everywhere (Home, AI chat, and now every other screen), matching
  /// `LumaGlass.sparkle`. `isDark` is kept as a parameter purely so the
  /// hundreds of existing call sites (`AstraKit.primary(isDark)`) don't need
  /// to change, but it's ignored: the app no longer has a separate dark/moon
  /// look, so there's nothing left for it to switch between. See [gold].
  static Color primary(bool isDark) => const Color(0xFFA85777);

  /// ASTRA login/signup accent — the same fixed rose-pink family as
  /// [primary], so the branded auth flow matches the rest of the app.
  static Color gold(bool isDark) => const Color(0xFFCE7CA6);

  // Reading colours: fixed deep-plum-on-light-pink-glass, matching
  // Home/chat's contrast. Previously these branched light/dark to read
  // against either a dark night photo or a bright sun photo; now that every
  // background is the same flat light pink wash, they're fixed too — a
  // leftover isDark=true branch returning pale, near-white text would be
  // unreadable on the new background, so it's deliberately gone.
  static Color ink(bool isDark) => const Color(0xFF34121F);

  static Color heading(bool isDark) => const Color(0xFF2A1420);

  static Color muted(bool isDark) => const Color(0xDE6B3550);

  static Color faint(bool isDark) => const Color(0xAA7A4058);

  /// Big brand wordmark ("ASTRA") — fixed deep rose, legible on the new
  /// light pink wash everywhere it appears.
  static TextStyle wordmark(bool isDark, {double fontSize = 44}) => GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: const Color(0xFF7A2E4A),
      );

  static TextStyle heading1(bool isDark, {double fontSize = 22, FontWeight fontWeight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: fontWeight, color: heading(isDark));

  static TextStyle heading2(bool isDark, {double fontSize = 16, FontWeight fontWeight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: fontWeight, color: heading(isDark));

  static TextStyle label(bool isDark, {double fontSize = 12, Color? color}) => GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color ?? primary(isDark),
        letterSpacing: 0.3,
      );

  static TextStyle body(bool isDark,
          {double fontSize = 14, FontWeight fontWeight = FontWeight.w600, double? height, Color? color}) =>
      GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: color ?? ink(isDark), height: height);

  static TextStyle mutedText(bool isDark, {double fontSize = 12, FontWeight fontWeight = FontWeight.w500}) =>
      GoogleFonts.outfit(fontSize: fontSize, fontWeight: fontWeight, color: muted(isDark));
}

/// Small code-drawn "ASTRA" wordmark for the entry screens (login, sign-up,
/// name entry). Those screens used to sit over a mountain-scene photo with
/// the wordmark baked into the art itself; now that the background is the
/// flat pink wash (see [AstraMountainBackground]), this keeps the brand mark
/// on screen instead of losing it along with the removed photo.
class AstraWordmarkHeader extends StatelessWidget {
  const AstraWordmarkHeader({super.key, this.fontSize = 34});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ASTRA',
      textAlign: TextAlign.center,
      style: AstraKit.wordmark(false, fontSize: fontSize),
    );
  }
}

/// Full-bleed background — now the same flat, calm pink wash used
/// everywhere else in the app (Home/chat's `LumaGlassBackground`), replacing
/// the old moon/sun mountain photography so every screen shares one
/// consistent look with nothing left over from the previous theme.
///
/// [isDark] and [useEntryScene] are kept as parameters purely so existing
/// call sites don't need to change; they no longer affect what's rendered —
/// there's only one background now. Colours are duplicated from
/// `LumaGlass.backgroundGradient` (not imported) matching this codebase's
/// established pattern (see `luma_chat_sheet.dart`) of keeping a shared
/// shipped look immune to edits made in a different file.
class AstraMountainBackground extends StatelessWidget {
  const AstraMountainBackground({
    super.key,
    required this.isDark,
    required this.child,
    this.useEntryScene = false,
  });

  final bool isDark;
  final Widget child;
  final bool useEntryScene;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCE8EE), Color(0xFFF8DCE6), Color(0xFFF1D1DE)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Frosted glass card — real blurred glass (`ClipRRect` + `BackdropFilter`),
/// matching `LumaGlassCard` in `luma_glass_theme.dart` pixel-for-pixel: same
/// blur, same gradient fill, same border/shadow. Every screen using this
/// widget now gets exactly the box treatment introduced on Home/chat, not a
/// recolored version of the old flat-tint card. Values duplicated rather
/// than imported, matching this codebase's established pattern (see
/// `luma_chat_sheet.dart`) of keeping shared shipped surfaces immune to
/// edits made in a different file.
///
/// [isDark] is kept for API compatibility with existing call sites but no
/// longer changes the fill — there's one glass look now, not two.
/// [primaryColor], if passed, still tints the border (some screens use it to
/// echo a specific accent, e.g. the ASTRA sign-in panel).
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
    final border = primaryColor?.withValues(alpha: 0.55) ?? const Color(0x8CFFFFFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8CFFFFFF), Color(0x47FFFFFF)],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1.1),
            boxShadow: const [
              BoxShadow(color: Color(0x28C77D9B), blurRadius: 26, offset: Offset(0, 12)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Circular icon button — flat, white-tinted translucent circle matching
/// `LumaIconCircle`'s technique (no per-tile blur; app bars often carry two
/// or three of these together, and blurring each individually is the same
/// per-tile cost `LumaIconCircle` documents avoiding for icon grids).
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
    final iconColor = primaryColor ?? const Color(0xFFC77D9B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.5),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Icon(icon, size: size * 0.47, color: iconColor),
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
    // pink pill; the dark theme's default is the same rose-pink family,
    // matching the rest of the app's Luma accent instead.
    final useGold = forceGold || !isDark;
    final gradient = useGold
        ? (isDark
            ? const LinearGradient(
                colors: [Color(0xFFF6C9DC), Color(0xFFE18FB4), Color(0xFFB35C82)],
                stops: [0.0, 0.55, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFFFCE0EB), Color(0xFFEAAAC8), Color(0xFFB35C82)],
                stops: [0.0, 0.55, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ))
        : const LinearGradient(
            colors: [Color(0xFFEAAAC8), Color(0xFFCE7CA6)],
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
      child: BouncyTap(
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
    // Fixed light pink glass tint — matches the new background everywhere,
    // so there's no more separate dark-mode fill to keep in sync.
    const fill = Color(0x73FCEAF0);

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

/// Provides a "replay" signal to every [AstraEntrance] beneath it: whenever the
/// given [Listenable] fires, those entrances re-run their cascade. Wrap a screen
/// with this and tick the notifier each time the screen becomes visible again
/// (e.g. on tab switch) so the entrance choreography plays every time, not just
/// on first build.
class AstraEntranceReplay extends InheritedWidget {
  const AstraEntranceReplay({super.key, required this.notifier, required super.child});

  final Listenable notifier;

  static Listenable? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AstraEntranceReplay>()?.notifier;

  @override
  bool updateShouldNotify(AstraEntranceReplay oldWidget) => !identical(notifier, oldWidget.notifier);
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

class _AstraEntranceState extends State<AstraEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
  // easeOutBack overshoots past 1.0, giving the gentle spring settle.
  late final Animation<double> _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  Listenable? _replay;

  int get _delay => widget.index != null ? widget.index! * widget.intervalMs : widget.delayMs;

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
            child: widget.scaleFrom == 1.0 ? child : Transform.scale(scale: scale, child: child),
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
      builder: (context, v, _) => Text('$v', style: style, textAlign: textAlign),
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

class _BouncyTapState extends State<BouncyTap> with SingleTickerProviderStateMixin {
  // Unbounded so the spring can overshoot below 0 (a slight grow-past-100%
  // bounce) on release.
  late final AnimationController _controller = AnimationController.unbounded(vsync: this, value: 0);
  // Playful spring (mass 1 · stiffness 250 · damping 20): a small, soft
  // overshoot on release — bouncy without feeling floppy.
  static const _spring = SpringDescription(mass: 1, stiffness: 250, damping: 20);

  void _press() {
    _controller.animateTo(1, duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
  }

  void _release() {
    _controller.animateWith(SpringSimulation(_spring, _controller.value, 0, _controller.velocity));
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
          final scale = 1 - (1 - widget.pressedScale) * _controller.value.clamp(-0.6, 1.4);
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
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      openBuilder: (context, _) => openBuilder(context),
      closedBuilder: (context, open) => closedBuilder(context, open),
    );
  }
}
