import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// ASTRA · Design Tokens (v2 — richer, soft-premium palettes)
/// ─────────────────────────────────────────────────────────────────────────
///
/// A single, theme-agnostic token model plus 7 refined pastel palettes. The
/// gradients now have more depth (light top → richer, more saturated bottom)
/// and slightly deeper accents, so the app reads as premium rather than washed
/// out — while staying soft and keeping dark text readable on every surface.
class AstraText {
  const AstraText._();

  /// Headings — near-black anthracite.
  static const title = Color(0xFF1D1A22);

  /// Body copy — very dark grey.
  static const body = Color(0xFF2C2731);

  /// Secondary / helper text — medium-dark grey.
  static const muted = Color(0xFF4A4452);
}

/// The 6 selectable theme families.
enum AstraThemeId {
  lumaPink,
  softLilacMist,
  sageVeil,
  mutedSkyBloom,
  apricotCloud,
  smokyTealAura,
}

/// A complete set of surface/accent tokens for one theme.
@immutable
class AstraPalette {
  const AstraPalette({
    required this.id,
    required this.name,
    required this.mood,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.surfaceElevated,
    required this.gradientTop,
    required this.gradientBottom,
    required this.cardBackground,
    required this.inputBackground,
    required this.activeAccent,
    required this.softBorder,
    required this.iconContainer,
    required this.bottomNavActive,
    required this.bottomNavInactive,
    required this.buttonPrimary,
    required this.buttonSecondary,
    required this.chipSelected,
    required this.chipUnselected,
    required this.dividerSoft,
    required this.focusGlow,
  });

  final AstraThemeId id;
  final String name;
  final String mood;

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color surfaceElevated;
  final Color gradientTop;
  final Color gradientBottom;
  final Color cardBackground;
  final Color inputBackground;
  final Color activeAccent;
  final Color softBorder;
  final Color iconContainer;
  final Color bottomNavActive;
  final Color bottomNavInactive;
  final Color buttonPrimary;
  final Color buttonSecondary;
  final Color chipSelected;
  final Color chipUnselected;
  final Color dividerSoft;
  final Color focusGlow;

  /// The app background — a soft vertical gradient with real depth.
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientTop, gradientBottom],
      );

  /// Best on-primary text colour for legibility.
  Color get onPrimary =>
      primary.computeLuminance() < 0.5 ? Colors.white : AstraText.title;
}

/// ─────────────────────────────────────────────────────────────────────────
/// The 7 palettes (soft, but rich)
/// ─────────────────────────────────────────────────────────────────────────

/// The signature "Luma" healing-pink used on Home, the AI chat sheet and the
/// journal writing screen — now available as a selectable family too, and the
/// app's default. Its background/accent values match `LumaGlass` exactly so
/// picking it makes every palette-driven screen line up with those three
/// LumaGlass surfaces.
const astraLumaPink = AstraPalette(
  id: AstraThemeId.lumaPink,
  name: 'Luma Pink',
  mood: 'Yumuşak, şifalı pembe',
  primary: Color(0xFFCE7CA6),
  secondary: Color(0xFFB35C82),
  surface: Color(0xFFFCE8EE),
  surfaceElevated: Color(0xFFFFF6FA),
  gradientTop: Color(0xFFFCE8EE),
  gradientBottom: Color(0xFFFCE8EE),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFFBE4EC),
  activeAccent: Color(0xFFC77D9B),
  softBorder: Color(0x33CE7CA6),
  iconContainer: Color(0xFFF6D6E3),
  bottomNavActive: Color(0xFFA85777),
  bottomNavInactive: Color(0xFFBE9EAA),
  buttonPrimary: Color(0xFFEAAAC8),
  buttonSecondary: Color(0xFFF7DEE9),
  chipSelected: Color(0xFFCE7CA6),
  chipUnselected: Color(0xFFF5DDE7),
  dividerSoft: Color(0x22CE7CA6),
  focusGlow: Color(0x66CE7CA6),
);

// The five non-pink families below were re-toned (Aug 2026) to livelier, more
// saturated pastels — soft but never washed-out/"dead" — sitting at the same
// pastel weight as Luma Pink so the whole set reads as one harmonious family.
// Every background is now a single flat colour (gradientTop == gradientBottom),
// no top→bottom darkening gradient.

const astraSoftLilacMist = AstraPalette(
  id: AstraThemeId.softLilacMist,
  name: 'Lila',
  mood: 'Canlı lavanta',
  primary: Color(0xFFAE8AEF),
  secondary: Color(0xFF8B63E6),
  surface: Color(0xFFF0E9FE),
  surfaceElevated: Color(0xFFFAF7FF),
  gradientTop: Color(0xFFEEE7FE),
  gradientBottom: Color(0xFFEEE7FE),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFE7DEFC),
  activeAccent: Color(0xFF8B63E6),
  softBorder: Color(0x338B63E6),
  iconContainer: Color(0xFFDECFFB),
  bottomNavActive: Color(0xFF6E4FCF),
  bottomNavInactive: Color(0xFFA79FB4),
  buttonPrimary: Color(0xFFC0A6F4),
  buttonSecondary: Color(0xFFE9E0FB),
  chipSelected: Color(0xFFAE8AEF),
  chipUnselected: Color(0xFFE4DAFA),
  dividerSoft: Color(0x228B63E6),
  focusGlow: Color(0x66AE8AEF),
);

const astraSageVeil = AstraPalette(
  id: AstraThemeId.sageVeil,
  name: 'Yeşil',
  mood: 'Taze pastel yeşil',
  primary: Color(0xFF74C79C),
  secondary: Color(0xFF43A877),
  surface: Color(0xFFE7F6EE),
  surfaceElevated: Color(0xFFF6FDF9),
  gradientTop: Color(0xFFE4F5EC),
  gradientBottom: Color(0xFFE4F5EC),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFDCF1E5),
  activeAccent: Color(0xFF43A877),
  softBorder: Color(0x3343A877),
  iconContainer: Color(0xFFC9EBD8),
  bottomNavActive: Color(0xFF2E8259),
  bottomNavInactive: Color(0xFF9CA99E),
  buttonPrimary: Color(0xFF8AD3AE),
  buttonSecondary: Color(0xFFDBF1E5),
  chipSelected: Color(0xFF74C79C),
  chipUnselected: Color(0xFFD8EFE2),
  dividerSoft: Color(0x2243A877),
  focusGlow: Color(0x6674C79C),
);

const astraMutedSkyBloom = AstraPalette(
  id: AstraThemeId.mutedSkyBloom,
  name: 'Mavi',
  mood: 'Ferah gökyüzü mavisi',
  primary: Color(0xFF6FACE4),
  secondary: Color(0xFF4187CE),
  surface: Color(0xFFE6F1FC),
  surfaceElevated: Color(0xFFF5FAFE),
  gradientTop: Color(0xFFE2EFFC),
  gradientBottom: Color(0xFFE2EFFC),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFD9EAFA),
  activeAccent: Color(0xFF4187CE),
  softBorder: Color(0x334187CE),
  iconContainer: Color(0xFFC8DFF6),
  bottomNavActive: Color(0xFF2F6EB4),
  bottomNavInactive: Color(0xFF9AA7B4),
  buttonPrimary: Color(0xFF8CBEF0),
  buttonSecondary: Color(0xFFDCECFA),
  chipSelected: Color(0xFF6FACE4),
  chipUnselected: Color(0xFFD6E9F8),
  dividerSoft: Color(0x224187CE),
  focusGlow: Color(0x666FACE4),
);

const astraApricotCloud = AstraPalette(
  id: AstraThemeId.apricotCloud,
  name: 'Turuncu',
  mood: 'Sıcak canlı şeftali-turuncu',
  primary: Color(0xFFEF9E63),
  secondary: Color(0xFFE17A34),
  surface: Color(0xFFFFEEDF),
  surfaceElevated: Color(0xFFFFF9F3),
  gradientTop: Color(0xFFFFEAD9),
  gradientBottom: Color(0xFFFFEAD9),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFFCE4D0),
  activeAccent: Color(0xFFE17A34),
  softBorder: Color(0x33E17A34),
  iconContainer: Color(0xFFF9D6BB),
  bottomNavActive: Color(0xFFC0641B),
  bottomNavInactive: Color(0xFFBAA091),
  buttonPrimary: Color(0xFFF3B27E),
  buttonSecondary: Color(0xFFFAE0CB),
  chipSelected: Color(0xFFEF9E63),
  chipUnselected: Color(0xFFF8DCC6),
  dividerSoft: Color(0x22E17A34),
  focusGlow: Color(0x66EF9E63),
);

const astraSmokyTealAura = AstraPalette(
  id: AstraThemeId.smokyTealAura,
  name: 'Turkuaz',
  mood: 'Canlı turkuaz',
  primary: Color(0xFF4DC6BD),
  secondary: Color(0xFF1FA79D),
  surface: Color(0xFFE1F6F3),
  surfaceElevated: Color(0xFFF4FDFC),
  gradientTop: Color(0xFFDBF5F1),
  gradientBottom: Color(0xFFDBF5F1),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFD0F0EB),
  activeAccent: Color(0xFF1FA79D),
  softBorder: Color(0x331FA79D),
  iconContainer: Color(0xFFBFE9E3),
  bottomNavActive: Color(0xFF12857B),
  bottomNavInactive: Color(0xFF90A5A2),
  buttonPrimary: Color(0xFF6FD7CF),
  buttonSecondary: Color(0xFFD3F0EC),
  chipSelected: Color(0xFF4DC6BD),
  chipUnselected: Color(0xFFCFECE7),
  dividerSoft: Color(0x221FA79D),
  focusGlow: Color(0x664DC6BD),
);

/// All palettes, in display order.
const List<AstraPalette> astraPalettes = [
  astraLumaPink,
  astraSoftLilacMist,
  astraSageVeil,
  astraMutedSkyBloom,
  astraApricotCloud,
  astraSmokyTealAura,
];

/// Lookup by id, with a safe default.
AstraPalette astraPaletteFor(AstraThemeId id) =>
    astraPalettes.firstWhere((p) => p.id == id, orElse: () => astraLumaPink);
