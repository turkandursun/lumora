import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../../letters/presentation/providers/letter_providers.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../data/pdf_export_service.dart';

/// Lets the user pick a date range and download a warm PDF archive of their
/// journal, dreams, future-letters and mood history.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late DateTime _start;
  late DateTime _end;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = DateTime(now.year, now.month, now.day);
    _start = DateTime(now.year - 1, now.month, now.day);
  }

  String _displayName() {
    final user = Supabase.instance.client.auth.currentUser;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return '';
  }

  String _fmt(DateTime d, String locale) {
    try {
      return DateFormat('d MMMM yyyy', locale).format(d);
    } catch (_) {
      return '${d.day}.${d.month}.${d.year}';
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: SakuraHomePalette.blossomPink,
            onPrimary: Colors.white,
            surface: SakuraHomePalette.cardWhite,
            onSurface: SakuraHomePalette.textDeep,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    setState(() => _busy = true);
    try {
      final start = DateTime(_start.year, _start.month, _start.day);
      final end = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);

      bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

      final journals = (await ref
              .read(journalEntriesRepositoryProvider)
              .watchAll()
              .first)
          .where((e) => inRange(e.createdAt))
          .toList();
      final dreams =
          (await ref.read(dreamsRepositoryProvider).watchAll().first)
              .where((d) => inRange(d.date))
              .toList();
      final letters = (await ref.read(letterRepositoryProvider).load())
          .where((l) => inRange(l.createdAt))
          .toList();
      final allMoods = await ref.read(moodLogRepositoryProvider).load();
      final moods = <DateTime, int>{
        for (final e in allMoods.entries)
          if (inRange(e.key)) e.key: e.value,
      };

      final bundle = ExportBundle(
        journals: journals,
        dreams: dreams,
        letters: letters,
        moods: moods,
      );

      if (bundle.isEmpty) {
        if (mounted) {
          _snack(l10n.exportEmptyRange);
          setState(() => _busy = false);
        }
        return;
      }

      final name = _displayName();
      final labels = ExportLabels(
        documentTitle: name.isEmpty
            ? l10n.exportDocumentTitleNoName
            : l10n.exportDocumentTitle(name),
        rangeLine: '${_fmt(start, locale)}  –  ${_fmt(end, locale)}',
        generatedOn: l10n.exportGeneratedOn(_fmt(DateTime.now(), locale)),
        journalSection: l10n.exportSectionJournal,
        dreamsSection: l10n.exportSectionDreams,
        lettersSection: l10n.exportSectionLetters,
        moodSection: l10n.exportSectionMood,
        emptySection: l10n.exportSectionEmpty,
        untitled: l10n.exportUntitled,
        moodDaysSuffix: l10n.exportMoodDays,
        letterSealedFor: l10n.exportLetterOpens,
        moodNames: [
          l10n.moodHappy,
          l10n.moodCalm,
          l10n.moodTired,
          l10n.moodSad,
          l10n.moodAnxious,
        ],
        localeCode: locale,
      );

      final bytes = await buildJournalPdf(data: bundle, labels: labels);
      final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
      await Printing.sharePdf(bytes: bytes, filename: 'ASTRA_$stamp.pdf');
    } catch (e) {
      if (mounted) _snack(l10n.exportError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: SakuraHomePalette.blossomPink,
        content: Text(msg,
            style: AppTheme.bodyFont(color: Colors.white, fontWeight: FontWeight.w600)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: SakuraHomePalette.textDeep),
                  ),
                ),
                Text(
                  l10n.exportTitle,
                  style: AppTheme.displayFont(
                      fontSize: 24, color: SakuraHomePalette.textDeep),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.exportIntro,
                  style: AppTheme.bodyFont(
                      fontSize: 14, color: SakuraHomePalette.textMuted),
                ),
                const SizedBox(height: 24),
                _DateRow(
                  label: l10n.exportStartLabel,
                  value: _fmt(_start, locale),
                  onTap: () => _pickDate(isStart: true),
                ),
                const SizedBox(height: 12),
                _DateRow(
                  label: l10n.exportEndLabel,
                  value: _fmt(_end, locale),
                  onTap: () => _pickDate(isStart: false),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: _PrimaryButton(
                    label: _busy ? l10n.exportGenerating : l10n.exportButton,
                    busy: _busy,
                    onTap: _busy ? null : _export,
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

class _DateRow extends StatelessWidget {
  const _DateRow(
      {required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SakuraHomePalette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: SakuraHomePalette.blossomPink),
              const SizedBox(width: 12),
              Text(label,
                  style: AppTheme.bodyFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SakuraHomePalette.textDeep)),
              const Spacer(),
              Text(value,
                  style: AppTheme.bodyFont(
                      fontSize: 14, color: SakuraHomePalette.textMuted)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: SakuraHomePalette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.busy, required this.onTap});

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient:
                const LinearGradient(colors: SakuraHomePalette.ctaGradient),
            boxShadow: [
              BoxShadow(
                color: SakuraHomePalette.blossomPink.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
              ] else ...[
                const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Text(label,
                  style: AppTheme.bodyFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
