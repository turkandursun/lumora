import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'astra_design_tokens.dart';

/// Shared palette-aware premium glassmorphism system — introduced on the
/// Luma AI chat hero (see `luma_chat_sheet.dart`) and reused wherever the app
/// wants the same soft, uncluttered, Apple-like look. The blur, opacity and
/// radius language stays constant while both palette and brightness react.
class LumaGlass {
  LumaGlass._();

  static AstraPalette _palette(BuildContext context) =>
      AstraThemeTokens.of(context).palette;
  static AstraThemeTokens _tokens(BuildContext context) =>
      AstraThemeTokens.of(context);

  static Color bgTop(BuildContext context) => _palette(context).gradientTop;
  static Color bgMid(BuildContext context) => Color.lerp(
        _palette(context).gradientTop,
        _palette(context).gradientBottom,
        0.5,
      )!;
  static Color bgBottom(BuildContext context) =>
      _palette(context).gradientBottom;
  static List<Color> backgroundGradient(BuildContext context) =>
      [bgTop(context), bgMid(context), bgBottom(context)];

  // Brand + type.
  static Color wordmark(BuildContext context) => _palette(context).secondary;
  static Color heroInk(BuildContext context) => _tokens(context).textPrimary;
  static Color subtitle(BuildContext context) => _tokens(context).textMuted;

  // Frosted-glass surface tokens (blurred, low-opacity — never flat white).
  static Color glassFillTop(BuildContext context) =>
      _palette(context).surfaceElevated.withValues(alpha: 0.68);
  static Color glassFillBottom(BuildContext context) =>
      _palette(context).surfaceElevated.withValues(alpha: 0.34);
  static Color glassBorder(BuildContext context) =>
      _palette(context).softBorder.withValues(alpha: 0.65);
  static Color glassShadow(BuildContext context) => _palette(context).focusGlow;

  // Reading colours on top of glass.
  static Color ink(BuildContext context) => _tokens(context).textSecondary;
  static Color cardTitle(BuildContext context) => _tokens(context).textPrimary;
  static Color hint(BuildContext context) => _tokens(context).textMuted;

  static Color sparkle(BuildContext context) => _palette(context).activeAccent;

  static List<Color> accentGradient(BuildContext context) =>
      [_palette(context).buttonPrimary, _palette(context).secondary];
  static Color accentShadow(BuildContext context) =>
      _palette(context).focusGlow;
  static Color accentInk(BuildContext context) =>
      _palette(context).bottomNavActive;

  static const double cardRadius = 26;
  static const double blurSigma = 20;

  static TextStyle sans(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.manrope(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? ink(context),
        height: height,
        letterSpacing: letterSpacing,
      );

  static BoxDecoration glassDecoration(
    BuildContext context, {
    double radius = cardRadius,
    List<BoxShadow>? shadow,
  }) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glassFillTop(context), glassFillBottom(context)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glassBorder(context), width: 1.1),
        boxShadow: shadow ??
            [
              BoxShadow(
                  color: glassShadow(context),
                  blurRadius: 26,
                  offset: const Offset(0, 12)),
            ],
      );
}

/// Full-bleed pink gradient background — the flat, calm wash behind any
/// screen that opts into the [LumaGlass] look, replacing the busy mountain
/// photo used elsewhere in the app. Deliberately simple (no photo, no Ken
/// Burns) so cards read clearly on top of it.
class LumaGlassBackground extends StatelessWidget {
  const LumaGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: AstraThemeTokens.of(context).isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarIconBrightness: AstraThemeTokens.of(context).isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: LumaGlass.backgroundGradient(context),
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A reusable frosted-glass container: wraps [child] in a blurred,
/// pink-tinted glass surface — the single visual building block for the
/// "Luma glass" look, so every screen that opts in gets pixel-identical
/// glass (same blur, same fill, same border) instead of hand-rolled copies.
class LumaGlassCard extends StatelessWidget {
  const LumaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = LumaGlass.cardRadius,
    this.blurSigma = LumaGlass.blurSigma,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: LumaGlass.glassDecoration(context, radius: radius),
          child: child,
        ),
      ),
    );
  }
}

/// A soft, flat (non-blurred) tinted circle for small repeated elements —
/// quick-action icons, avatars, badges. Deliberately skips [BackdropFilter]:
/// applying real-time blur to many small tiles at once (e.g. a 9-icon grid)
/// is the exact per-card blur cost [AstraGlassCard] documents avoiding, so
/// this reads as soft/translucent through flat colour alone, which is enough
/// once it's already sitting on the flat [LumaGlassBackground] wash.
class LumaIconCircle extends StatelessWidget {
  const LumaIconCircle({
    super.key,
    required this.icon,
    this.size = 56,
    this.iconSize = 22,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AstraThemeTokens.of(context)
            .palette
            .surfaceElevated
            .withValues(alpha: 0.56),
        border: Border.all(
          color: AstraThemeTokens.of(context).palette.softBorder,
        ),
      ),
      child: Icon(icon, size: iconSize, color: LumaGlass.sparkle(context)),
    );
  }
}
