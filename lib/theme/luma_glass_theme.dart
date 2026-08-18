import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'astra_design_tokens.dart';
import 'astra_screen_kit.dart';

/// Shared "premium healing pink" glassmorphism system — introduced on the
/// Luma AI chat hero (see `luma_chat_sheet.dart`) and reused wherever the app
/// wants that same soft, uncluttered, Apple-like look. Intentionally NOT
/// theme-aware (moon/sun) — this is its own consistent pink world, opted
/// into screen-by-screen (Home first; see [LumaGlassBackground]).
///
/// Kept independent from `luma_chat_sheet.dart`'s private `_Pink` class
/// (same values, deliberately duplicated) so that file's already-shipped,
/// user-approved look can't regress from edits made here. If the two ever
/// need to diverge (e.g. a screen wants a slightly different tint), that's
/// fine — they're allowed to.
class LumaGlass {
  LumaGlass._();

  /// The palette selected in Profile (set app-wide from `activePaletteProvider`
  /// via `AstraKit.active`). Every accent/background token below now derives
  /// from it, so picking a theme recolours everything that uses LumaGlass —
  /// Home, the AI chat sheet, the journal screen. Falls back to the original
  /// Luma pink on the very first frame before a palette is set.
  static AstraPalette? get _p => AstraKit.active;

  // Background wash — now a single FLAT colour per palette (no top→bottom
  // darkening gradient, per the "düz renk arka plan" request).
  static Color get bgTop => _p?.gradientTop ?? const Color(0xFFFCE8EE);
  static Color get bgMid => bgTop;
  static Color get bgBottom => bgTop;
  static List<Color> get backgroundGradient => [bgTop, bgTop];

  // Brand + type. Body/heading text stays a fixed dark neutral so it's always
  // readable on any pastel; the eyebrow/subtitle follow the palette accent.
  static Color get wordmark => _p?.bottomNavActive ?? const Color(0xFFAC8794);
  static const heroInk = Color(0xFF2A2433); // near-black headline
  static Color get subtitle => _p?.primary ?? const Color(0xFFCB9FB1);

  // Frosted-glass surface tokens (blurred, low-opacity — never flat white).
  static const glassFillTop = Color(0x8CFFFFFF); // ~55% white
  static const glassFillBottom = Color(0x47FFFFFF); // ~28% white
  static const glassBorder = Color(0x8CFFFFFF); // ~55% white hairline
  static Color get glassShadow =>
      (_p?.primary ?? const Color(0xFFC77D9B)).withValues(alpha: 0.16);

  // Reading colours on top of glass (fixed dark neutrals for legibility).
  static const ink = Color(0xFF3A3444);
  static const cardTitle = Color(0xFF3B3543);
  static const hint = Color(0xFFB6A8BE);

  static Color get sparkle => _p?.primary ?? const Color(0xFFC77D9B);

  static List<Color> get accentGradient => [
        _p?.buttonPrimary ?? const Color(0xFFEAAAC8),
        _p?.primary ?? const Color(0xFFCE7CA6),
      ];
  static Color get accentShadow =>
      (_p?.primary ?? const Color(0xFFCE7CA6)).withValues(alpha: 0.30);
  static Color get accentInk =>
      _p?.secondary ?? const Color(0xFFA85777); // text/icon on light accent tints

  static const double cardRadius = 26;
  static const double blurSigma = 20;

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.manrope(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static BoxDecoration glassDecoration({
    double radius = cardRadius,
    List<BoxShadow>? shadow,
  }) =>
      BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glassFillTop, glassFillBottom],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glassBorder, width: 1.1),
        boxShadow: shadow ??
            [
              BoxShadow(color: glassShadow, blurRadius: 26, offset: const Offset(0, 12)),
            ],
      );
}

/// Full-bleed background behind any screen that opts into the [LumaGlass]
/// look. Now a single FLAT colour taken from the selected palette (no photo,
/// no Ken Burns, and no top→bottom darkening gradient) so the whole screen is
/// one clean solid colour that changes with the chosen theme.
class LumaGlassBackground extends StatelessWidget {
  const LumaGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: LumaGlass.bgTop,
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
          decoration: LumaGlass.glassDecoration(radius: radius),
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
        color: Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, size: iconSize, color: LumaGlass.sparkle),
    );
  }
}
