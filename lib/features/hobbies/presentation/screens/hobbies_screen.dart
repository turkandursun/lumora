import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';
import '../../../special_days/presentation/providers/special_days_providers.dart';
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
  (
    'volunteering',
    'Gönüllülük',
    'Volunteering',
    Icons.volunteer_activism_rounded
  ),
  ('shopping', 'Alışveriş', 'Shopping', Icons.shopping_bag_rounded),
  ('makeup', 'Makyaj', 'Makeup', Icons.face_retouching_natural_rounded),
  ('skincare', 'Cilt bakımı', 'Skincare', Icons.spa_rounded),
  ('fishing', 'Balık tutma', 'Fishing', Icons.set_meal_rounded),
  ('cars', 'Arabalar', 'Cars', Icons.directions_car_rounded),
];

/// Emoji shown inside each hobby bubble, keyed by preset id. Custom hobbies
/// fall back to a sparkle.
const Map<String, String> _hobbyEmoji = {
  'reading': '📚', 'writing': '✍️', 'music': '🎵', 'singing': '🎤',
  'painting': '🎨', 'drawing': '✏️', 'photography': '📷', 'dancing': '💃',
  'cooking': '🍳', 'baking': '🧁', 'gardening': '🌷', 'plants': '🪴',
  'yoga': '🧘', 'running': '🏃', 'walking': '🚶', 'cycling': '🚴',
  'swimming': '🏊', 'gym': '🏋️', 'football': '⚽', 'basketball': '🏀',
  'tennis': '🎾', 'hiking': '🥾', 'camping': '🏕️', 'travel': '✈️',
  'movies': '🎬', 'series': '📺', 'gaming': '🎮', 'coding': '💻',
  'chess': '♟️', 'puzzle': '🧩', 'knitting': '🧶', 'coffee': '☕',
  'tea': '🍵', 'pets': '🐾', 'astronomy': '🌙', 'languages': '🗣️',
  'volunteering': '🤝', 'shopping': '🛍️', 'makeup': '💄', 'skincare': '🧴',
  'fishing': '🎣', 'cars': '🚗',
};

String _emojiFor(String id) => _hobbyEmoji[id] ?? '✨';

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
  const HobbiesScreen({
    super.key,
    this.onboarding = false,
    this.registrationIntent,
  });

  /// When true, shown once during fresh registration: no back button, and a
  /// "Continue" button that hands off to LUMA's first welcome.
  final bool onboarding;
  final FreshRegistrationIntent? registrationIntent;

  @override
  ConsumerState<HobbiesScreen> createState() => _HobbiesScreenState();
}

class _HobbiesScreenState extends ConsumerState<HobbiesScreen> {
  final _customController = TextEditingController();

  // During onboarding we ask the birthday on a first step, right before the
  // hobby picker. Once answered (or skipped) we reveal the hobbies content.
  bool _birthdayDone = false;
  DateTime? _birthday;

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

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _saveBirthdayAndContinue(bool isTr) async {
    final date = _birthday;
    if (date != null) {
      await ref.read(specialDaysProvider.notifier).setBirthday(
            month: date.month,
            day: date.day,
            year: date.year,
            title: AppLocalizations.of(context).specialDayMyBirthday,
            isTr: isTr,
          );
    }
    if (mounted) setState(() => _birthdayDone = true);
  }

  Widget _buildBirthdayStep(
      BuildContext context, bool isTr, bool isDark, Color primary) {
    final localeStr = Localizations.localeOf(context).toString();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Icon(Icons.cake_rounded, size: 46, color: primary),
                const SizedBox(height: 18),
                Text(
                  isTr ? 'Doğum günün ne zaman?' : 'When is your birthday?',
                  style: AstraKit.heading1(context, isDark, fontSize: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  isTr
                      ? 'Senin için özel bir gün. Her yıl seni hatırlayıp küçük bir kutlama hazırlayalım 🎂'
                      : 'A day that\'s all about you. We\'ll remember it every year with a little celebration 🎂',
                  style: AstraKit.mutedText(context, isDark, fontSize: 14),
                ),
                const SizedBox(height: 28),
                InkWell(
                  onTap: _pickBirthday,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, color: primary),
                        const SizedBox(width: 14),
                        Text(
                          _birthday == null
                              ? (isTr ? 'Tarih seç' : 'Pick a date')
                              : DateFormat('d MMMM yyyy', localeStr)
                                  .format(_birthday!),
                          style: AstraKit.body(context, isDark, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                AstraGoldButton(
                  isDark: isDark,
                  label: isTr ? 'Devam et' : 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  enabled: _birthday != null,
                  onTap: () => _saveBirthdayAndContinue(isTr),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _birthdayDone = true),
                    child: Text(
                      isTr ? 'Şimdilik geç' : 'Skip for now',
                      style:
                          AstraKit.mutedText(context, isDark, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    if (widget.onboarding && !_birthdayDone) {
      return _buildBirthdayStep(context, isTr, isDark, primary);
    }

    final selected = ref.watch(hobbiesProvider);

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
                      style: AstraKit.heading1(context, isDark, fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isTr
                      ? 'Sevdiğin hobilere dokun; birden fazla seçebilirsin.'
                      : 'Tap the hobbies you love; you can pick several.',
                  style: AstraKit.mutedText(context, isDark, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _HobbyBubbleCloud(
                    presets: _presets,
                    selected: selected,
                    isTr: isTr,
                    isDark: isDark,
                    primary: primary,
                    onToggle: (id) =>
                        ref.read(hobbiesProvider.notifier).toggle(id),
                  ),
                ),
                _PicksBar(
                  selected: selected,
                  isTr: isTr,
                  isDark: isDark,
                  primary: primary,
                  onRemove: (id) =>
                      ref.read(hobbiesProvider.notifier).remove(id),
                ),
                const SizedBox(height: 10),
                _CustomAddRow(
                  isTr: isTr,
                  isDark: isDark,
                  primary: primary,
                  controller: _customController,
                  onAdd: _addCustom,
                ),
                if (widget.onboarding) ...[
                  const SizedBox(height: 12),
                  AstraGoldButton(
                    isDark: isDark,
                    label: isTr ? 'Devam et' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onTap: _finishOnboarding,
                  ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    if (!mounted) return;
    final current = widget.registrationIntent;
    if (current == null) {
      context.go(AuthFlowRoutes.home);
      return;
    }
    try {
      final next = await registrationFlowStore.advance(
        current,
        RegistrationStep.firstLumaGreeting,
      );
      if (!mounted) return;
      context.go(
        AuthFlowRoutes.afterSignupHobbies,
        extra: LumaGreetingRouteData(
          variant: LumaGreetingVariant.postSignup,
          registrationIntent: next,
        ),
      );
    } on RegistrationIntentMismatchException {
      if (mounted) context.go(AuthFlowRoutes.home);
    }
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
            style: AstraKit.body(context, isDark,
                fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText:
                  isTr ? 'Başka bir hobi ekle...' : 'Add another hobby...',
              hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14),
              filled: true,
              fillColor:
                  isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        AstraGoldButton(
            isDark: isDark,
            label: isTr ? 'Ekle' : 'Add',
            expand: false,
            onTap: onAdd),
      ],
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip(
      {required this.label,
      required this.isDark,
      required this.primary,
      required this.onRemove});

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
          Text(label,
              style: AstraKit.body(context, isDark,
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Icon(Icons.close_rounded,
                size: 16, color: AstraKit.muted(context, isDark)),
          ),
        ],
      ),
    );
  }
}

/// A paginated cloud of circular hobby "bubbles" (emoji + label), grouped into
/// pages of [_perPage] with a bottom pager (arrows + dots). Selected bubbles
/// fill with the active palette colour.
class _HobbyBubbleCloud extends StatefulWidget {
  const _HobbyBubbleCloud({
    required this.presets,
    required this.selected,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onToggle,
  });

  final List<(String, String, String, IconData)> presets;
  final Set<String> selected;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onToggle;

  @override
  State<_HobbyBubbleCloud> createState() => _HobbyBubbleCloudState();
}

class _HobbyBubbleCloudState extends State<_HobbyBubbleCloud> {
  static const _perPage = 12;
  final _controller = PageController();
  int _page = 0;

  int get _pageCount => (widget.presets.length / _perPage).ceil();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = math.max(0, math.min(_pageCount - 1, _page + delta));
    if (target == _page) return;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: _pageCount,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * _perPage;
              final end = math.min(start + _perPage, widget.presets.length);
              return _BubblePage(
                items: widget.presets.sublist(start, end),
                selected: widget.selected,
                isTr: widget.isTr,
                isDark: widget.isDark,
                primary: widget.primary,
                onToggle: widget.onToggle,
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        _Pager(
          current: _page,
          count: _pageCount,
          isDark: widget.isDark,
          primary: widget.primary,
          onPrev: () => _go(-1),
          onNext: () => _go(1),
        ),
      ],
    );
  }
}

/// One page of the bubble cloud: rows of three, alternate rows nudged sideways
/// for a soft, non-grid honeycomb cluster.
class _BubblePage extends StatelessWidget {
  const _BubblePage({
    required this.items,
    required this.selected,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onToggle,
  });

  final List<(String, String, String, IconData)> items;
  final Set<String> selected;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final rows = <List<(String, String, String, IconData)>>[];
    for (var i = 0; i < items.length; i += 3) {
      rows.add(items.sublist(i, math.min(i + 3, items.length)));
    }
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (r, row) in rows.indexed)
              Padding(
                // Alternate rows indent to opposite sides for a soft, non-grid
                // honeycomb cluster (layout-affecting so it never clips).
                padding: EdgeInsets.only(
                  top: 6,
                  bottom: 6,
                  left: r.isOdd ? 46 : 0,
                  right: r.isOdd ? 0 : 46,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final p in row)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: _HobbyBubble(
                          emoji: _emojiFor(p.$1),
                          label: isTr ? p.$2 : p.$3,
                          selected: selected.contains(p.$1),
                          isDark: isDark,
                          primary: primary,
                          onTap: () => onToggle(p.$1),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single circular hobby bubble: emoji in a soft circle with its label below.
/// Selected → filled with the palette colour and gently enlarged.
class _HobbyBubble extends StatelessWidget {
  const _HobbyBubble({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        selected ? primary : (isDark ? const Color(0x3A2A2036) : Colors.white);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: selected ? 78 : 72,
              height: selected ? 78 : 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bubbleColor,
                border: Border.all(
                  color: selected ? primary : primary.withValues(alpha: 0.16),
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? primary.withValues(alpha: 0.32)
                        : Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                    blurRadius: selected ? 16 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AstraKit.body(
                context,
                isDark,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom pager for the bubble cloud: prev/next circle arrows flanking a row of
/// dots (the current page shown as a wider pill).
class _Pager extends StatelessWidget {
  const _Pager({
    required this.current,
    required this.count,
    required this.isDark,
    required this.primary,
    required this.onPrev,
    required this.onNext,
  });

  final int current;
  final int count;
  final bool isDark;
  final Color primary;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final atStart = current == 0;
    final atEnd = current >= count - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _arrow(Icons.chevron_left_rounded, atStart ? null : onPrev),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == current ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color:
                      i == current ? primary : primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        _arrow(Icons.chevron_right_rounded, atEnd ? null : onNext),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0x3A2A2036) : Colors.white,
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: primary, size: 24),
        ),
      ),
    );
  }
}

/// A single horizontal strip of the user's current picks (including custom
/// hobbies), each removable — hidden entirely when nothing is selected.
class _PicksBar extends StatelessWidget {
  const _PicksBar({
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
    if (selected.isEmpty) return const SizedBox.shrink();
    final ids = selected.toList();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: ids.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => _SelectedChip(
            label: _labelFor(ids[i], isTr),
            isDark: isDark,
            primary: primary,
            onRemove: () => onRemove(ids[i]),
          ),
        ),
      ),
    );
  }
}
