import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../data/activity_repository.dart';
import '../providers/activity_providers.dart';

/// (id, Turkish, English, icon) — the activities a user can pick from.
const List<(String, String, String, IconData)> _activityOptions = [
  ('walk', 'Yürüyüş', 'Walk', Icons.directions_walk_rounded),
  ('exercise', 'Spor', 'Exercise', Icons.fitness_center_rounded),
  ('journal', 'Günlük yazdım', 'Journaled', Icons.edit_note_rounded),
  ('read', 'Kitap okudum', 'Read', Icons.menu_book_rounded),
  ('meditate', 'Meditasyon', 'Meditated', Icons.self_improvement_rounded),
  ('friend', 'Arkadaşımla buluştum', 'Met a friend', Icons.people_rounded),
  ('cook', 'Yemek yaptım', 'Cooked', Icons.restaurant_rounded),
  ('clean', 'Temizlik', 'Cleaned', Icons.cleaning_services_rounded),
  ('work', 'Çalıştım / ders', 'Worked / studied', Icons.work_rounded),
  ('rest', 'Dinlendim', 'Rested', Icons.weekend_rounded),
  ('nature', 'Doğada vakit', 'Nature time', Icons.park_rounded),
  ('music', 'Müzik dinledim', 'Music', Icons.music_note_rounded),
  ('watch', 'Film / dizi', 'Watched', Icons.movie_rounded),
  ('selfcare', 'Öz bakım', 'Self-care', Icons.spa_rounded),
  ('family', 'Aile vakti', 'Family time', Icons.family_restroom_rounded),
  ('cry', 'Ağladım', 'Cried', Icons.sentiment_dissatisfied_rounded),
  ('laugh', 'Güldüm', 'Laughed', Icons.sentiment_very_satisfied_rounded),
  ('sleep', 'İyi uyudum', 'Slept well', Icons.bedtime_rounded),
];

String _activityLabel(String id, bool isTr) {
  for (final o in _activityOptions) {
    if (o.$1 == id) return isTr ? o.$2 : o.$3;
  }
  return id;
}

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  final Set<String> _selected = {};
  String? _activityPhotoPath;

  Future<XFile?> _pickImage() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: SakuraHomePalette.cream,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: SakuraHomePalette.blossomPink),
              title: Text(isTr ? 'Galeriden seç' : 'Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: SakuraHomePalette.blossomPink),
              title: Text(isTr ? 'Fotoğraf çek' : 'Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    try {
      return await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 82);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickActivityPhoto() async {
    final picked = await _pickImage();
    if (picked == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'activity_photos'));
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final dest = p.join(photosDir.path,
          'act_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}');
      await File(picked.path).copy(dest);
      if (!mounted) return;
      setState(() => _activityPhotoPath = dest);
    } catch (_) {}
  }

  Future<void> _saveActivity() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final labels = _selected.map((id) => _activityLabel(id, isTr)).toList();
    final text = labels.join(', ');
    if (text.isEmpty && _activityPhotoPath == null) return;

    await ref.read(activitiesProvider.notifier).add(Activity(
          id: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now(),
          text: text,
          photoPath: _activityPhotoPath,
        ));
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _activityPhotoPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isTr ? 'Kaydedildi 🌸' : 'Saved 🌸')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final locale = Localizations.localeOf(context).languageCode;
    final activities = ref.watch(activitiesProvider);

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
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: SakuraHomePalette.textDeep),
                  ),
                  Text(
                    isTr ? 'Etkinliklerim' : 'My activities',
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
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTr ? 'Bugün ne yaptın?' : 'What did you do today?',
                            style: AppTheme.displayFont(
                                fontSize: 16, color: SakuraHomePalette.textDeep),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isTr
                                ? 'Yaptıklarını seç (bunlar sadece sana özel).'
                                : 'Pick what you did (these stay private to you).',
                            style: AppTheme.bodyFont(
                                fontSize: 12, color: SakuraHomePalette.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final o in _activityOptions)
                                _OptionChip(
                                  icon: o.$4,
                                  label: isTr ? o.$2 : o.$3,
                                  selected: _selected.contains(o.$1),
                                  onTap: () => setState(() {
                                    if (!_selected.add(o.$1)) {
                                      _selected.remove(o.$1);
                                    }
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (_activityPhotoPath != null)
                            _PhotoPreview(
                              file: File(_activityPhotoPath!),
                              onRemove: () =>
                                  setState(() => _activityPhotoPath = null),
                            )
                          else
                            _photoButton(isTr, _pickActivityPhoto),
                          const SizedBox(height: 14),
                          _filledButton(
                            label: isTr ? 'Kaydet' : 'Save',
                            onTap: _saveActivity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (activities.isNotEmpty) ...[
                      Text(
                        isTr ? 'Geçmiş' : 'History',
                        style: AppTheme.displayFont(
                            fontSize: 16, color: SakuraHomePalette.textDeep),
                      ),
                      const SizedBox(height: 8),
                      for (final a in activities)
                        _ActivityHistoryCard(
                          activity: a,
                          locale: locale,
                          onDelete: () =>
                              ref.read(activitiesProvider.notifier).remove(a.id),
                        ),
                    ],
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

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: SakuraHomePalette.cardWhite,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: SakuraHomePalette.branchMauve.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );

  Widget _photoButton(bool isTr, VoidCallback onTap, {String? label}) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: SakuraHomePalette.blossomPink,
          side: const BorderSide(color: SakuraHomePalette.blossomPink),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onPressed: onTap,
        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
        label: Text(
          label ?? (isTr ? 'Fotoğraf ekle' : 'Add a photo'),
          style: AppTheme.bodyFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SakuraHomePalette.blossomPink),
        ),
      );

  Widget _filledButton({
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) =>
      PremiumButton(
        label: label,
        icon: Icons.check_rounded,
        loading: loading,
        onPressed: onTap,
      );
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? SakuraHomePalette.blossomPink
                : SakuraHomePalette.lavender,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      selected ? Colors.white : SakuraHomePalette.blossomPink),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.bodyFont(
                  fontSize: 12.5,
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

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(file,
              width: double.infinity, height: 190, fit: BoxFit.cover),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
              child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({
    required this.activity,
    required this.locale,
    required this.onDelete,
  });

  final Activity activity;
  final String locale;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.photoPath != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.file(File(activity.photoPath!),
                  width: double.infinity, height: 180, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMMM yyyy · HH:mm', locale)
                            .format(activity.createdAt),
                        style: AppTheme.bodyFont(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: SakuraHomePalette.textMuted),
                      ),
                      if (activity.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          activity.text,
                          style: AppTheme.bodyFont(
                              fontSize: 14, color: SakuraHomePalette.textDeep),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20, color: SakuraHomePalette.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
