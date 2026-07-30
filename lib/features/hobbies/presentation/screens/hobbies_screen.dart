import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
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

  /// When true, shown once right after sign-in: no back button, and a
  /// "Continue" button that marks the prompt done and heads to Home.
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
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
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: SakuraHomePalette.textDeep),
                    ),
                  Text(
                    widget.onboarding
                        ? (isTr ? 'Hobilerini seç' : 'Pick your hobbies')
                        : (isTr ? 'Hobilerim' : 'My hobbies'),
                    style: AppTheme.displayFont(
                      fontSize: 22,
                      color: SakuraHomePalette.textDeep,
                    ),
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
                      style: AppTheme.bodyFont(
                        fontSize: 13.5,
                        color: SakuraHomePalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selected.isNotEmpty) ...[
                      Text(
                        isTr ? 'Seçtiklerin' : 'Your picks',
                        style: AppTheme.displayFont(
                          fontSize: 15,
                          color: SakuraHomePalette.textDeep,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in selected)
                            _SelectedChip(
                              label: _labelFor(id, isTr),
                              onRemove: () =>
                                  ref.read(hobbiesProvider.notifier).remove(id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    _CustomAddRow(
                      isTr: isTr,
                      controller: _customController,
                      onAdd: _addCustom,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isTr ? 'Hobiler' : 'Hobbies',
                      style: AppTheme.displayFont(
                        fontSize: 15,
                        color: SakuraHomePalette.textDeep,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final p in _presets)
                          _HobbyChip(
                            icon: p.$4,
                            label: isTr ? p.$2 : p.$3,
                            selected: selected.contains(p.$1),
                            onTap: () =>
                                ref.read(hobbiesProvider.notifier).toggle(p.$1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.onboarding)
                      PremiumButton(
                        label: isTr ? 'Devam et' : 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _finishOnboarding,
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
    context.go(AppRoutes.home);
  }
}

class _CustomAddRow extends StatelessWidget {
  const _CustomAddRow({
    required this.isTr,
    required this.controller,
    required this.onAdd,
  });

  final bool isTr;
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
            style: AppTheme.bodyFont(fontSize: 14, color: SakuraHomePalette.textDeep),
            cursorColor: SakuraHomePalette.blossomPink,
            decoration: InputDecoration(
              hintText: isTr ? 'Başka bir hobi ekle...' : 'Add another hobby...',
              hintStyle: AppTheme.bodyFont(
                fontSize: 14,
                color: SakuraHomePalette.textMuted,
              ),
              filled: true,
              fillColor: SakuraHomePalette.cardWhite,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        PremiumButton(
          label: isTr ? 'Ekle' : 'Add',
          expand: false,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _HobbyChip extends StatelessWidget {
  const _HobbyChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
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
            color: selected ? SakuraHomePalette.blossomPink : SakuraHomePalette.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? SakuraHomePalette.blossomPink
                  : SakuraHomePalette.branchMauve.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : SakuraHomePalette.blossomPink,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : SakuraHomePalette.textDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: SakuraHomePalette.blossomPink.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SakuraHomePalette.blossomPink.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.bodyFont(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const SizedBox(width: 4),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: SakuraHomePalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
