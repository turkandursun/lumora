import 'dart:math';

import 'package:flutter/material.dart';

import 'vintage_palette.dart';

/// Aged-paper backdrop for the vintage first-touch screens: a warm cream
/// page with a soft edge vignette and code-drawn botanical branches tucked
/// into the corners. Lay content on top via [child].
class VintagePaperBackground extends StatelessWidget {
  const VintagePaperBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: VintagePalette.pageGradient,
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft aged vignette — darkens the page edges a touch, like a
          // sheet of paper that's browned unevenly over the years.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.15),
                radius: 1.15,
                colors: [Color(0x00000000), Color(0x1A6B5A33)],
                stops: [0.62, 1.0],
              ),
            ),
          ),
          // Botanical branches in two opposite corners for a framed,
          // pressed-flower feel.
          const Positioned(
            top: -6,
            right: -10,
            child: _BotanicalBranch(size: Size(190, 170)),
          ),
          Positioned(
            bottom: -12,
            left: -14,
            child: Transform.rotate(
              angle: pi,
              child: const _BotanicalBranch(size: Size(150, 140)),
            ),
          ),
          const Positioned(top: 120, left: 34, child: _VintageButterfly()),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// A curved branch with soft sage leaves and a few dusty-rose blossoms,
/// drawn in muted vintage tones.
class _BotanicalBranch extends StatelessWidget {
  const _BotanicalBranch({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(painter: _BotanicalBranchPainter()),
    );
  }
}

class _BotanicalBranchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final branchPaint = Paint()
      ..color = VintagePalette.sageDeep.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Main arcing stem sweeping in from the corner.
    final stem = Path()
      ..moveTo(w, h * 0.06)
      ..cubicTo(w * 0.72, h * 0.10, w * 0.60, h * 0.30, w * 0.44, h * 0.42)
      ..cubicTo(w * 0.30, h * 0.52, w * 0.20, h * 0.60, w * 0.06, h * 0.74);
    canvas.drawPath(stem, branchPaint);

    // A couple of small offshoot twigs.
    final twig1 = Path()
      ..moveTo(w * 0.60, h * 0.30)
      ..quadraticBezierTo(w * 0.66, h * 0.16, w * 0.80, h * 0.14);
    final twig2 = Path()
      ..moveTo(w * 0.30, h * 0.52)
      ..quadraticBezierTo(w * 0.20, h * 0.44, w * 0.14, h * 0.30);
    canvas.drawPath(twig1, branchPaint);
    canvas.drawPath(twig2, branchPaint);

    // Leaves along the stem.
    _leaf(canvas, Offset(w * 0.72, h * 0.16), 15, -0.7);
    _leaf(canvas, Offset(w * 0.52, h * 0.36), 17, -0.2);
    _leaf(canvas, Offset(w * 0.34, h * 0.50), 15, 0.4);
    _leaf(canvas, Offset(w * 0.18, h * 0.28), 13, -1.1);
    _leaf(canvas, Offset(w * 0.16, h * 0.64), 14, 0.9);

    // Blossoms clustered near the corner.
    _blossom(canvas, Offset(w * 0.86, h * 0.12), 8);
    _blossom(canvas, Offset(w * 0.66, h * 0.24), 7);
    _blossom(canvas, Offset(w * 0.46, h * 0.42), 6.5);
    _blossom(canvas, Offset(w * 0.80, h * 0.30), 5.5);
  }

  void _leaf(Canvas canvas, Offset center, double length, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final fill = Paint()
      ..color = VintagePalette.sage.withValues(alpha: 0.38);
    final vein = Paint()
      ..color = VintagePalette.sageDeep.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final leaf = Path()
      ..moveTo(0, -length)
      ..quadraticBezierTo(length * 0.55, 0, 0, length)
      ..quadraticBezierTo(-length * 0.55, 0, 0, -length)
      ..close();
    canvas.drawPath(leaf, fill);
    canvas.drawLine(Offset(0, -length), Offset(0, length), vein);
    canvas.restore();
  }

  void _blossom(Canvas canvas, Offset center, double petalRadius) {
    final petalPaint = Paint()
      ..color = VintagePalette.rosePetal.withValues(alpha: 0.7);
    for (var i = 0; i < 5; i++) {
      final angle = (pi * 2 / 5) * i;
      final petalCenter = Offset(
        center.dx + cos(angle) * petalRadius,
        center.dy + sin(angle) * petalRadius,
      );
      canvas.drawCircle(petalCenter, petalRadius * 0.62, petalPaint);
    }
    canvas.drawCircle(
      center,
      petalRadius * 0.42,
      Paint()..color = const Color(0xFFE9C9A0).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A small, faded vintage butterfly accent.
class _VintageButterfly extends StatelessWidget {
  const _VintageButterfly();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.2,
      child: SizedBox(
        width: 32,
        height: 26,
        child: CustomPaint(painter: _VintageButterflyPainter()),
      ),
    );
  }
}

class _VintageButterflyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wingFill = Paint()
      ..color = VintagePalette.rosePetal.withValues(alpha: 0.45);
    final wingStroke = Paint()
      ..color = VintagePalette.sageDeep.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final c = Offset(size.width / 2, size.height / 2);

    Path wing(double sx, double sy) => Path()
      ..moveTo(c.dx, c.dy - 2)
      ..cubicTo(c.dx + 15 * sx, c.dy - 17 * sy, c.dx + 19 * sx, c.dy + 2, c.dx, c.dy)
      ..close();
    Path lowerWing(double sx) => Path()
      ..moveTo(c.dx, c.dy)
      ..cubicTo(c.dx + 11 * sx, c.dy + 4, c.dx + 9 * sx, c.dy + 15, c.dx, c.dy + 4)
      ..close();

    for (final wg in [wing(-1, 1), wing(1, 1), lowerWing(-1), lowerWing(1)]) {
      canvas.drawPath(wg, wingFill);
      canvas.drawPath(wg, wingStroke);
    }
    final body = Paint()
      ..color = VintagePalette.inkSoft.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, c.dy - 7), Offset(c.dx, c.dy + 7), body);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A parchment card with a double hairline border — the raised sheet the
/// form sits on.
class VintageCard extends StatelessWidget {
  const VintageCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: VintagePalette.parchment,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: VintagePalette.line, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5A33).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      // Inner hairline for the classic double-ruled frame.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: VintagePalette.lineSoft.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: child,
      ),
    );
  }
}

/// A short ornamental rule with a small blossom at its centre — used under
/// titles ("Kayıt Ol").
class VintageOrnament extends StatelessWidget {
  const VintageOrnament({super.key, this.width = 150});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 18,
      child: CustomPaint(painter: _OrnamentPainter()),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final linePaint = Paint()
      ..color = VintagePalette.line
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const gap = 16.0;
    // Left and right rules with a small arrow tail.
    canvas.drawLine(Offset(0, midY), Offset(size.width / 2 - gap, midY), linePaint);
    canvas.drawLine(Offset(size.width / 2 + gap, midY), Offset(size.width, midY), linePaint);
    canvas.drawLine(
      Offset(size.width / 2 - gap, midY),
      Offset(size.width / 2 - gap - 5, midY - 3),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2 + gap, midY),
      Offset(size.width / 2 + gap + 5, midY - 3),
      linePaint,
    );
    // Centre blossom.
    final center = Offset(size.width / 2, midY);
    final petal = Paint()..color = VintagePalette.dustyRose.withValues(alpha: 0.85);
    for (var i = 0; i < 5; i++) {
      final a = (pi * 2 / 5) * i - pi / 2;
      canvas.drawCircle(
        Offset(center.dx + cos(a) * 4.5, center.dy + sin(a) * 4.5),
        2.8,
        petal,
      );
    }
    canvas.drawCircle(center, 2.0, Paint()..color = const Color(0xFFE9C9A0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A labelled divider ("YA DA") flanked by hairlines.
class VintageLabeledDivider extends StatelessWidget {
  const VintageLabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: VintagePalette.line.withValues(alpha: 0.7)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label.toUpperCase(), style: VintagePalette.overline()),
        ),
        line,
      ],
    );
  }
}

/// Sage-green pill button with an optional botanical flourish, matching the
/// vintage CTA in the design.
class VintageButton extends StatelessWidget {
  const VintageButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          colors: [VintagePalette.sage, VintagePalette.sageDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: VintagePalette.sageDeep.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(VintagePalette.parchment),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: VintagePalette.heading(
                          fontSize: 20,
                          color: VintagePalette.parchment,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.local_florist_outlined,
                        size: 16,
                        color: VintagePalette.parchment.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Shared vintage field decoration — cream fill, soft brown hairline that
/// warms to sage on focus, sepia icon and serif hint.
InputDecoration vintageFieldDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1.1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: VintagePalette.body(fontSize: 15, color: VintagePalette.inkMuted),
    prefixIcon: Icon(icon, color: VintagePalette.inkMuted, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: VintagePalette.parchmentField,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(VintagePalette.line),
    enabledBorder: border(VintagePalette.line),
    focusedBorder: border(VintagePalette.sage, 1.5),
    errorBorder: border(VintagePalette.dustyRose),
    focusedErrorBorder: border(VintagePalette.dustyRose, 1.5),
    errorStyle: VintagePalette.body(fontSize: 12, color: VintagePalette.dustyRose),
  );
}
