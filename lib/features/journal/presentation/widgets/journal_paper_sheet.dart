import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../create_page/domain/page_config.dart';
import '../providers/journal_page_config_provider.dart';
import 'journal_paper_surface.dart';

/// A theme-aware "Kağıdını Tasarla" sheet: pick the paper ruling, colour,
/// binding and background scene, with a live preview. All choices persist and
/// the journal is written on the resulting paper.
class JournalPaperSheet extends ConsumerWidget {
  const JournalPaperSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const JournalPaperSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final palette = AstraKit.palette(context);
    final primary = AstraKit.primary(context, isDark);
    final config = ref.watch(journalPageConfigProvider);
    final ctrl = ref.read(journalPageConfigProvider.notifier);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    Color blend(Color base, Color tint, double t) => Color.lerp(base, tint, t)!;
    final colorOptions = <Color?>[
      null,
      blend(palette.surface, primary, 0.14),
      blend(palette.surface, palette.secondary, 0.14),
      blend(palette.surface, palette.activeAccent, 0.10),
      palette.inputBackground,
    ];

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: primary.withValues(alpha: 0.3))),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AstraKit.muted(context, isDark).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(isTr ? 'Kağıdını Tasarla' : 'Design your paper',
                  style: AstraKit.heading2(context, isDark, fontSize: 18)),
              const SizedBox(height: 14),

              // Live preview.
              Center(
                child: SizedBox(
                  height: 150,
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primary.withValues(alpha: 0.3)),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: JournalPaperSurface(
                          config: config,
                          lineColor: primary.withValues(alpha: isDark ? 0.32 : 0.22),
                          defaultColor: palette.cardBackground,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _sectionLabel(context, isDark, isTr ? 'Kâğıt deseni' : 'Ruling'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in PaperStyle.values)
                  _chip(
                    context, isDark, primary,
                    label: _paperLabel(s, isTr),
                    selected: config.paperStyle == s,
                    onTap: () => ctrl.update(config.copyWith(
                        paperStyle: s, templateId: () => null)),
                  ),
              ]),
              const SizedBox(height: 16),

              _sectionLabel(context, isDark, isTr ? 'Renk' : 'Colour'),
              Wrap(spacing: 10, children: [
                for (final c in colorOptions)
                  _colorDot(
                    color: c ?? palette.cardBackground,
                    isNone: c == null,
                    selected: config.color == c,
                    primary: primary,
                    onTap: () => ctrl.update(config.copyWith(color: () => c)),
                  ),
              ]),
              const SizedBox(height: 16),

              _sectionLabel(context, isDark, isTr ? 'Cilt' : 'Binding'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final b in BindingStyle.values)
                  _chip(
                    context, isDark, primary,
                    label: _bindingLabel(b, isTr),
                    selected: config.binding == b,
                    onTap: () => ctrl.update(config.copyWith(binding: b)),
                  ),
              ]),
              const SizedBox(height: 16),

              _sectionLabel(context, isDark, isTr ? 'Arka plan' : 'Background'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _bgDot(
                  gradient: null,
                  selected: config.backgroundIndex == null,
                  primary: primary,
                  cardColor: palette.cardBackground,
                  onTap: () =>
                      ctrl.update(config.copyWith(backgroundIndex: () => null)),
                ),
                for (var i = 0; i < kPageBackgrounds.length; i++)
                  _bgDot(
                    gradient: kPageBackgrounds[i].gradient,
                    selected: config.backgroundIndex == i,
                    primary: primary,
                    cardColor: palette.cardBackground,
                    onTap: () =>
                        ctrl.update(config.copyWith(backgroundIndex: () => i)),
                  ),
              ]),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: AstraGoldButton(
                  isDark: isDark,
                  label: isTr ? 'Bu kâğıda yaz' : 'Write on this paper',
                  icon: Icons.check_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _paperLabel(PaperStyle s, bool isTr) {
    switch (s) {
      case PaperStyle.blank:
        return isTr ? 'Boş' : 'Blank';
      case PaperStyle.lined:
        return isTr ? 'Çizgili' : 'Lined';
      case PaperStyle.linedMargin:
        return isTr ? 'Marjinli' : 'Margin';
      case PaperStyle.grid:
        return isTr ? 'Kareli' : 'Grid';
      case PaperStyle.checkered:
        return isTr ? 'İnce kareli' : 'Fine grid';
      case PaperStyle.dotted:
        return isTr ? 'Noktalı' : 'Dotted';
    }
  }

  static String _bindingLabel(BindingStyle b, bool isTr) {
    switch (b) {
      case BindingStyle.none:
        return isTr ? 'Ciltsiz' : 'None';
      case BindingStyle.foldCenter:
        return isTr ? 'Ortadan katlı' : 'Fold';
      case BindingStyle.spiralCenter:
        return isTr ? 'Orta spiral' : 'Center spiral';
      case BindingStyle.spiralSide:
        return isTr ? 'Yan spiral' : 'Side spiral';
    }
  }

  Widget _sectionLabel(BuildContext context, bool isDark, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: AstraKit.body(context, isDark,
                fontSize: 13.5, fontWeight: FontWeight.w700)),
      );

  Widget _chip(
    BuildContext context,
    bool isDark,
    Color primary, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.85)
              : primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? primary : primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : primary,
          ),
        ),
      ),
    );
  }

  Widget _colorDot({
    required Color color,
    required bool isNone,
    required bool selected,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? primary : const Color(0x22000000),
            width: selected ? 2.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: isNone
            ? Icon(Icons.format_color_reset_rounded,
                size: 18, color: primary.withValues(alpha: 0.7))
            : (selected
                ? Icon(Icons.check_rounded, size: 18, color: primary)
                : null),
      ),
    );
  }

  Widget _bgDot({
    required Gradient? gradient,
    required bool selected,
    required Color primary,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 46,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? cardColor : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primary : const Color(0x22000000),
            width: selected ? 2.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: gradient == null
            ? Icon(Icons.block_rounded,
                size: 16, color: primary.withValues(alpha: 0.6))
            : (selected
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18)
                : null),
      ),
    );
  }
}
