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

/// The 8 selectable theme families.
enum AstraThemeId {
  lumaPink,
  softLilacMist,
  dustyRoseHaze,
  sageVeil,
  mutedSkyBloom,
  apricotCloud,
  berrySand,
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
  gradientBottom: Color(0xFFF1D1DE),
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

const astraSoftLilacMist = AstraPalette(
  id: AstraThemeId.softLilacMist,
  name: 'Soft Lilac Mist',
  mood: 'Zengin, zarif lila',
  primary: Color(0xFFB79CF0),
  secondary: Color(0xFF9B7BE6),
  surface: Color(0xFFF4EFFF),
  surfaceElevated: Color(0xFFFBF8FF),
  gradientTop: Color(0xFFF0E7FF),
  gradientBottom: Color(0xFFC6AEF4),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFF1EAFD),
  activeAccent: Color(0xFF9B7BE6),
  softBorder: Color(0x339B7BE6),
  iconContainer: Color(0xFFE6D9FB),
  bottomNavActive: Color(0xFF7E5FD0),
  bottomNavInactive: Color(0xFFA79FB4),
  buttonPrimary: Color(0xFFB79CF0),
  buttonSecondary: Color(0xFFEEE6FB),
  chipSelected: Color(0xFFB79CF0),
  chipUnselected: Color(0xFFEAE1FA),
  dividerSoft: Color(0x229B7BE6),
  focusGlow: Color(0x66B79CF0),
);

const astraDustyRoseHaze = AstraPalette(
  id: AstraThemeId.dustyRoseHaze,
  name: 'Dusty Rose Haze',
  mood: 'Zengin, tozlu pembe',
  primary: Color(0xFFD998AB),
  secondary: Color(0xFFC67C95),
  surface: Color(0xFFFBEDF1),
  surfaceElevated: Color(0xFFFFF9FB),
  gradientTop: Color(0xFFFBEAF0),
  gradientBottom: Color(0xFFE7A9BF),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFF8E7EE),
  activeAccent: Color(0xFFC67C95),
  softBorder: Color(0x33C67C95),
  iconContainer: Color(0xFFF2D2DD),
  bottomNavActive: Color(0xFFB0637E),
  bottomNavInactive: Color(0xFFB29AA2),
  buttonPrimary: Color(0xFFD998AB),
  buttonSecondary: Color(0xFFF6E2E9),
  chipSelected: Color(0xFFD998AB),
  chipUnselected: Color(0xFFF3DFE7),
  dividerSoft: Color(0x22C67C95),
  focusGlow: Color(0x66D998AB),
);

const astraSageVeil = AstraPalette(
  id: AstraThemeId.sageVeil,
  name: 'Sage Veil',
  mood: 'Zengin, doğal yeşil',
  primary: Color(0xFF9EC2A6),
  secondary: Color(0xFF79A585),
  surface: Color(0xFFEEF6F0),
  surfaceElevated: Color(0xFFFBFEFB),
  gradientTop: Color(0xFFEDF7F0),
  gradientBottom: Color(0xFFABCDB2),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFEAF4ED),
  activeAccent: Color(0xFF79A585),
  softBorder: Color(0x3379A585),
  iconContainer: Color(0xFFD6E8DB),
  bottomNavActive: Color(0xFF588268),
  bottomNavInactive: Color(0xFF9CA99E),
  buttonPrimary: Color(0xFF9EC2A6),
  buttonSecondary: Color(0xFFE4F0E7),
  chipSelected: Color(0xFF9EC2A6),
  chipUnselected: Color(0xFFE1EDE4),
  dividerSoft: Color(0x2279A585),
  focusGlow: Color(0x669EC2A6),
);

const astraMutedSkyBloom = AstraPalette(
  id: AstraThemeId.mutedSkyBloom,
  name: 'Muted Sky Bloom',
  mood: 'Zengin, tozlu mavi',
  primary: Color(0xFF9BBEDE),
  secondary: Color(0xFF74A2CB),
  surface: Color(0xFFEDF5FC),
  surfaceElevated: Color(0xFFFAFCFE),
  gradientTop: Color(0xFFEBF4FC),
  gradientBottom: Color(0xFFA6C7E8),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFE9F2FB),
  activeAccent: Color(0xFF74A2CB),
  softBorder: Color(0x3374A2CB),
  iconContainer: Color(0xFFD2E4F3),
  bottomNavActive: Color(0xFF4F83B4),
  bottomNavInactive: Color(0xFF9AA7B4),
  buttonPrimary: Color(0xFF9BBEDE),
  buttonSecondary: Color(0xFFE2EEF8),
  chipSelected: Color(0xFF9BBEDE),
  chipUnselected: Color(0xFFDEEBF6),
  dividerSoft: Color(0x2274A2CB),
  focusGlow: Color(0x669BBEDE),
);

const astraApricotCloud = AstraPalette(
  id: AstraThemeId.apricotCloud,
  name: 'Apricot Cloud',
  mood: 'Zengin, sıcak pastel turuncu',
  primary: Color(0xFFEAA877),
  secondary: Color(0xFFDB8A54),
  surface: Color(0xFFFFF1E8),
  surfaceElevated: Color(0xFFFFFBF8),
  gradientTop: Color(0xFFFFF0E6),
  gradientBottom: Color(0xFFF4BC92),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFFBEADD),
  activeAccent: Color(0xFFDB8A54),
  softBorder: Color(0x33DB8A54),
  iconContainer: Color(0xFFF8DBC6),
  bottomNavActive: Color(0xFFC4712F),
  bottomNavInactive: Color(0xFFBAA091),
  buttonPrimary: Color(0xFFEAA877),
  buttonSecondary: Color(0xFFFAE3D3),
  chipSelected: Color(0xFFEAA877),
  chipUnselected: Color(0xFFF8E0CF),
  dividerSoft: Color(0x22DB8A54),
  focusGlow: Color(0x66EAA877),
);

const astraBerrySand = AstraPalette(
  id: AstraThemeId.berrySand,
  name: 'Berry Sand',
  mood: 'Zengin, yumuşak berry',
  primary: Color(0xFFD0879A),
  secondary: Color(0xFFBE6A7E),
  surface: Color(0xFFFBEDF0),
  surfaceElevated: Color(0xFFFFFAFB),
  gradientTop: Color(0xFFFBEBEF),
  gradientBottom: Color(0xFFDF9CAB),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFF7E7EB),
  activeAccent: Color(0xFFBE6A7E),
  softBorder: Color(0x33BE6A7E),
  iconContainer: Color(0xFFEFCFD8),
  bottomNavActive: Color(0xFFA2506A),
  bottomNavInactive: Color(0xFFB39AA0),
  buttonPrimary: Color(0xFFD0879A),
  buttonSecondary: Color(0xFFF4E0E6),
  chipSelected: Color(0xFFD0879A),
  chipUnselected: Color(0xFFF1DCE3),
  dividerSoft: Color(0x22BE6A7E),
  focusGlow: Color(0x66D0879A),
);

const astraSmokyTealAura = AstraPalette(
  id: AstraThemeId.smokyTealAura,
  name: 'Smoky Teal Aura',
  mood: 'Zengin, sofistike mavi-yeşil',
  primary: Color(0xFF82B8B2),
  secondary: Color(0xFF5C9A92),
  surface: Color(0xFFEAF5F3),
  surfaceElevated: Color(0xFFF9FDFC),
  gradientTop: Color(0xFFE9F6F4),
  gradientBottom: Color(0xFF99C8C1),
  cardBackground: Color(0xC2FFFFFF),
  inputBackground: Color(0xFFE4F3F0),
  activeAccent: Color(0xFF5C9A92),
  softBorder: Color(0x335C9A92),
  iconContainer: Color(0xFFCFE8E3),
  bottomNavActive: Color(0xFF437E76),
  bottomNavInactive: Color(0xFF90A5A2),
  buttonPrimary: Color(0xFF82B8B2),
  buttonSecondary: Color(0xFFDEEFEC),
  chipSelected: Color(0xFF82B8B2),
  chipUnselected: Color(0xFFDAECE9),
  dividerSoft: Color(0x225C9A92),
  focusGlow: Color(0x6682B8B2),
);

/// All palettes, in display order.
const List<AstraPalette> astraPalettes = [
  astraLumaPink,
  astraSoftLilacMist,
  astraDustyRoseHaze,
  astraSageVeil,
  astraMutedSkyBloom,
  astraApricotCloud,
  astraBerrySand,
  astraSmokyTealAura,
];

/// Lookup by id, with a safe default.
AstraPalette astraPaletteFor(AstraThemeId id) =>
    astraPalettes.firstWhere((p) => p.id == id, orElse: () => astraLumaPink);
