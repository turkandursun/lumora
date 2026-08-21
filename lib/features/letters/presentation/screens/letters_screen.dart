import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_notification_ids.dart';
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
  late DateTime _openAt = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(lettersProvider.notifier).refresh();
      if (!mounted) return;
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      _syncLetterNotifications(ref.read(lettersProvider), isTr);
    });
  }

  static int _letterNotifId(int letterId) =>
      reminderNotificationId('letter_$letterId');

  /// Keeps a "10 minutes before it opens" local notification armed for every
  /// letter whose open date is still in the future. Idempotent — rescheduling
  /// the same id just updates it, and past moments quietly no-op.
  void _syncLetterNotifications(List<Letter> letters, bool isTr) {
    for (final letter in letters) {
      final at = letter.openAt.subtract(const Duration(minutes: 10));
      final title =
          isTr ? '💌 Mektubun açılıyor' : '💌 Your letter opens soon';
      final hasTitle = letter.title.trim().isNotEmpty;
      final body = hasTitle
          ? (isTr
              ? '"${letter.title}" birazdan açılacak — 10 dakika kaldı.'
              : '"${letter.title}" opens soon — 10 minutes left.')
          : (isTr
              ? 'Geleceğe yazdığın mektup birazdan açılıyor.'
              : 'The letter you wrote to the future opens soon.');
      NotificationService.instance.scheduleOnceAt(
        id: _letterNotifId(letter.id),
        title: title,
        body: body,
        at: at,
      );
    }
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
        SnackBar(
            content: Text(
                isTr ? 'Önce mektubunu yaz.' : 'Write your letter first.')),
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
      SnackBar(
          content: Text(isTr ? 'Mektup mühürlendi 💌' : 'Letter sealed 💌')),
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
      NotificationService.instance.cancel(_letterNotifId(letter.id));
      await ref
          .read(lettersProvider.notifier)
          .delete(letter.id, supabaseId: letter.supabaseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isTr ? 'Mektup silindi' : 'Letter deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final locale = Localizations.localeOf(context).languageCode;
    final letters = ref.watch(lettersProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    // Re-arm the "10 minutes before" notification whenever letters change.
    ref.listen<List<Letter>>(lettersProvider, (previous, next) {
      _syncLetterNotifications(next, isTr);
    });

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
                    Text(isTr ? 'Geleceğe Mektup' : 'Letter to future self',
                        style:
                            AstraKit.heading1(context, isDark, fontSize: 20)),
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
                        Text(isTr ? 'Mektuplarım' : 'My letters',
                            style: AstraKit.heading2(context, isDark,
                                fontSize: 16)),
                      const SizedBox(height: 8),
                      // An unlocked letter's card morphs open (Reflectly-style
                      // container transform) into a full-screen reader, then
                      // shrinks back to the card on close. Locked letters stay
                      // a plain, non-opening card.
                      for (final letter in letters)
                        if (letter.isUnlocked)
                          AstraMorphContainer(
                            borderRadius: 18,
                            openBuilder: (_) => _LetterReaderPage(
                              letter: letter,
                              locale: locale,
                              isTr: isTr,
                              isDark: isDark,
                              primary: primary,
                            ),
                            closedBuilder: (context, open) => _LetterCard(
                              letter: letter,
                              locale: locale,
                              isTr: isTr,
                              isDark: isDark,
                              primary: primary,
                              onOpen: open,
                              onDelete: () => _confirmDelete(letter),
                            ),
                          )
                        else
                          _LetterCard(
                            letter: letter,
                            locale: locale,
                            isTr: isTr,
                            isDark: isDark,
                            primary: primary,
                            onOpen: () {},
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

  InputDecoration _decoration(BuildContext context, String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AstraKit.mutedText(context, isDark, fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
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
            isTr
                ? 'Gelecekteki kendine bir mektup yaz'
                : 'Write a letter to your future self',
            style: AstraKit.heading2(context, isDark, fontSize: 16),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            style: AstraKit.body(context, isDark,
                fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: _decoration(
                context, isTr ? 'Başlık (isteğe bağlı)' : 'Title (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            maxLines: 6,
            style: AstraKit.body(context, isDark,
                fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: primary,
            decoration: _decoration(context,
                isTr ? 'Sevgili gelecekteki ben...' : 'Dear future me...'),
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
                  Text(isTr ? 'Açılış: ' : 'Opens: ',
                      style: AstraKit.mutedText(context, isDark, fontSize: 13)),
                  Text(
                    DateFormat('d MMMM yyyy', locale).format(openAt),
                    style: AstraKit.body(context, isDark,
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_calendar_rounded,
                      size: 15, color: AstraKit.muted(context, isDark)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AstraGoldButton(
              isDark: isDark,
              label: isTr ? 'Mühürle' : 'Seal it',
              icon: Icons.lock_rounded,
              onTap: onSave),
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
                    unlocked
                        ? Icons.mark_email_read_rounded
                        : Icons.lock_rounded,
                    color: unlocked ? primary : AstraKit.muted(context, isDark),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AstraKit.body(context, isDark,
                                fontSize: 14.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          unlocked
                              ? (isTr ? 'Okumak için dokun' : 'Tap to read')
                              : (isTr
                                  ? '$openLabel tarihinde açılacak'
                                  : 'Opens on $openLabel'),
                          style:
                              AstraKit.mutedText(context, isDark, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (unlocked) ...[
                    Icon(Icons.chevron_right_rounded,
                        color: AstraKit.muted(context, isDark)),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: AstraKit.muted(context, isDark)),
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

/// Full-screen reader that an unlocked letter's list card morphs open into via
/// the shared [AstraMorphContainer] container transform. Replaces the old small
/// pop-up dialog with a calm, full-page reading surface that eases back to the
/// card on close.
class _LetterReaderPage extends StatelessWidget {
  const _LetterReaderPage({
    required this.letter,
    required this.locale,
    required this.isTr,
    required this.isDark,
    required this.primary,
  });

  final Letter letter;
  final String locale;
  final bool isTr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final hasTitle = letter.title.trim().isNotEmpty;
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
                    Expanded(
                      child: Text(
                        isTr ? 'Mektubun' : 'Your letter',
                        style: AstraKit.heading1(context, isDark, fontSize: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: AstraGlassCard(
                      isDark: isDark,
                      primaryColor: primary,
                      borderRadius: 24,
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasTitle) ...[
                            Text(letter.title,
                                style: AstraKit.heading2(context, isDark,
                                    fontSize: 21)),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Icon(Icons.mark_email_read_rounded,
                                  size: 16, color: primary),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('d MMMM yyyy', locale)
                                    .format(letter.createdAt),
                                style: AstraKit.mutedText(context, isDark,
                                    fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            letter.body,
                            style: AstraKit.body(context, isDark,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w500,
                                height: 1.6),
                          ),
                        ],
                      ),
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
}
