import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../data/letter_repository.dart';
import '../providers/letter_providers.dart';

class LettersScreen extends ConsumerStatefulWidget {
  const LettersScreen({super.key});

  @override
  ConsumerState<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends ConsumerState<LettersScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  late DateTime _openAt =
      DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lettersProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _openAt,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _openAt = picked);
  }

  Future<void> _save() async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTr ? 'Önce mektubunu yaz.' : 'Write your letter first.')),
      );
      return;
    }
    await ref.read(lettersProvider.notifier).add(
          title: _titleController.text,
          body: _bodyController.text,
          openAt: _openAt,
        );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _titleController.clear();
    _bodyController.clear();
    setState(() => _openAt = DateTime.now().add(const Duration(days: 30)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isTr ? 'Mektup mühürlendi 💌' : 'Letter sealed 💌')),
    );
  }

  Future<void> _confirmDelete(Letter letter) async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTr ? 'Mektubu Sil' : 'Delete Letter'),
        content: Text(
          isTr
              ? 'Bu mektubu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'
              : 'Are you sure you want to delete this letter? This action cannot be undone.',
        ),
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
      await ref.read(lettersProvider.notifier).delete(letter.id, supabaseId: letter.supabaseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Mektup silindi' : 'Letter deleted')),
        );
      }
    }
  }

  void _openLetter(Letter letter, String locale, bool isDark, Color primary) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: AstraGlassCard(
          isDark: isDark,
          primaryColor: primary,
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (letter.title.trim().isNotEmpty) ...[
                  Text(letter.title, style: AstraKit.heading2(isDark, fontSize: 19)),
                  const SizedBox(height: 8),
                ],
                Text(DateFormat('d MMMM yyyy', locale).format(letter.createdAt), style: AstraKit.mutedText(isDark, fontSize: 12)),
                const SizedBox(height: 14),
                Text(letter.body, style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w500, height: 1.5)),
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
    final locale = Localizations.localeOf(context).languageCode;
    final letters = ref.watch(lettersProvider);
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
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(isTr ? 'Geleceğe Mektup' : 'Letter to future self', style: AstraKit.heading1(isDark, fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _ComposeCard(
                        isTr: isTr,
                        isDark: isDark,
                        primary: primary,
                        locale: locale,
                        titleController: _titleController,
                        bodyController: _bodyController,
                        openAt: _openAt,
                        onPickDate: _pickDate,
                        onSave: _save,
                      ),
                      const SizedBox(height: 18),
                      if (letters.isNotEmpty)
                        Text(isTr ? 'Mektuplarım' : 'My letters', style: AstraKit.heading2(isDark, fontSize: 16)),
                      const SizedBox(height: 8),
                      for (final letter in letters)
                        _LetterCard(
                          letter: letter,
                          locale: locale,
                          isTr: isTr,
                          isDark: isDark,
                          primary: primary,
                          onOpen: () => _openLetter(letter, locale, isDark, primary),
                          onDelete: () => _confirmDelete(letter),
                        ),
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
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.locale,
    required this.titleController,
    required this.bodyController,
    required this.openAt,
    required this.onPickDate,
    required this.onSave,
  });

  final bool isTr;
  final bool isDark;
  final Color primary;
  final String locale;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final DateTime openAt;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
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
      );

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr ? 'Gelecekteki kendine bir mektup yaz' : 'Write a letter to your future self',
            style: AstraKit.heading2(isDark, fontSize: 16),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: _decoration(isTr ? 'Başlık (isteğe bağlı)' : 'Title (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            maxLines: 6,
            style: AstraKit.body(isDark, fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: _decoration(isTr ? 'Sevgili gelecekteki ben...' : 'Dear future me...'),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.lock_clock_rounded, size: 18, color: primary),
                  const SizedBox(width: 8),
                  Text(isTr ? 'Açılış: ' : 'Opens: ', style: AstraKit.mutedText(isDark, fontSize: 13)),
                  Text(
                    DateFormat('d MMMM yyyy', locale).format(openAt),
                    style: AstraKit.body(isDark, fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_calendar_rounded, size: 15, color: AstraKit.muted(isDark)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AstraGoldButton(isDark: isDark, label: isTr ? 'Mühürle' : 'Seal it', icon: Icons.lock_rounded, onTap: onSave),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.letter,
    required this.locale,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onOpen,
    required this.onDelete,
  });

  final Letter letter;
  final String locale;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unlocked = letter.isUnlocked;
    final openLabel = DateFormat('d MMMM yyyy', locale).format(letter.openAt);
    final title = letter.title.trim().isEmpty
        ? (isTr ? 'Başlıksız mektup' : 'Untitled letter')
        : letter.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: EdgeInsets.zero,
        borderRadius: 18,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: unlocked ? onOpen : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Icon(
                    unlocked ? Icons.mark_email_read_rounded : Icons.lock_rounded,
                    color: unlocked ? primary : AstraKit.muted(isDark),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AstraKit.body(isDark, fontSize: 14.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          unlocked
                              ? (isTr ? 'Okumak için dokun' : 'Tap to read')
                              : (isTr ? '$openLabel tarihinde açılacak' : 'Opens on $openLabel'),
                          style: AstraKit.mutedText(isDark, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (unlocked) ...[
                    Icon(Icons.chevron_right_rounded, color: AstraKit.muted(isDark)),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: AstraKit.muted(isDark)),
                    onPressed: onDelete,
                    tooltip: isTr ? 'Mektubu Sil' : 'Delete Letter',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
