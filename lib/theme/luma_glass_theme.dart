import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Background wash (top → bottom).
  static const bgTop = Color(0xFFFCE8EE);
  static const bgMid = Color(0xFFF8DCE6);
  static const bgBottom = Color(0xFFF1D1DE);
  static const backgroundGradient = [bgTop, bgMid, bgBottom];

  // Brand + type.
  static const wordmark = Color(0xFFAC8794); // dusty mauve — eyebrow/labels
  static const heroInk = Color(0xFF2A2433); // near-black headline
  static const subtitle = Color(0xFFCB9FB1); // muted rose — secondary text

  // Frosted-glass surface tokens (blurred, low-opacity — never flat white).
  static const glassFillTop = Color(0x8CFFFFFF); // ~55% white
  static const glassFillBottom = Color(0x47FFFFFF); // ~28% white
  static const glassBorder = Color(0x8CFFFFFF); // ~55% white hairline
  static const glassShadow = Color(0x28C77D9B);

  // Reading colours on top of glass.
  static const ink = Color(0xFF3A3444);
  static const cardTitle = Color(0xFF3B3543);
  static const hint = Color(0xFFB6A8BE);

  static const sparkle = Color(0xFFC77D9B);

  static const accentGradient = [Color(0xFFEAAAC8), Color(0xFFCE7CA6)];
  static const accentShadow = Color(0x4DCE7CA6);
  static const accentInk = Color(0xFFA85777); // text/icon on light accent tints

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
            const [
              BoxShadow(color: glassShadow, blurRadius: 26, offset: Offset(0, 12)),
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: LumaGlass.backgroundGradient,
            stops: [0.0, 0.55, 1.0],
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
