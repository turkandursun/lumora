import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers/astra_theme_provider.dart';

/// Dynamic ASTRA Glassmorphism Design System.
/// Supports both Moon (Mor alttonlu Ay Teması) and Sun (Sarı alttonlu Güneş Teması).
class AstraGlassTheme {
  // --- MOON THEME (Mor Alttonlu) ---
  static const Color moonPrimary = Color(0xFFA582F7);
  static const Color moonAccent = Color(0xFF7653D9);
  static const Color moonTextHeading = Color(0xFFF4EEFF);
  static const Color moonTextBody = Color(0xFF000000); // Solid sharp black text
  static const Color moonTextMuted = Color(0xFF555566);
  static const Color moonCardBorderLight = Color(0xFFEBDCFF);

  static const LinearGradient moonGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xEFF5EEFF),
      Color(0xEAE2FAFF),
      Color(0xEDF1EAFF),
    ],
  );

  static const LinearGradient moonBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEADBFF),
      Color(0xFFA582F7),
      Color(0x665434A5),
      Color(0xAAEBDCFF),
    ],
  );

  static const LinearGradient moonButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEADBFF),
      Color(0xFFA582F7),
      Color(0xFF7653D9),
    ],
  );

  // --- SUN THEME (Sarı Alttonlu) ---
  static const Color sunPrimary = Color(0xFFD4AF37);
  static const Color sunAccent = Color(0xFFB8860B);
  static const Color sunTextHeading = Color(0xFF1A1005);
  static const Color sunTextBody = Color(0xFF000000); // Solid sharp black text
  static const Color sunTextMuted = Color(0xFF665544);
  static const Color sunCardBorderLight = Color(0xFFFFEEAA);

  static const LinearGradient sunGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xEFFEFBEE),
      Color(0xEAFDF6E2),
      Color(0xEDFBF2DA),
    ],
  );

  static const LinearGradient sunBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFEEAA),
      Color(0xFFD4AF37),
      Color(0x66B8860B),
      Color(0xAAFFD700),
    ],
  );

  static const LinearGradient sunButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFEEAA),
      Color(0xFFD4AF37),
      Color(0xFFB8860B),
    ],
  );

  // Helpers driven by active theme mode
  static TextStyle titleFont(AstraThemeMode mode, {required double fontSize, FontWeight fontWeight = FontWeight.w600}) {
    final color = mode == AstraThemeMode.dark ? moonTextHeading : sunTextHeading;
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.3,
    );
  }

  static TextStyle bodyFont(AstraThemeMode mode, {required double fontSize, FontWeight fontWeight = FontWeight.w400, double? height}) {
    final color = mode == AstraThemeMode.dark ? moonTextBody : sunTextBody;
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle mutedFont(AstraThemeMode mode, {required double fontSize}) {
    final color = mode == AstraThemeMode.dark ? moonTextMuted : sunTextMuted;
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle uiFont(AstraThemeMode mode, {required double fontSize, FontWeight fontWeight = FontWeight.w600, Color? customColor}) {
    final color = customColor ?? (mode == AstraThemeMode.dark ? moonTextHeading : sunTextHeading);
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.3,
    );
  }
}

/// 3D Glassmorphic Card that seamlessly adapts to the active AstraThemeMode (Moon / Sun)
class AstraGlassCard extends StatelessWidget {
  const AstraGlassCard({
    super.key,
    required this.child,
    required this.mode,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24.0,
    this.blurSigma = 18.0,
    this.height,
    this.width,
  });

  final Widget child;
  final AstraThemeMode mode;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = mode == AstraThemeMode.dark;

    final glowColor = isDark
        ? AstraGlassTheme.moonPrimary.withValues(alpha: 0.22)
        : AstraGlassTheme.sunPrimary.withValues(alpha: 0.22);

    final fillGradient = isDark
        ? AstraGlassTheme.moonGlassGradient
        : AstraGlassTheme.sunGlassGradient;

    final borderGradient = isDark
        ? AstraGlassTheme.moonBorderGradient
        : AstraGlassTheme.sunBorderGradient;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 26,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: _AstraBorderPainter(
              borderRadius: borderRadius,
              borderWidth: 1.5,
              borderGradient: borderGradient,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: fillGradient,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AstraBorderPainter extends CustomPainter {
  _AstraBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
    required this.borderGradient,
  });

  final double borderRadius;
  final double borderWidth;
  final Gradient borderGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _AstraBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderGradient != borderGradient;
  }
}

/// Dynamic Background Wrapper loading user's chosen ASTRA theme image (Moon vs Sun)
/// with a soft blur filter & frosted veil overlay so it stays vivid yet completely non-tiring.
class DynamicAstraBackground extends StatelessWidget {
  const DynamicAstraBackground({
    super.key,
    required this.child,
    required this.mode,
  });

  final Widget child;
  final AstraThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final isDark = mode == AstraThemeMode.dark;
    final asset = isDark
        ? 'assets/images/astra_dark_plain.png'
        : 'assets/images/astra_sun_bg.png';

    return Container(
      color: isDark ? const Color(0xFF0F0B1A) : const Color(0xFFFFF8EC),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. User's Selected ASTRA Background Image Asset
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          // 2. Soft Blur Filter
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const SizedBox.expand(),
          ),

          // 3. Ambient Frosted Veil Overlay (Keeps eyes rested & content crystal readable)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0x77160F2C),
                        const Color(0xAA100A22),
                        const Color(0xF40B0718),
                      ]
                    : [
                        const Color(0xB8FFFBF3),
                        const Color(0xDDFCF3DF),
                        const Color(0xF4FAF0D4),
                      ],
              ),
            ),
          ),

          // 4. Foreground Content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
