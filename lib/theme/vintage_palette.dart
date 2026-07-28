import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vintage "pressed-flower journal" palette + typography for Lumora's
/// first-touch surfaces (login, sign up, onboarding).
///
/// This is a warm, aged-paper world — cream parchment, sepia ink, muted
/// sage and dusty rose — deliberately distinct from [LumoraPalette]'s dark
/// night-sky auth theme. Kept in its own file so the existing dark screens
/// stay untouched while these screens migrate to the vintage look.
class VintagePalette {
  VintagePalette._();

  // --- Paper / surfaces ---
  /// Aged-paper background, top to bottom (a soft warm cream that deepens
  /// slightly toward the foot of the page like a sun-faded page).
  static const Color paperTop = Color(0xFFF3ECDC);
  static const Color paperMid = Color(0xFFEBE1CC);
  static const Color paperBottom = Color(0xFFE0D3B8);

  /// Parchment used for the raised form card — a touch lighter than the
  /// page so it reads as a pressed leaf of paper laid on top.
  static const Color parchment = Color(0xFFF7F1E4);

  /// Slightly brighter cream used inside input fields.
  static const Color parchmentField = Color(0xFFFCF8EF);

  // --- Ink ---
  /// Deep sage-charcoal used for headings and the wordmark.
  static const Color inkDeep = Color(0xFF474C3D);

  /// Softer sepia for body copy and field text.
  static const Color inkSoft = Color(0xFF6C6552);

  /// Muted sepia for hints, placeholders and quiet captions.
  static const Color inkMuted = Color(0xFF9C917A);

  // --- Accents ---
  /// Muted sage green — the primary action colour (buttons).
  static const Color sage = Color(0xFF8B9578);
  static const Color sageDeep = Color(0xFF6F7B5D);

  /// Dusty rose — links, highlights and the small heart/flower motifs.
  static const Color dustyRose = Color(0xFFB27C74);
  static const Color rosePetal = Color(0xFFD3ABA4);

  // --- Lines / borders ---
  /// Soft brown hairline used for field borders and ornamental rules.
  static const Color line = Color(0xFFC9BB9C);
  static const Color lineSoft = Color(0xFFD9CDB1);

  static const List<Color> pageGradient = [paperTop, paperMid, paperBottom];

  /// Elegant serif wordmark, e.g. the "Lumora" title.
  static TextStyle wordmark({
    double fontSize = 46,
    Color color = inkDeep,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: color,
    );
  }

  /// Section / card titles ("Kayıt Ol", "Giriş Yap").
  static TextStyle heading({
    double fontSize = 26,
    Color color = inkDeep,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      color: color,
    );
  }

  /// Italic serif tagline under the wordmark.
  static TextStyle tagline({
    double fontSize = 16,
    Color color = inkSoft,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.5,
      color: color,
    );
  }

  /// Readable serif for body copy, fields, hints and buttons.
  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = inkSoft,
    double letterSpacing = 0.2,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.ebGaramond(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  /// Small uppercase label used on divider rules ("YA DA").
  static TextStyle overline({
    double fontSize = 12,
    Color color = inkMuted,
  }) {
    return GoogleFonts.ebGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 3.0,
      color: color,
    );
  }
}
