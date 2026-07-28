import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme definition for Lumora — a soft purple & white,
/// calm/premium aesthetic inspired by Calm, Notion and Reflectly.
class AppTheme {
  AppTheme._();

  static const Color primaryPurple = Color(0xFF7C6AE6);
  static const Color deepPurple = Color(0xFF5A4FCF);
  static const Color softLavender = Color(0xFFF3F0FB);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2A2438);
  static const Color textSecondary = Color(0xFF8E88A0);

  // --- Premium surfaces (gradient hero screens: login/onboarding) ---
  static const Color gradientTop = Color(0xFF6E5DE3);
  static const Color gradientMid = Color(0xFFA79AF0);
  static const Color gradientBottom = Color(0xFFF5F2FC);
  static const Color blobPrimary = Color(0xFF9D8DF1);
  static const Color blobSecondary = Color(0xFFD9CFFB);
  static const Color glassSurface = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x59FFFFFF);
  static const Color glassHighlight = Color(0x14FFFFFF);
  static const Color glowShadow = Color(0x4D5A4FCF);
  static const Color onGradientText = Color(0xFFFFFFFF);
  static const Color onGradientTextMuted = Color(0xE6FFFFFF);

  /// Elegant serif for hero/display text on premium surfaces.
  static TextStyle displayFont({
    double fontSize = 40,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
    double letterSpacing = 0.2,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Clean geometric sans for body copy, fields and buttons.
  static TextStyle bodyFont({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = textPrimary,
    double letterSpacing = 0.1,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
      primary: primaryPurple,
      surface: backgroundWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundWhite,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softLavender,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
          shadowColor: glowShadow,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
          shadowColor: glowShadow,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: Color(0xFFE3DFF2), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPurple,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
