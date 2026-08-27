import 'package:flutter/material.dart';

import '../../domain/page_config.dart';

/// Pastel palette for the Create-Page module (soft, cozy, pink-accented).
class CpColors {
  CpColors._();
  static const bg = Color(0xFFF6F3EF);
  static const pink = Color(0xFFF6A8C0);
  static const pinkSoft = Color(0xFFF9D2DE);
  static const ink = Color(0xFF2C2730);
  static const muted = Color(0xFF8B8590);
  static const cardBorder = Color(0x14000000);
  static const sheet = Color(0xFFFFFFFF);
  static const line = Color(0xFFC3CADD);
  static const margin = Color(0xFFE79AA6);
}

/// Big, fixed pill-shaped primary action ("Yeni Sayfa Oluştur").
class CpPillButton extends StatelessWidget {
  const CpPillButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: CpColors.pink,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: CpColors.pink.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: CpColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The three-way "Özelleştir · Kâğıt · Şablonlar" segmented control.
class CpSegmentedControl extends StatelessWidget {
  const CpSegmentedControl({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final CreatePageTab current;
  final ValueChanged<CreatePageTab> onChanged;

  static const _labels = {
    CreatePageTab.customize: 'Özelleştir',
    CreatePageTab.paper: 'Kâğıt',
  };

  // Şablonlar tab removed by request — only Customize & Paper are offered.
  static const _tabs = [CreatePageTab.customize, CreatePageTab.paper];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFECE7E1),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(tab),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: current == tab ? CpColors.pink : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    _labels[tab]!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: current == tab ? CpColors.ink : CpColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Left-aligned bold section header ("Diary", "Temel kâğıt 1"…).
class CpSectionHeader extends StatelessWidget {
  const CpSectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: CpColors.ink,
        ),
      ),
    );
  }
}

/// A rounded, optionally-checked choice chip used by the toggle rows.
class CpChoiceChip extends StatelessWidget {
  const CpChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? CpColors.pinkSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? CpColors.pink : const Color(0x11000000),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: CpColors.ink),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: selected ? CpColors.ink : CpColors.muted,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 7),
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: CpColors.pink),
            ],
          ],
        ),
      ),
    );
  }
}

/// A round page-tint swatch (first entry is the "no colour" slash icon).
class CpColorDot extends StatelessWidget {
  const CpColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.isWheel = false,
  });

  final Color? color;
  final bool selected;
  final bool isWheel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.white,
          border: Border.all(
            color: selected ? CpColors.pink : const Color(0x22000000),
            width: selected ? 2.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: isWheel
            ? const Icon(Icons.palette_rounded, color: CpColors.pink, size: 24)
            : color == null
                ? const Icon(Icons.block_rounded,
                    color: CpColors.muted, size: 22)
                : (selected
                    ? const Icon(Icons.check_rounded,
                        color: CpColors.pink, size: 22)
                    : null),
      ),
    );
  }
}

/// ─── Live, layered page preview ────────────────────────────────────────────
/// Layers, bottom→top: background scene · colour tint · paper style · binding.
class PagePreview extends StatelessWidget {
  const PagePreview({
    super.key,
    required this.config,
    this.selected = false,
    this.showBorder = true,
  });

  final PageConfig config;
  final bool selected;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final spread = config.format == PageFormat.spread;
    final aspect = config.aspectRatio * (spread ? 2 : 1);
    return AspectRatio(
      aspectRatio: aspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: showBorder
              ? Border.all(
                  color: selected ? CpColors.pink : const Color(0x14000000),
                  width: selected ? 2.4 : 1,
                )
              : null,
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1) Background scene.
              if (config.background != null)
                DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: config.background!.gradient))
              else
                const ColoredBox(color: Color(0xFFF3F0EC)),
              // 2) Colour tint layer (inset a touch so the scene peeks around).
              Padding(
                padding: EdgeInsets.all(config.background == null ? 0 : 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      config.background == null ? 0 : 6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: config.color ?? CpColors.sheet),
                      // 3) Paper style + 4) binding, painted together.
                      CustomPaint(
                        painter: PaperPainter(
                          style: config.paperStyle,
                          binding: config.binding,
                          spread: spread,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the paper ruling (lines/grid/dots) and the binding (spiral/fold).
class PaperPainter extends CustomPainter {
  const PaperPainter({
    required this.style,
    required this.binding,
    required this.spread,
  });

  final PaperStyle style;
  final BindingStyle binding;
  final bool spread;

  @override
  void paint(Canvas canvas, Size size) {
    _paintRuling(canvas, size);
    _paintBinding(canvas, size);
  }

  void _paintRuling(Canvas canvas, Size size) {
    final line = Paint()
      ..color = CpColors.line.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    final gap = size.height / 20;

    switch (style) {
      case PaperStyle.blank:
        break;
      case PaperStyle.lined:
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), line);
        }
        break;
      case PaperStyle.linedMargin:
        for (var y = gap; y < size.height; y += gap) {
          canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), line);
        }
        canvas.drawLine(
          Offset(size.width * 0.16, 0),
          Offset(size.width * 0.16, size.height),
          Paint()
            ..color = CpColors.margin.withValues(alpha: 0.8)
            ..strokeWidth = 1.4,
        );
        break;
      case PaperStyle.grid:
        for (var y = gap; y < size.height; y += gap) {
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
        final dot = Paint()..color = CpColors.line;
        for (var y = gap; y < size.height; y += gap) {
          for (var x = gap; x < size.width; x += gap) {
            canvas.drawCircle(Offset(x, y), 0.9, dot);
          }
        }
        break;
    }
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
            ..color = const Color(0x22000000)
            ..strokeWidth = 1.4,
        );
        break;
      case BindingStyle.spiralCenter:
        _spiral(canvas, Size(size.width, size.height), size.width / 2, true);
        break;
      case BindingStyle.spiralSide:
        _spiral(canvas, size, size.width * 0.08, false);
        break;
    }
  }

  void _spiral(Canvas canvas, Size size, double x, bool vertical) {
    const count = 13;
    final step = size.height / (count + 1);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB99B6B);
    final hole = Paint()..color = const Color(0x22000000);
    for (var i = 1; i <= count; i++) {
      final c = Offset(x, step * i);
      canvas.drawCircle(c, 3.4, hole);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 4.6),
        -1.2,
        3.4,
        false,
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PaperPainter old) =>
      old.style != style || old.binding != binding || old.spread != spread;
}

/// A stylized card preview for a [TemplateModel] (colored blocks + optional
/// spiral), standing in for real template artwork.
class TemplatePreview extends StatelessWidget {
  const TemplatePreview({
    super.key,
    required this.template,
    this.selected = false,
  });

  final TemplateModel template;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.7,
      child: Container(
        decoration: BoxDecoration(
          color: template.color ?? Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? CpColors.pink : const Color(0x11000000),
            width: selected ? 2.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: PaperPainter(
                style: template.paperStyle,
                binding: template.binding,
                spread: false,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                template.binding == BindingStyle.spiralSide ? 20 : 12,
                12,
                12,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CpColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final a in template.accents) ...[
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: a,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                  const Spacer(),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                right: 6,
                top: 6,
                child: Icon(Icons.check_circle_rounded,
                    color: CpColors.pink, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
