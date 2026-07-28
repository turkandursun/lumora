import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette + typography for Lumora's night-sky auth surfaces
/// (login, sign up, magic-link). This is a distinct, darker world from
/// [AppTheme]'s light in-app theme — used for first-touch screens where
/// the "night sky + purple-to-pink gradient" identity lives.
class LumoraPalette {
  LumoraPalette._();

  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color lightPurple = Color(0xFFC084FC);
  static const Color accentPink = Color(0xFFF9A8D4);
  static const Color softPink = Color(0xFFFFD6E7);
  static const Color warmCream = Color(0xFFFFF4D6);
  static const Color nightBackground = Color(0xFF1A1330);

  /// Top-to-bottom night sky → purple wash used behind auth screens.
  static const List<Color> backgroundGradient = [
    nightBackground,
    Color(0xFF2D2050),
    Color(0xFF4C2E7A),
    primaryPurple,
  ];

  static const List<Color> ctaGradient = [primaryPurple, accentPink];

  static TextStyle logoStyle({
    double fontSize = 42,
    Color color = Colors.white,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 8,
      color: color,
    );
  }

  static TextStyle taglineStyle({
    double fontSize = 12.5,
    Color color = softPink,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 2,
      color: color,
    );
  }

  static TextStyle bodyStyle({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = Colors.white,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Storytelling headline style used on the onboarding pages — same
  /// serif family as the wordmark, softer weight for longer lines.
  static TextStyle storyTitleStyle({
    double fontSize = 27,
    Color color = Colors.white,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: color,
    );
  }
}
