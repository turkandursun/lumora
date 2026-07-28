import 'package:flutter/material.dart';

/// Light, airy "spring morning" palette used only by the Home screen — a
/// deliberate departure from [LumoraPalette]'s night-sky world used
/// everywhere else in the app (auth, onboarding, mood-gradient screens).
/// Lavender-pink-cream pastels, sakura branches instead of moon/stars.
class SakuraHomePalette {
  SakuraHomePalette._();

  static const Color lavender = Color(0xFFF3E8FB);
  static const Color blush = Color(0xFFFDE7F3);
  static const Color cream = Color(0xFFFFF8ED);
  static const Color mint = Color(0xFFE3F6ED);
  static const Color blossomPink = Color(0xFFF9A8D4);
  static const Color petalPink = Color(0xFFFFD6E7);
  static const Color branchMauve = Color(0xFFB79AC7);
  static const Color textDeep = Color(0xFF463A55);
  static const Color textMuted = Color(0xFF8B7C99);
  static const Color cardWhite = Color(0xF2FFFFFF);

  /// Top-to-bottom light lavender → soft pink → cream wash, the light-mode
  /// counterpart to `LumoraPalette.backgroundGradient`.
  static const List<Color> backgroundGradient = [lavender, blush, cream];

  static const List<Color> ctaGradient = [blossomPink, petalPink];

  /// Solid pastel fills rotated across the Home feature grid cards — pink,
  /// lavender, cream, mint — so neighboring cards read as gentle variety
  /// without resorting to a saturated gradient fill.
  static const List<Color> cardFills = [blush, lavender, cream, mint];
}
