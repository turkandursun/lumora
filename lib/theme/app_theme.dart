import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'astra_design_tokens.dart';

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

  static ThemeData forPalette(
    AstraPalette palette, {
    Brightness brightness = Brightness.light,
  }) {
    final tokens = AstraThemeTokens.fromPalette(
      palette,
      brightness: brightness,
    );
    final appearance = tokens.palette;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: appearance.primary,
      brightness: brightness,
      primary: appearance.primary,
      secondary: appearance.secondary,
      surface: appearance.surfaceElevated,
      onPrimary: tokens.textOnAccent,
      onSurface: tokens.textSecondary,
    );

    final textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
        letterSpacing: 0.5,
      ),
      headlineSmall: TextStyle(color: tokens.textPrimary),
      titleLarge: TextStyle(color: tokens.textPrimary),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: tokens.textSecondary,
      ),
      titleSmall: TextStyle(color: tokens.textSecondary),
      bodyLarge: TextStyle(color: tokens.textSecondary),
      bodyMedium: TextStyle(fontSize: 14, color: tokens.textSecondary),
      bodySmall: TextStyle(color: tokens.textMuted),
      labelLarge: TextStyle(color: tokens.textPrimary),
      labelMedium: TextStyle(color: tokens.textSecondary),
      labelSmall: TextStyle(color: tokens.textMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appearance.surface,
      canvasColor: appearance.surface,
      extensions: [tokens],
      fontFamily: 'Roboto',
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: tokens.textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appearance.inputBackground,
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
          borderSide: BorderSide(color: appearance.softBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: appearance.activeAccent, width: 1.5),
        ),
        hintStyle: TextStyle(color: tokens.textMuted),
        labelStyle: TextStyle(color: tokens.textSecondary),
        prefixIconColor: tokens.textMuted,
        suffixIconColor: tokens.textMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appearance.buttonPrimary,
          foregroundColor: tokens.textOnAccent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
          shadowColor: appearance.focusGlow,
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
          backgroundColor: appearance.buttonPrimary,
          foregroundColor: tokens.textOnAccent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
          shadowColor: appearance.focusGlow,
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
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: appearance.softBorder, width: 1.2),
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
          foregroundColor: appearance.activeAccent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: appearance.cardBackground,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: appearance.dividerSoft,
      dividerTheme: DividerThemeData(color: appearance.dividerSoft),
      dialogTheme: DialogThemeData(
        backgroundColor: appearance.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: tokens.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: appearance.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: appearance.surfaceElevated,
        modalBarrierColor: Colors.black.withValues(alpha: 0.48),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appearance.cardBackground,
        indicatorColor: appearance.iconContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? appearance.bottomNavActive
                : appearance.bottomNavInactive,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: tokens.textSecondary),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: appearance.cardBackground,
        selectedItemColor: appearance.bottomNavActive,
        unselectedItemColor: appearance.bottomNavInactive,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: appearance.chipUnselected,
        selectedColor: appearance.chipSelected,
        side: BorderSide(color: appearance.softBorder),
        labelStyle: TextStyle(color: tokens.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? appearance.activeAccent
              : tokens.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? appearance.activeAccent.withValues(alpha: 0.38)
              : appearance.inputBackground,
        ),
        trackOutlineColor: WidgetStatePropertyAll(appearance.softBorder),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: appearance.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: appearance.iconContainer,
        headerForegroundColor: tokens.textPrimary,
        dayForegroundColor: WidgetStatePropertyAll(tokens.textSecondary),
        todayForegroundColor: WidgetStatePropertyAll(appearance.activeAccent),
        todayBorder: BorderSide(color: appearance.activeAccent),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: appearance.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: tokens.textSecondary),
      ),
      listTileTheme: ListTileThemeData(
        textColor: tokens.textSecondary,
        iconColor: appearance.activeAccent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: appearance.surfaceElevated,
        contentTextStyle: TextStyle(color: tokens.textPrimary),
      ),
      focusColor: appearance.focusGlow,
    );
  }

  static ThemeData get lightTheme => forPalette(astraSoftLilacMist);
}
