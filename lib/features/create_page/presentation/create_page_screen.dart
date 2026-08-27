import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/create_page_controller.dart';
import '../domain/page_config.dart';
import 'widgets/create_page_widgets.dart';

/// The "Sayfa Oluştur" module: pick a ready template, a basic paper, or build a
/// custom page from scratch with a live layered preview.
class CreatePageScreen extends ConsumerWidget {
  const CreatePageScreen({super.key, this.onPageCreated});

  /// Fired with the final [PageConfig] when the user taps "Yeni Sayfa Oluştur".
  final void Function(PageConfig config)? onPageCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPageControllerProvider);
    final controller = ref.read(createPageControllerProvider.notifier);

    return Scaffold(
      backgroundColor: CpColors.bg,
      appBar: AppBar(
        backgroundColor: CpColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CpColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Sayfa Oluştur',
          style: TextStyle(
              color: CpColors.ink, fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton(
              onPressed: state.isDirty ? controller.reset : null,
              style: TextButton.styleFrom(
                backgroundColor:
                    state.isDirty ? CpColors.pinkSoft : const Color(0xFFECE7E1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Sıfırla…',
                style: TextStyle(
                  color: state.isDirty ? CpColors.ink : CpColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: CpSegmentedControl(
              current: state.tab,
              onChanged: controller.setTab,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: state.tab.index,
              children: const [
                _CustomizeTab(),
                _PaperTab(),
                _TemplatesTab(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: CpPillButton(
                label: 'Yeni Sayfa Oluştur',
                onTap: () {
                  onPageCreated?.call(state.config);
                  Navigator.of(context).maybePop(state.config);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared "Boyut" dropdown + "Dikey/Yatay" toggle used by Paper & Templates.
class _SizeOrientationBar extends ConsumerWidget {
  const _SizeOrientationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(createPageControllerProvider).config;
    final controller = ref.read(createPageControllerProvider.notifier);
    return Row(
      children: [
        const Text('Boyut',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: CpColors.ink)),
        const SizedBox(width: 12),
        PopupMenuButton<PageSizePreset>(
          onSelected: controller.setSize,
          itemBuilder: (_) => [
            for (final s in PageSizePreset.values)
              PopupMenuItem(value: s, child: Text(s.label)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x14000000)),
            ),
            child: Row(
              children: [
                Text(config.size.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: CpColors.ink)),
                const SizedBox(width: 30),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: CpColors.muted),
              ],
            ),
          ),
        ),
        const Spacer(),
        _OrientationToggle(
          orientation: config.orientation,
          onChanged: controller.setOrientation,
        ),
      ],
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  const _OrientationToggle({required this.orientation, required this.onChanged});

  final PageOrientation orientation;
  final ValueChanged<PageOrientation> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(PageOrientation o, IconData icon) {
      final sel = orientation == o;
      return GestureDetector(
        onTap: () => onChanged(o),
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? CpColors.pink : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Icon(icon, size: 20, color: sel ? CpColors.pink : CpColors.muted),
        ),
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFECE7E1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(PageOrientation.portrait, Icons.crop_portrait_rounded),
              btn(PageOrientation.landscape, Icons.crop_landscape_rounded),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          orientation == PageOrientation.portrait ? 'Dikey' : 'Yatay',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: CpColors.muted),
        ),
      ],
    );
  }
}

/// ─── TAB 1 · Özelleştir ──────────────────────────────────────────────────
class _CustomizeTab extends ConsumerWidget {
  const _CustomizeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(createPageControllerProvider).config;
    final c = ref.read(createPageControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        // Live preview.
        Center(
          child: SizedBox(
            height: 240,
            child: PagePreview(config: config),
          ),
        ),
        const SizedBox(height: 8),

        const CpSectionHeader('Boyut & Biçim'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final s in PageSizePreset.values)
            CpChoiceChip(
                label: s.label,
                selected: config.size == s,
                onTap: () => c.setSize(s)),
          CpChoiceChip(
              label: 'Tek sayfa',
              selected: config.format == PageFormat.single,
              onTap: () => c.setFormat(PageFormat.single)),
          CpChoiceChip(
              label: 'Çift sayfa',
              selected: config.format == PageFormat.spread,
              onTap: () => c.setFormat(PageFormat.spread)),
        ]),

        const CpSectionHeader('Yön'),
        Wrap(spacing: 10, children: [
          CpChoiceChip(
              label: 'Dikey',
              icon: Icons.crop_portrait_rounded,
              selected: config.orientation == PageOrientation.portrait,
              onTap: () => c.setOrientation(PageOrientation.portrait)),
          CpChoiceChip(
              label: 'Yatay',
              icon: Icons.crop_landscape_rounded,
              selected: config.orientation == PageOrientation.landscape,
              onTap: () => c.setOrientation(PageOrientation.landscape)),
        ]),

        const CpSectionHeader('Kâğıt stili'),
        _HScroll(children: [
          for (final style in PaperStyle.values)
            _PaperSwatch(
              style: style,
              selected: config.paperStyle == style,
              onTap: () => c.setPaperStyle(style),
            ),
        ]),

        const CpSectionHeader('Renk'),
        _HScroll(children: [
          for (var i = 0; i < kPageColors.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CpColorDot(
                color: kPageColors[i],
                selected: config.color == kPageColors[i],
                onTap: () => c.setColor(kPageColors[i]),
              ),
            ),
          CpColorDot(color: null, isWheel: true, selected: false, onTap: () {}),
        ]),

        const CpSectionHeader('Kitap'),
        _HScroll(children: [
          for (final b in BindingStyle.values)
            _BindingSwatch(
              binding: b,
              selected: config.binding == b,
              onTap: () => c.setBinding(b),
            ),
        ]),

        const CpSectionHeader('Arka plan'),
        _HScroll(children: [
          _BgSwatch(
              gradient: null,
              selected: config.backgroundIndex == null,
              onTap: () => c.setBackground(null)),
          for (var i = 0; i < kPageBackgrounds.length; i++)
            _BgSwatch(
              gradient: kPageBackgrounds[i].gradient,
              selected: config.backgroundIndex == i,
              onTap: () => c.setBackground(i),
            ),
        ]),
      ],
    );
  }
}

/// ─── TAB 2 · Kâğıt ───────────────────────────────────────────────────────
class _PaperTab extends ConsumerWidget {
  const _PaperTab();

  static const _group1 = [PaperStyle.blank, PaperStyle.dotted, PaperStyle.lined];
  static const _group2 = [
    PaperStyle.grid,
    PaperStyle.checkered,
    PaperStyle.linedMargin
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(createPageControllerProvider).config;
    final c = ref.read(createPageControllerProvider.notifier);
    final forms =
        kTemplates.where((t) => t.category == 'Daily routine').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const _SizeOrientationBar(),
        const CpSectionHeader('Temel kâğıt 1'),
        _paperGrid(_group1, config, c),
        const CpSectionHeader('Temel kâğıt 2'),
        _paperGrid(_group2, config, c),
        const CpSectionHeader('Temel kâğıt 3'),
        _templateGrid(forms, config, c),
      ],
    );
  }

  Widget _paperGrid(
          List<PaperStyle> styles, PageConfig config, CreatePageController c) =>
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.7,
        children: [
          for (final s in styles)
            GestureDetector(
              onTap: () => c.setPaperStyle(s),
              child: PagePreview(
                config: PageConfig(
                    paperStyle: s, color: const Color(0xFFFFFDF7)),
                selected: config.templateId == null && config.paperStyle == s,
              ),
            ),
        ],
      );

  Widget _templateGrid(
          List<TemplateModel> items, PageConfig config, CreatePageController c) =>
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.7,
        children: [
          for (final t in items)
            GestureDetector(
              onTap: () => c.selectTemplate(t),
              child: TemplatePreview(
                  template: t, selected: config.templateId == t.id),
            ),
        ],
      );
}

/// ─── TAB 3 · Şablonlar ───────────────────────────────────────────────────
class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(createPageControllerProvider).config;
    final c = ref.read(createPageControllerProvider.notifier);

    // Preserve first-seen category order.
    final categories = <String>[];
    for (final t in kTemplates) {
      if (!categories.contains(t.category)) categories.add(t.category);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const _SizeOrientationBar(),
        for (final category in categories) ...[
          CpSectionHeader(category),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.7,
            children: [
              for (final t in kTemplates.where((t) => t.category == category))
                GestureDetector(
                  onTap: () => c.selectTemplate(t),
                  child: TemplatePreview(
                      template: t, selected: config.templateId == t.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A horizontally scrolling row of option tiles.
class _HScroll extends StatelessWidget {
  const _HScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: children,
      ),
    );
  }
}

class _PaperSwatch extends StatelessWidget {
  const _PaperSwatch(
      {required this.style, required this.selected, required this.onTap});

  final PaperStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 74,
              child: PagePreview(
                config: PageConfig(
                    paperStyle: style, color: const Color(0xFFFFFDF7)),
                selected: selected,
              ),
            ),
            const SizedBox(height: 4),
            Text(style.label,
                style: const TextStyle(fontSize: 11, color: CpColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _BindingSwatch extends StatelessWidget {
  const _BindingSwatch(
      {required this.binding, required this.selected, required this.onTap});

  final BindingStyle binding;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 64,
          height: 74,
          child: PagePreview(
            config: PageConfig(
                paperStyle: PaperStyle.blank,
                binding: binding,
                color: const Color(0xFFFFFDF7)),
            selected: selected,
          ),
        ),
      ),
    );
  }
}

class _BgSwatch extends StatelessWidget {
  const _BgSwatch(
      {required this.gradient, required this.selected, required this.onTap});

  final Gradient? gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 74,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? CpColors.pink : const Color(0x14000000),
            width: selected ? 2.4 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: gradient == null
            ? const Icon(Icons.block_rounded, color: CpColors.muted)
            : (selected
                ? const Icon(Icons.check_circle_rounded, color: CpColors.pink)
                : null),
      ),
    );
  }
}
