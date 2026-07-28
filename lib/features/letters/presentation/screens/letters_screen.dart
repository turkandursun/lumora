import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/sakura_home_palette.dart';
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

  void _openLetter(Letter letter, String locale) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: SakuraHomePalette.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (letter.title.trim().isNotEmpty) ...[
                  Text(
                    letter.title,
                    style: AppTheme.displayFont(
                      fontSize: 19,
                      color: SakuraHomePalette.textDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  DateFormat('d MMMM yyyy', locale).format(letter.createdAt),
                  style: AppTheme.bodyFont(
                    fontSize: 12,
                    color: SakuraHomePalette.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  letter.body,
                  style: AppTheme.bodyFont(
                    fontSize: 15,
                    color: SakuraHomePalette.textDeep,
                  ).copyWith(height: 1.5),
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
    final locale = Localizations.localeOf(context).languageCode;
    final letters = ref.watch(lettersProvider);

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
                    isTr ? 'Geleceğe Mektup' : 'Letter to future self',
                    style: AppTheme.displayFont(
                      fontSize: 20,
                      color: SakuraHomePalette.textDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _ComposeCard(
                      isTr: isTr,
                      locale: locale,
                      titleController: _titleController,
                      bodyController: _bodyController,
                      openAt: _openAt,
                      onPickDate: _pickDate,
                      onSave: _save,
                    ),
                    const SizedBox(height: 18),
                    if (letters.isNotEmpty)
                      Text(
                        isTr ? 'Mektuplarım' : 'My letters',
                        style: AppTheme.displayFont(
                          fontSize: 16,
                          color: SakuraHomePalette.textDeep,
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final letter in letters)
                      _LetterCard(
                        letter: letter,
                        locale: locale,
                        isTr: isTr,
                        onOpen: () => _openLetter(letter, locale),
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
    required this.locale,
    required this.titleController,
    required this.bodyController,
    required this.openAt,
    required this.onPickDate,
    required this.onSave,
  });

  final bool isTr;
  final String locale;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final DateTime openAt;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyFont(
          fontSize: 14,
          color: SakuraHomePalette.textMuted,
        ),
        filled: true,
        fillColor: SakuraHomePalette.lavender,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr
                ? 'Gelecekteki kendine bir mektup yaz'
                : 'Write a letter to your future self',
            style: AppTheme.displayFont(
              fontSize: 16,
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            style: AppTheme.bodyFont(
              fontSize: 14,
              color: SakuraHomePalette.textDeep,
            ),
            cursorColor: SakuraHomePalette.blossomPink,
            decoration: _decoration(isTr ? 'Başlık (isteğe bağlı)' : 'Title (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            maxLines: 6,
            style: AppTheme.bodyFont(
              fontSize: 14,
              color: SakuraHomePalette.textDeep,
            ),
            cursorColor: SakuraHomePalette.blossomPink,
            decoration: _decoration(
              isTr ? 'Sevgili gelecekteki ben...' : 'Dear future me...',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded,
                      size: 18, color: SakuraHomePalette.blossomPink),
                  const SizedBox(width: 8),
                  Text(
                    isTr ? 'Açılış: ' : 'Opens: ',
                    style: AppTheme.bodyFont(
                      fontSize: 13,
                      color: SakuraHomePalette.textMuted,
                    ),
                  ),
                  Text(
                    DateFormat('d MMMM yyyy', locale).format(openAt),
                    style: AppTheme.bodyFont(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: SakuraHomePalette.textDeep,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_calendar_rounded,
                      size: 15, color: SakuraHomePalette.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PremiumButton(
            label: isTr ? 'Mühürle' : 'Seal it',
            icon: Icons.lock_rounded,
            onPressed: onSave,
          ),
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
    required this.onOpen,
  });

  final Letter letter;
  final String locale;
  final bool isTr;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final unlocked = letter.isUnlocked;
    final openLabel = DateFormat('d MMMM yyyy', locale).format(letter.openAt);
    final title = letter.title.trim().isEmpty
        ? (isTr ? 'Başlıksız mektup' : 'Untitled letter')
        : letter.title;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: unlocked ? onOpen : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(
                  unlocked ? Icons.mark_email_read_rounded : Icons.lock_rounded,
                  color: unlocked
                      ? SakuraHomePalette.blossomPink
                      : SakuraHomePalette.textMuted,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyFont(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: SakuraHomePalette.textDeep,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        unlocked
                            ? (isTr ? 'Okumak için dokun' : 'Tap to read')
                            : (isTr
                                ? '$openLabel tarihinde açılacak'
                                : 'Opens on $openLabel'),
                        style: AppTheme.bodyFont(
                          fontSize: 12,
                          color: SakuraHomePalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  const Icon(Icons.chevron_right_rounded,
                      color: SakuraHomePalette.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
