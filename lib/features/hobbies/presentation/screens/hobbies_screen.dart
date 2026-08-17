import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../providers/hobbies_providers.dart';

/// (id, Turkish label, English label, icon)
const List<(String, String, String, IconData)> _presets = [
  ('reading', 'Kitap okuma', 'Reading', Icons.menu_book_rounded),
  ('writing', 'Yazı yazma', 'Writing', Icons.edit_rounded),
  ('music', 'Müzik', 'Music', Icons.music_note_rounded),
  ('singing', 'Şarkı söyleme', 'Singing', Icons.mic_rounded),
  ('painting', 'Resim', 'Painting', Icons.palette_rounded),
  ('drawing', 'Çizim', 'Drawing', Icons.brush_rounded),
  ('photography', 'Fotoğraf', 'Photography', Icons.camera_alt_rounded),
  ('dancing', 'Dans', 'Dancing', Icons.music_video_rounded),
  ('cooking', 'Yemek yapma', 'Cooking', Icons.restaurant_rounded),
  ('baking', 'Pasta & kek', 'Baking', Icons.cake_rounded),
  ('gardening', 'Bahçe', 'Gardening', Icons.local_florist_rounded),
  ('plants', 'Bitkiler', 'Plants', Icons.eco_rounded),
  ('yoga', 'Yoga', 'Yoga', Icons.self_improvement_rounded),
  ('running', 'Koşu', 'Running', Icons.directions_run_rounded),
  ('walking', 'Yürüyüş', 'Walking', Icons.directions_walk_rounded),
  ('cycling', 'Bisiklet', 'Cycling', Icons.directions_bike_rounded),
  ('swimming', 'Yüzme', 'Swimming', Icons.pool_rounded),
  ('gym', 'Spor salonu', 'Gym', Icons.fitness_center_rounded),
  ('football', 'Futbol', 'Football', Icons.sports_soccer_rounded),
  ('basketball', 'Basketbol', 'Basketball', Icons.sports_basketball_rounded),
  ('tennis', 'Tenis', 'Tennis', Icons.sports_tennis_rounded),
  ('hiking', 'Doğa yürüyüşü', 'Hiking', Icons.hiking_rounded),
  ('camping', 'Kamp', 'Camping', Icons.forest_rounded),
  ('travel', 'Seyahat', 'Travel', Icons.flight_rounded),
  ('movies', 'Film', 'Movies', Icons.movie_rounded),
  ('series', 'Dizi', 'Series', Icons.live_tv_rounded),
  ('gaming', 'Oyun', 'Gaming', Icons.sports_esports_rounded),
  ('coding', 'Kodlama', 'Coding', Icons.code_rounded),
  ('chess', 'Satranç', 'Chess', Icons.grid_on_rounded),
  ('puzzle', 'Bulmaca', 'Puzzle', Icons.extension_rounded),
  ('knitting', 'Örgü', 'Knitting', Icons.checkroom_rounded),
  ('coffee', 'Kahve', 'Coffee', Icons.local_cafe_rounded),
  ('tea', 'Çay', 'Tea', Icons.emoji_food_beverage_rounded),
  ('pets', 'Evcil hayvan', 'Pets', Icons.pets_rounded),
  ('astronomy', 'Astronomi', 'Astronomy', Icons.nightlight_round),
  ('languages', 'Dil öğrenme', 'Languages', Icons.translate_rounded),
  ('volunteering', 'Gönüllülük', 'Volunteering', Icons.volunteer_activism_rounded),
  ('shopping', 'Alışveriş', 'Shopping', Icons.shopping_bag_rounded),
  ('makeup', 'Makyaj', 'Makeup', Icons.face_retouching_natural_rounded),
  ('skincare', 'Cilt bakımı', 'Skincare', Icons.spa_rounded),
  ('fishing', 'Balık tutma', 'Fishing', Icons.set_meal_rounded),
  ('cars', 'Arabalar', 'Cars', Icons.directions_car_rounded),
];

(String, String, String, IconData)? _presetById(String id) {
  for (final p in _presets) {
    if (p.$1 == id) return p;
  }
  return null;
}

String _labelFor(String id, bool isTr) {
  final p = _presetById(id);
  if (p == null) return id; // custom hobby: the typed text
  return isTr ? p.$2 : p.$3;
}

/// Public label lookup for a hobby id (used by the profile screen).
String hobbyLabel(String id, bool isTr) => _labelFor(id, isTr);

/// Public icon lookup; null for custom hobbies.
IconData? hobbyIcon(String id) => _presetById(id)?.$4;

class HobbiesScreen extends ConsumerStatefulWidget {
  const HobbiesScreen({super.key, this.onboarding = false});

  /// When true, shown once during fresh registration: no back button, and a
  /// "Continue" button that hands off to LUMA's first welcome.
  final bool onboarding;

  @override
  ConsumerState<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends ConsumerState<HobbiesScreen> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addCustom() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    ref.read(hobbiesProvider.notifier).add(text);
    _customController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final selected = ref.watch(hobbiesProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.onboarding)
                      const SizedBox(width: 8)
                    else
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      widget.onboarding
                          ? (isTr ? 'Hobilerini seç' : 'Pick your hobbies')
                          : (isTr ? 'Hobilerim' : 'My hobbies'),
                      style: AstraKit.heading1(isDark, fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        isTr
                            ? 'Sevdiğin hobileri seç; listede yoksa elle ekle.'
                            : 'Pick the hobbies you love; add your own if it isn\'t listed.',
                        style: AstraKit.mutedText(isDark, fontSize: 13.5),
                      ),
                      const SizedBox(height: 16),
                      _SelectedHobbiesSection(
                        selected: selected,
                        isTr: isTr,
                        isDark: isDark,
                        primary: primary,
                        onRemove: (id) =>
                            ref.read(hobbiesProvider.notifier).remove(id),
                      ),
                      _CustomAddRow(
                        isTr: isTr,
                        isDark: isDark,
                        primary: primary,
                        controller: _customController,
                        onAdd: _addCustom,
                      ),
                      const SizedBox(height: 20),
                      Text(isTr ? 'Hobiler' : 'Hobbies', style: AstraKit.heading2(isDark, fontSize: 15)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final (i, p) in _presets.indexed)
                            AstraEntrance(
                              key: ValueKey(p.$1),
                              index: i,
                              intervalMs: 30,
                              offset: 12,
                              scaleFrom: 0.8,
                              child: _HobbyChip(
                                icon: p.$4,
                                label: isTr ? p.$2 : p.$3,
                                selected: selected.contains(p.$1),
                                isDark: isDark,
                                primary: primary,
                                onTap: () => ref.read(hobbiesProvider.notifier).toggle(p.$1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.onboarding)
                        AstraGoldButton(
                          isDark: isDark,
                          label: isTr ? 'Devam et' : 'Continue',
                          icon: Icons.arrow_forward_rounded,
                          onTap: _finishOnboarding,
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _finishOnboarding() {
    if (!mounted) return;
    // Sign-up flow: the greeting (first welcome) hands off to the AI-rating
    // step, then the final "all set" screen, then Home.
    context.go(
      AuthFlowRoutes.afterSignupHobbies,
      extra: const {'first': true, 'next': AuthFlowRoutes.aiRating},
    );
  }
}

class _SelectedHobbiesSection extends StatelessWidget {
  const _SelectedHobbiesSection({
    required this.selected,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onRemove,
  });

  final Set<String> selected;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: selected.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Seçtiklerin' : 'Your picks',
                  style: AstraKit.heading2(isDark, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in selected)
                      _SelectedChip(
                        key: ValueKey('selected_$id'),
                        label: _labelFor(id, isTr),
                        isDark: isDark,
                        primary: primary,
                        onRemove: () => onRemove(id),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
    );
  }
}

class _CustomAddRow extends StatelessWidget {
  const _CustomAddRow({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.controller,
    required this.onAdd,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: isTr ? 'Başka bir hobi ekle...' : 'Add another hobby...',
              hintStyle: AstraKit.mutedText(isDark, fontSize: 14),
              filled: true,
              fillColor: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary.withValues(alpha: 0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AstraGoldButton(isDark: isDark, label: isTr ? 'Ekle' : 'Add', expand: false, onTap: onAdd),
      ],
    );
  }
}

class _HobbyChip extends StatelessWidget {
  const _HobbyChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.85) : (isDark ? const Color(0x33231845) : const Color(0x55FFF8EE)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? primary : primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AstraKit.body(isDark, fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({super.key, required this.label, required this.isDark, required this.primary, required this.onRemove});

  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AstraKit.body(isDark, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Icon(Icons.close_rounded, size: 16, color: AstraKit.muted(isDark)),
          ),
        ],
      ),
    );
  }
}
