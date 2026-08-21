import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../data/special_day.dart';
import '../providers/special_days_providers.dart';

/// "Özel Günler" — the user's birthdays, anniversaries and other yearly dates.
/// Each one is marked on the calendar and gets a gentle annual notification.
class SpecialDaysScreen extends ConsumerStatefulWidget {
  const SpecialDaysScreen({super.key});

  @override
  ConsumerState<SpecialDaysScreen> createState() => _SpecialDaysScreenState();
}

class _SpecialDaysScreenState extends ConsumerState<SpecialDaysScreen> {
  @override
  void initState() {
    super.initState();
    // Re-arm every special day's yearly notification when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      ref.read(specialDaysProvider.notifier).rearm(isTr: isTr);
    });
  }

  String _formatted(SpecialDay d, String localeStr) {
    // Use a leap year so 29 Feb formats correctly.
    final date = DateTime(2000, d.month, d.day);
    return DateFormat('d MMMM', localeStr).format(date);
  }

  Future<void> _addSpecialDay(bool isTr, bool isDark, Color primary) async {
    final result = await showModalBottomSheet<_NewSpecialDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSpecialDaySheet(isTr: isTr, isDark: isDark, primary: primary),
    );
    if (result == null || !mounted) return;
    final day = SpecialDay(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: result.title,
      month: result.date.month,
      day: result.date.day,
      year: result.date.year,
    );
    await ref
        .read(specialDaysProvider.notifier)
        .addOrReplace(day, isTr: isTr);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isTr ? 'Özel gün eklendi ✨' : 'Special day added ✨')),
      );
    }
  }

  Future<void> _delete(SpecialDay d, bool isTr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTr ? 'Özel günü sil' : 'Delete special day'),
        content: Text(isTr
            ? '"${d.title}" silinsin mi?'
            : 'Delete "${d.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isTr ? 'Vazgeç' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isTr ? 'Sil' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(specialDaysProvider.notifier).remove(d.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final localeStr = Localizations.localeOf(context).toString();
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final days = ref.watch(specialDaysProvider);

    final sorted = [...days]
      ..sort((a, b) => a.monthDayKey.compareTo(b.monthDayKey));

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
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(isTr ? 'Özel Günler' : 'Special Days',
                        style: AstraKit.heading1(context, isDark, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    isTr
                        ? 'Doğum günleri ve senin için önemli tarihler — her yıl hatırlatalım.'
                        : 'Birthdays and dates that matter to you — reminded every year.',
                    style: AstraKit.mutedText(context, isDark, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: sorted.isEmpty
                      ? _EmptyState(isTr: isTr, isDark: isDark, primary: primary)
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final d = sorted[i];
                            return AstraEntrance(
                              delayMs: 60 * i,
                              child: _SpecialDayTile(
                                day: d,
                                dateLabel: _formatted(d, localeStr),
                                isDark: isDark,
                                primary: primary,
                                onDelete: () => _delete(d, isTr),
                              ),
                            );
                          },
                        ),
                ),
                AstraGoldButton(
                  isDark: isDark,
                  label: isTr ? 'Yeni özel gün ekle' : 'Add a special day',
                  icon: Icons.add_rounded,
                  onTap: () => _addSpecialDay(isTr, isDark, primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialDayTile extends StatelessWidget {
  const _SpecialDayTile({
    required this.day,
    required this.dateLabel,
    required this.isDark,
    required this.primary,
    required this.onDelete,
  });

  final SpecialDay day;
  final String dateLabel;
  final bool isDark;
  final Color primary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.16),
              border: Border.all(color: primary.withValues(alpha: 0.4)),
            ),
            child: Icon(
              day.isBirthday
                  ? Icons.cake_rounded
                  : Icons.celebration_rounded,
              size: 22,
              color: primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AstraKit.body(context, isDark,
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(dateLabel,
                    style: AstraKit.mutedText(context, isDark, fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: AstraKit.muted(context, isDark)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.isTr, required this.isDark, required this.primary});

  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_outlined,
              size: 48, color: primary.withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Text(
            isTr ? 'Henüz özel gün yok' : 'No special days yet',
            style: AstraKit.body(context, isDark,
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isTr
                  ? 'Doğum günleri ve önemli tarihleri ekle; her yıl hatırlatalım.'
                  : 'Add birthdays and important dates; we\'ll remind you every year.',
              textAlign: TextAlign.center,
              style: AstraKit.mutedText(context, isDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Result of the add-sheet.
class _NewSpecialDay {
  const _NewSpecialDay(this.title, this.date);
  final String title;
  final DateTime date;
}

class _AddSpecialDaySheet extends StatefulWidget {
  const _AddSpecialDaySheet(
      {required this.isTr, required this.isDark, required this.primary});

  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  State<_AddSpecialDaySheet> createState() => _AddSpecialDaySheetState();
}

class _AddSpecialDaySheetState extends State<_AddSpecialDaySheet> {
  final _titleController = TextEditingController();
  DateTime? _date;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = widget.isTr;
    final isDark = widget.isDark;
    final primary = widget.primary;
    final localeStr = Localizations.localeOf(context).toString();
    final canSave =
        _titleController.text.trim().isNotEmpty && _date != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1430) : const Color(0xFFFFF7FB),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(isTr ? 'Yeni özel gün' : 'New special day',
                style: AstraKit.heading2(context, isDark, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              style: AstraKit.body(context, isDark, fontSize: 15),
              decoration: InputDecoration(
                hintText: isTr
                    ? 'Örn. Annemin doğum günü'
                    : 'e.g. Mom\'s birthday',
                hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14),
                filled: true,
                fillColor: primary.withValues(alpha: 0.08),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: primary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: primary.withValues(alpha: 0.7)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded, size: 20, color: primary),
                    const SizedBox(width: 12),
                    Text(
                      _date == null
                          ? (isTr ? 'Tarih seç' : 'Pick a date')
                          : DateFormat('d MMMM', localeStr).format(_date!),
                      style: AstraKit.body(context, isDark, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AstraGoldButton(
              isDark: isDark,
              label: isTr ? 'Kaydet' : 'Save',
              icon: Icons.check_rounded,
              enabled: canSave,
              onTap: () {
                if (!canSave) return;
                Navigator.of(context).pop(
                    _NewSpecialDay(_titleController.text.trim(), _date!));
              },
            ),
          ],
        ),
      ),
    );
  }
}
