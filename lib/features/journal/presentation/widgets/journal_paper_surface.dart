import 'package:flutter/material.dart';

import '../../../create_page/domain/page_config.dart';

/// Renders the user-designed paper (background scene · colour · ruling ·
/// binding) as a full-size writing surface. [child] (the TextField) is laid
/// over the paper. All ruling is drawn in the theme-supplied [lineColor].
class JournalPaperSurface extends StatelessWidget {
  const JournalPaperSurface({
    super.key,
    required this.config,
    required this.lineColor,
    required this.defaultColor,
    required this.child,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 6, 16, 10),
    this.lineGap = 32.0,
  });

  final PageConfig config;
  final Color lineColor;

  /// Theme-appropriate paper colour used when the config has no explicit tint
  /// (keeps text readable in both light and dark themes).
  final Color defaultColor;
  final Widget child;
  final EdgeInsets contentPadding;

  /// Row height — pass the same value as the TextField's line height so the
  /// letters sit on the ruling.
  final double lineGap;

  @override
  Widget build(BuildContext context) {
    final hasScene = config.background != null;
    final inset = hasScene ? 12.0 : 0.0;
    final extraLeft =
        config.binding == BindingStyle.spiralSide ? 16.0 : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasScene)
          DecoratedBox(
            decoration: BoxDecoration(gradient: config.background!.gradient),
          ),
        // Paper (colour + ruling + binding).
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(hasScene ? 10 : 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: config.color ?? defaultColor),
                  CustomPaint(
                    painter: JournalPaperPainter(
                      style: config.paperStyle,
                      binding: config.binding,
                      lineColor: lineColor,
                      gap: lineGap,
                      startY: contentPadding.top,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Writing content over the paper.
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              contentPadding.left + inset + extraLeft,
              contentPadding.top + inset,
              contentPadding.right + inset,
              contentPadding.bottom + inset,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Paints the paper ruling and binding for a [PageConfig], using the app's
/// active accent (passed as [lineColor]) so the paper matches the theme.
class JournalPaperPainter extends CustomPainter {
  const JournalPaperPainter({
    required this.style,
    required this.binding,
    required this.lineColor,
    this.gap = 32.0,
    this.startY = 0.0,
  });

  final PaperStyle style;
  final BindingStyle binding;
  final Color lineColor;

  /// Row height — matched to the TextField's line height so letters sit ON the
  /// lines, like a real notebook.
  final double gap;

  /// Y of the first ruling line (the bottom of the first text row) — matched to
  /// the writing content's top padding so text and lines line up exactly.
  final double startY;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    switch (style) {
      case PaperStyle.blank:
        break;
      case PaperStyle.lined:
        for (var y = startY + gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        break;
      case PaperStyle.linedMargin:
        for (var y = startY + gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        canvas.drawLine(
          Offset(size.width * 0.12, 0),
          Offset(size.width * 0.12, size.height),
          Paint()
            ..color = const Color(0x66E79AA6)
            ..strokeWidth = 1.4,
        );
        break;
      case PaperStyle.grid:
        for (var y = startY + gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = gap; x < size.width; x += gap) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        break;
      case PaperStyle.checkered:
        final g = gap * 0.6;
        for (var y = g; y < size.height; y += g) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = g; x < size.width; x += g) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
        break;
      case PaperStyle.dotted:
        final dot = Paint()..color = lineColor;
        for (var y = startY + gap; y < size.height; y += gap) {
          for (var x = gap; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 1, dot);
          }
        }
        break;
    }

    _paintBinding(canvas, size);
  }

  void _paintBinding(Canvas canvas, Size size) {
    switch (binding) {
      case BindingStyle.none:
        break;
      case BindingStyle.foldCenter:
        canvas.drawLine(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          Paint()
            ..color = lineColor.withValues(alpha: 0.5)
            ..strokeWidth = 1.4,
        );
        break;
      case BindingStyle.spiralCenter:
        _spiral(canvas, size, size.width / 2);
        break;
      case BindingStyle.spiralSide:
        _spiral(canvas, size, size.width * 0.06);
        break;
    }
  }

  void _spiral(Canvas canvas, Size size, double x) {
    const count = 14;
    final step = size.height / (count + 1);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB99B6B);
    final hole = Paint()..color = const Color(0x22000000);
    for (var i = 1; i <= count; i++) {
      final c = Offset(x, step * i);
      canvas.drawCircle(c, 3.2, hole);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 4.4),
        -1.2,
        3.4,
        false,
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JournalPaperPainter old) =>
      old.style != style ||
      old.binding != binding ||
      old.lineColor != lineColor;
}
