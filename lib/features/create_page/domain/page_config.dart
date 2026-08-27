import 'package:flutter/material.dart';

/// Which top tab of the "Sayfa Oluştur" flow is active.
enum CreatePageTab { customize, paper, templates }

/// Aspect / print size preset shown in the "Boyut" control.
enum PageSizePreset {
  a1('A1', 1 / 1.4142),
  ratio9x16('9:16', 9 / 16);

  const PageSizePreset(this.label, this.portraitAspect);

  /// width / height when portrait.
  final String label;
  final double portraitAspect;
}

/// Single page or a two-page (yan yana) spread.
enum PageFormat { single, spread }

enum PageOrientation { portrait, landscape }

/// The lines/grid drawn on the paper surface.
enum PaperStyle {
  blank('Boş'),
  lined('Çizgili'),
  grid('Kareli'),
  dotted('Noktalı'),
  checkered('Damalı'),
  linedMargin('Marjinli');

  const PaperStyle(this.label);
  final String label;
}

/// The book/binding treatment layered on top of the page.
enum BindingStyle {
  none('Boş'),
  foldCenter('Ortadan katlamalı'),
  spiralCenter('Ortadan spiralli'),
  spiralSide('Kenardan spiralli');

  const BindingStyle(this.label);
  final String label;
}

/// A soft illustrative scene that sits behind the page.
@immutable
class PageBackground {
  const PageBackground({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final List<Color> colors;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      );
}

/// The catalogue of preset background scenes (index-referenced by [PageConfig]).
const List<PageBackground> kPageBackgrounds = [
  PageBackground(
      id: 'beach', label: 'Sahil', colors: [Color(0xFFBFE3F5), Color(0xFFFCE9C8)]),
  PageBackground(
      id: 'autumn',
      label: 'Sonbahar',
      colors: [Color(0xFFF6D6A8), Color(0xFFE8B27E)]),
  PageBackground(
      id: 'winter', label: 'Kış', colors: [Color(0xFFE7F1FB), Color(0xFFF6E9F2)]),
  PageBackground(
      id: 'meadow',
      label: 'Çayır',
      colors: [Color(0xFFDDF3D8), Color(0xFFF3F7DE)]),
];

/// The soft page tint options (null = transparent / "Renk Yok").
const List<Color?> kPageColors = [
  null,
  Color(0xFFF3EDE7),
  Color(0xFFFBE7EC),
  Color(0xFFFDF0DE),
  Color(0xFFEFE7FB),
  Color(0xFFF3E9FB),
  Color(0xFFE4F0FB),
  Color(0xFFFFFFFF),
];

/// A ready-made page (Şablonlar / form pages) with a stylized preview.
@immutable
class TemplateModel {
  const TemplateModel({
    required this.id,
    required this.category,
    required this.title,
    required this.paperStyle,
    required this.binding,
    required this.accents,
    this.color,
  });

  final String id;
  final String category;
  final String title;
  final PaperStyle paperStyle;
  final BindingStyle binding;

  /// Colors used to paint the stylized preview blocks.
  final List<Color> accents;
  final Color? color;

  /// Applies this template onto a [PageConfig].
  PageConfig applyTo(PageConfig base) => base.copyWith(
        paperStyle: paperStyle,
        binding: binding,
        color: () => color,
        templateId: () => id,
      );
}

/// The full, serializable description of the page being built.
@immutable
class PageConfig {
  const PageConfig({
    this.size = PageSizePreset.ratio9x16,
    this.format = PageFormat.single,
    this.orientation = PageOrientation.portrait,
    this.paperStyle = PaperStyle.lined,
    this.color,
    this.binding = BindingStyle.none,
    this.backgroundIndex,
    this.templateId,
  });

  final PageSizePreset size;
  final PageFormat format;
  final PageOrientation orientation;
  final PaperStyle paperStyle;
  final Color? color;
  final BindingStyle binding;
  final int? backgroundIndex;
  final String? templateId;

  static const PageConfig initial = PageConfig();

  bool get isDefault => this == PageConfig.initial;

  PageBackground? get background =>
      backgroundIndex == null ? null : kPageBackgrounds[backgroundIndex!];

  /// width / height for the current size + orientation.
  double get aspectRatio {
    final portrait = size.portraitAspect;
    return orientation == PageOrientation.portrait ? portrait : 1 / portrait;
  }

  // A nullable-aware copyWith: pass a getter for fields that may be set to null.
  PageConfig copyWith({
    PageSizePreset? size,
    PageFormat? format,
    PageOrientation? orientation,
    PaperStyle? paperStyle,
    ValueGetter<Color?>? color,
    BindingStyle? binding,
    ValueGetter<int?>? backgroundIndex,
    ValueGetter<String?>? templateId,
  }) {
    return PageConfig(
      size: size ?? this.size,
      format: format ?? this.format,
      orientation: orientation ?? this.orientation,
      paperStyle: paperStyle ?? this.paperStyle,
      color: color != null ? color() : this.color,
      binding: binding ?? this.binding,
      backgroundIndex:
          backgroundIndex != null ? backgroundIndex() : this.backgroundIndex,
      templateId: templateId != null ? templateId() : this.templateId,
    );
  }

  static PageConfig fromJson(Map<String, dynamic> json) {
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((e) => e.name == name, orElse: () => fallback);
    Color? parseColor(Object? v) {
      if (v is! String || !v.startsWith('#')) return null;
      return Color(int.parse(v.substring(1), radix: 16));
    }

    final bgId = json['backgroundId'];
    final bgIndex =
        kPageBackgrounds.indexWhere((b) => b.id == bgId);
    return PageConfig(
      size: byName(PageSizePreset.values, json['size'], PageSizePreset.ratio9x16),
      format: byName(PageFormat.values, json['format'], PageFormat.single),
      orientation: byName(
          PageOrientation.values, json['orientation'], PageOrientation.portrait),
      paperStyle: byName(PaperStyle.values, json['paperStyle'], PaperStyle.blank),
      color: parseColor(json['color']),
      binding: byName(BindingStyle.values, json['binding'], BindingStyle.none),
      backgroundIndex: bgIndex < 0 ? null : bgIndex,
      templateId: json['templateId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'size': size.name,
        'format': format.name,
        'orientation': orientation.name,
        'paperStyle': paperStyle.name,
        'color': color == null
            ? null
            // ignore: deprecated_member_use
            : '#${color!.value.toRadixString(16).padLeft(8, '0')}',
        'binding': binding.name,
        'backgroundId': background?.id,
        'templateId': templateId,
      };

  @override
  bool operator ==(Object other) =>
      other is PageConfig &&
      other.size == size &&
      other.format == format &&
      other.orientation == orientation &&
      other.paperStyle == paperStyle &&
      other.color == color &&
      other.binding == binding &&
      other.backgroundIndex == backgroundIndex &&
      other.templateId == templateId;

  @override
  int get hashCode => Object.hash(size, format, orientation, paperStyle, color,
      binding, backgroundIndex, templateId);
}

/// Grouped, ready-made template catalogue used by the Şablonlar tab.
const List<TemplateModel> kTemplates = [
  TemplateModel(
      id: 'diary_scrap',
      category: 'Diary',
      title: 'My Diary',
      paperStyle: PaperStyle.blank,
      binding: BindingStyle.spiralSide,
      accents: [Color(0xFFEADBCB), Color(0xFFFFFFFF), Color(0xFFF3E4D3)],
      color: Color(0xFFF3EDE7)),
  TemplateModel(
      id: 'diary_lines',
      category: 'Diary',
      title: 'My Diary',
      paperStyle: PaperStyle.lined,
      binding: BindingStyle.spiralSide,
      accents: [Color(0xFFF3D9E0)],
      color: Color(0xFFFFFFFF)),
  TemplateModel(
      id: 'diary_blocks',
      category: 'Diary',
      title: 'My Diary',
      paperStyle: PaperStyle.grid,
      binding: BindingStyle.none,
      accents: [Color(0xFFE7DBF7), Color(0xFFFBE1EC), Color(0xFFFCEFCF)],
      color: Color(0xFFFFFFFF)),
  TemplateModel(
      id: 'shop_pastel',
      category: 'Shopping List',
      title: 'Shopping List',
      paperStyle: PaperStyle.blank,
      binding: BindingStyle.none,
      accents: [Color(0xFFFAD9A0), Color(0xFFCDECD8), Color(0xFFE0D6F5)],
      color: Color(0xFFFFFFFF)),
  TemplateModel(
      id: 'shop_grid',
      category: 'Shopping List',
      title: 'Shopping List',
      paperStyle: PaperStyle.blank,
      binding: BindingStyle.none,
      accents: [Color(0xFFF6D7DE)],
      color: Color(0xFFFDF7F8)),
  TemplateModel(
      id: 'shop_color',
      category: 'Shopping List',
      title: 'Shopping List',
      paperStyle: PaperStyle.blank,
      binding: BindingStyle.none,
      accents: [Color(0xFFF3C6DD), Color(0xFFBFE7DB), Color(0xFFCFE0F5)],
      color: Color(0xFFFFFFFF)),
  TemplateModel(
      id: 'routine_full',
      category: 'Daily routine',
      title: 'Daily Routine',
      paperStyle: PaperStyle.blank,
      binding: BindingStyle.spiralSide,
      accents: [Color(0xFFE7DFF6), Color(0xFFDDEBF7), Color(0xFFEFF3D8)],
      color: Color(0xFFFCF7EF)),
  TemplateModel(
      id: 'routine_hours',
      category: 'Daily routine',
      title: 'Daily Routine',
      paperStyle: PaperStyle.lined,
      binding: BindingStyle.spiralSide,
      accents: [Color(0xFFDDEBF7)],
      color: Color(0xFFFFFFFF)),
  TemplateModel(
      id: 'check_travel',
      category: 'Checklist',
      title: 'Travel Checklist',
      paperStyle: PaperStyle.blank,
      binding: BindingStyle.none,
      accents: [Color(0xFFF6D7E2), Color(0xFFF7E8CF)],
      color: Color(0xFFFFF8FA)),
  TemplateModel(
      id: 'check_grocery',
      category: 'Checklist',
      title: 'Grocery List',
      paperStyle: PaperStyle.lined,
      binding: BindingStyle.spiralSide,
      accents: [Color(0xFFE9E2D2)],
      color: Color(0xFFFFFFFF)),
];
