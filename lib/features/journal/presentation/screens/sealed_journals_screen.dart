import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/journal_entries_provider.dart';
import '../widgets/voice_entry_player.dart';

/// "Günlüklerim" — a calendar-driven archive: pick a day on the month calendar
/// (days with entries are dotted) and that day's journals appear below, each
/// with a delete action. Cleaner than the old single long mixed list.
class SealedJournalsScreen extends ConsumerStatefulWidget {
  const SealedJournalsScreen({super.key});

  @override
  ConsumerState<SealedJournalsScreen> createState() =>
      _SealedJournalsScreenState();
}

class _SealedJournalsScreenState extends ConsumerState<SealedJournalsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<bool> _confirmDelete(BuildContext context, JournalEntryRow entry,
      bool isTr, bool isDark, Color primary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTr ? 'Günlüğü sil' : 'Delete entry',
            style: AstraKit.heading2(context, isDark, fontSize: 18)),
        content: Text(
          isTr
              ? 'Bu günlük kaydı kalıcı olarak silinecek. Emin misin?'
              : 'This entry will be permanently deleted. Are you sure?',
          style: AstraKit.mutedText(context, isDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isTr ? 'Vazgeç' : 'Cancel',
                style: AstraKit.mutedText(context, isDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isTr ? 'Sil' : 'Delete',
                style: AstraKit.body(context, isDark,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE07A7A))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(journalEntriesRepositoryProvider)
          .delete(entry.id, supabaseId: entry.supabaseId);
      return true;
    }
    return false;
  }

  /// Opens the entry as a premium "sheet of paper" that drops onto the screen.
  void _openEntry(JournalEntryRow entry, String localeStr, bool isTr,
      bool isDark, Color primary) {
    Navigator.of(context).push(_paperDropRoute(
      _JournalDetailPage(
        entry: entry,
        localeStr: localeStr,
        isTr: isTr,
        isDark: isDark,
        primary: primary,
        onDelete: () async {
          final deleted =
              await _confirmDelete(context, entry, isTr, isDark, primary);
          if (deleted && mounted) Navigator.of(context).pop();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final localeStr = Localizations.localeOf(context).toString();
    final primary = AstraKit.primary(context, isDark);
    final entriesAsync = ref.watch(allJournalEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: entriesAsync.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: primary)),
            error: (_, __) => Center(
              child: Text(
                  isTr
                      ? 'Günlükler yüklenemedi.'
                      : 'Could not load your journals.',
                  style: AstraKit.mutedText(context, isDark)),
            ),
            data: (entries) {
              // Map of day → entries, plus the set of days that have entries.
              final byDay = <DateTime, List<JournalEntryRow>>{};
              for (final e in entries) {
                byDay.putIfAbsent(_dayKey(e.createdAt), () => []).add(e);
              }
              // Default selection: the most recent day that has an entry.
              final selected = _selectedDay ??
                  (entries.isNotEmpty
                      ? _dayKey(entries.first.createdAt)
                      : _dayKey(DateTime.now()));
              final dayEntries =
                  byDay[_dayKey(selected)] ?? const <JournalEntryRow>[];

              return ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(isDark: isDark, isTr: isTr, primary: primary),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: AstraGlassCard(
                        isDark: isDark,
                        primaryColor: primary,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        child: _Calendar(
                          focusedDay: _focusedDay,
                          selectedDay: selected,
                          isDark: isDark,
                          primary: primary,
                          isTr: isTr,
                          hasEntries: (d) => byDay.containsKey(_dayKey(d)),
                          onSelected: (sel, foc) => setState(() {
                            _selectedDay = _dayKey(sel);
                            _focusedDay = foc;
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: dayEntries.isEmpty
                          ? _EmptyDay(
                              isDark: isDark, isTr: isTr, primary: primary)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                              itemCount: dayEntries.length,
                              itemBuilder: (context, i) => AstraEntrance(
                                index: i,
                                intervalMs: 50,
                                offset: 26,
                                child: _EntryTile(
                                  entry: dayEntries[i],
                                  isDark: isDark,
                                  primary: primary,
                                  localeStr: localeStr,
                                  isTr: isTr,
                                  onOpen: () => _openEntry(dayEntries[i],
                                      localeStr, isTr, isDark, primary),
                                  onDelete: () => _confirmDelete(context,
                                      dayEntries[i], isTr, isDark, primary),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.isDark, required this.isTr, required this.primary});

  final bool isDark;
  final bool isTr;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
      child: Row(
        children: [
          AstraCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            isDark: isDark,
            primaryColor: primary,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isTr ? 'Günlüklerim' : 'My Journals',
                  style: AstraKit.heading1(context, isDark, fontSize: 22)),
              Text(
                  isTr
                      ? 'Bir tarih seç, o günün günlükleri gelsin.'
                      : 'Pick a date to see that day’s entries.',
                  style: AstraKit.mutedText(context, isDark, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.isDark,
    required this.primary,
    required this.isTr,
    required this.hasEntries,
    required this.onSelected,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final bool isDark;
  final Color primary;
  final bool isTr;
  final bool Function(DateTime) hasEntries;
  final void Function(DateTime selected, DateTime focused) onSelected;

  @override
  Widget build(BuildContext context) {
    final text = AstraKit.ink(context, isDark);
    final muted = AstraKit.muted(context, isDark);
    return TableCalendar<Object>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2035),
      focusedDay: focusedDay,
      locale: isTr ? 'tr_TR' : 'en_US',
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onSelected,
      eventLoader: (day) => hasEntries(day) ? const [1] : const [],
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: primary),
        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: primary),
        titleTextStyle: AstraKit.heading2(context, isDark, fontSize: 16),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AstraKit.mutedText(context, isDark, fontSize: 11.5),
        weekendStyle: AstraKit.mutedText(context, isDark, fontSize: 11.5),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
        weekendTextStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
        outsideTextStyle: TextStyle(color: muted.withValues(alpha: 0.5)),
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary.withValues(alpha: 0.18),
          border: Border.all(color: primary.withValues(alpha: 0.5)),
        ),
        todayTextStyle: TextStyle(color: text, fontWeight: FontWeight.w700),
        selectedDecoration:
            BoxDecoration(shape: BoxShape.circle, color: primary),
        selectedTextStyle: const TextStyle(
            color: Color(0xFF1A0F00), fontWeight: FontWeight.w800),
        markerDecoration: BoxDecoration(
            shape: BoxShape.circle, color: primary.withValues(alpha: 0.9)),
        markersMaxCount: 1,
        markerSize: 5,
        markerMargin: const EdgeInsets.only(top: 6),
      ),
    );
  }
}

/// Compact list row — just the time and the title (or first line of the
/// entry). Tapping it drops the full "paper" page in.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.isDark,
    required this.primary,
    required this.localeStr,
    required this.isTr,
    required this.onOpen,
    required this.onDelete,
  });

  final JournalEntryRow entry;
  final bool isDark;
  final Color primary;
  final String localeStr;
  final bool isTr;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm', localeStr).format(entry.createdAt);
    final rawTitle = entry.title?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : (entry.content.trim().isNotEmpty
            ? entry.content.trim()
            : (isTr ? 'Günlük' : 'Entry'));
    final hasAudio = entry.audioPath != null && entry.audioPath!.isNotEmpty;
    final photoUrl = entry.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncyTap(
        onTap: onOpen,
        child: AstraGlassCard(
          isDark: isDark,
          primaryColor: primary,
          padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: primary.withValues(alpha: 0.85)),
                        const SizedBox(width: 5),
                        Text(time,
                            style: AstraKit.body(context, isDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primary)),
                        if (hasPhoto) ...[
                          const SizedBox(width: 9),
                          Icon(Icons.photo_rounded,
                              size: 13, color: primary.withValues(alpha: 0.7)),
                        ],
                        if (hasAudio) ...[
                          const SizedBox(width: 7),
                          Icon(Icons.graphic_eq_rounded,
                              size: 13, color: primary.withValues(alpha: 0.7)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AstraKit.heading2(context, isDark, fontSize: 16)),
                  ],
                ),
              ),
              InkResponse(
                onTap: onDelete,
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 19, color: AstraKit.muted(context, isDark)),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme-aware palette for the reading page — warm ivory in the light theme,
/// a deep "night parchment" in the dark theme, so it feels intentional and
/// premium in both instead of a bright card blinding the reader at night.
class _PaperPalette {
  const _PaperPalette({
    required this.paperTop,
    required this.paperBottom,
    required this.ink,
    required this.softInk,
    required this.hairline,
    required this.frame,
    required this.spine,
    required this.accent,
    required this.shadow,
  });

  final Color paperTop;
  final Color paperBottom;
  final Color ink;
  final Color softInk;
  final Color hairline;
  final Color frame;
  final Color spine;
  final Color accent;
  final List<BoxShadow> shadow;

  factory _PaperPalette.of(bool isDark, Color primary) {
    if (isDark) {
      return _PaperPalette(
        paperTop: const Color(0xFF241E31),
        paperBottom: const Color(0xFF191426),
        ink: const Color(0xFFEDE4D6),
        softInk: const Color(0xFFA99CBB),
        hairline: const Color(0x1FFFFFFF),
        frame: const Color(0xFF2C2540),
        spine: primary.withValues(alpha: 0.55),
        accent: primary,
        shadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 44,
              offset: const Offset(0, 22)),
          BoxShadow(
              color: primary.withValues(alpha: 0.16),
              blurRadius: 34,
              spreadRadius: 1),
        ],
      );
    }
    return _PaperPalette(
      paperTop: const Color(0xFFFCF8EF),
      paperBottom: const Color(0xFFF2E9D6),
      ink: const Color(0xFF2B2318),
      softInk: const Color(0xFF9A876A),
      hairline: const Color(0x14000000),
      frame: const Color(0xFFFFFDF8),
      spine: primary.withValues(alpha: 0.38),
      accent: primary,
      shadow: const [
        BoxShadow(
            color: Color(0x59000000), blurRadius: 46, offset: Offset(0, 22)),
        BoxShadow(
            color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    );
  }
}

/// The premium reading view: the entry set like a page from a fine journal —
/// an editorial serif on warm parchment, a hairline ornament rule under the
/// title, a soft bookbinding spine down the left edge, and framed media. It
/// eases onto the dimmed screen rather than reading like a database row.
class _JournalDetailPage extends StatelessWidget {
  const _JournalDetailPage({
    required this.entry,
    required this.localeStr,
    required this.isTr,
    required this.isDark,
    required this.primary,
    required this.onDelete,
  });

  final JournalEntryRow entry;
  final String localeStr;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = _PaperPalette.of(isDark, primary);
    final dateEyebrow = DateFormat('d MMMM yyyy', localeStr)
        .format(entry.createdAt)
        .toUpperCase();
    final weekday = DateFormat('EEEE', localeStr).format(entry.createdAt);
    final time = DateFormat('HH:mm', localeStr).format(entry.createdAt);
    final hasTitle = entry.title != null && entry.title!.trim().isNotEmpty;
    final hasText = entry.content.trim().isNotEmpty;
    final hasAudio = entry.audioPath != null && entry.audioPath!.isNotEmpty;
    final photoUrl = entry.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.paperTop, p.paperBottom],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: p.hairline),
                  boxShadow: p.shadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // A soft bound "spine" down the inner-left edge.
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                p.spine.withValues(alpha: 0),
                                p.spine,
                                p.spine.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 22, 22, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Eyebrow date + actions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateEyebrow,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2,
                                          color: p.softInk,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '$weekday · $time',
                                        style: GoogleFonts.lora(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          color: p.softInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _PaperIconBtn(
                                    icon: Icons.delete_outline_rounded,
                                    palette: p,
                                    onTap: onDelete),
                                const SizedBox(width: 6),
                                _PaperIconBtn(
                                  icon: Icons.close_rounded,
                                  palette: p,
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // ── Title
                            Text(
                              hasTitle
                                  ? entry.title!.trim()
                                  : (isTr ? 'Bugünden' : 'From today'),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                height: 1.18,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _OrnamentRule(palette: p),
                            const SizedBox(height: 20),
                            // ── Photo, framed like a mounted print
                            if (hasPhoto) ...[
                              _FramedPhoto(url: photoUrl, palette: p),
                              const SizedBox(height: 20),
                            ],
                            // ── Body, set in a warm literary serif
                            if (hasText)
                              Text(
                                entry.content.trim(),
                                style: GoogleFonts.lora(
                                  fontSize: 16.5,
                                  height: 1.85,
                                  color: p.ink,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            if (hasAudio) ...[
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: p.frame,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: p.hairline),
                                ),
                                child: VoiceEntryPlayer(
                                    audioPath: entry.audioPath!),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // ── Closing flourish
                            Center(
                              child: Icon(
                                Icons.spa_rounded,
                                size: 16,
                                color: p.accent.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A hairline rule broken by a small centered diamond — a quiet editorial
/// divider under the title.
class _OrnamentRule extends StatelessWidget {
  const _OrnamentRule({required this.palette});

  final _PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: Container(
              height: 1, color: palette.softInk.withValues(alpha: 0.35)),
        );
    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 6,
              height: 6,
              color: palette.accent.withValues(alpha: 0.75),
            ),
          ),
        ),
        line(),
      ],
    );
  }
}

/// A photo mounted on the page — a thin paper mat with a soft drop shadow.
class _FramedPhoto extends StatelessWidget {
  const _FramedPhoto({required this.url, required this.palette});

  final String url;
  final _PaperPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.frame,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.hairline),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                color: palette.hairline,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: palette.accent),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _PaperIconBtn extends StatelessWidget {
  const _PaperIconBtn(
      {required this.icon, required this.palette, required this.onTap});

  final IconData icon;
  final _PaperPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.softInk.withValues(alpha: 0.10),
          border: Border.all(color: palette.hairline),
        ),
        child: Icon(icon, size: 18, color: palette.softInk),
      ),
    );
  }
}

/// Route that eases the page in with a gentle upward settle, fade and subtle
/// scale — a calm, premium arrival rather than a thrown sheet of paper.
Route<T> _paperDropRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: const Color(0x8C000000),
    barrierDismissible: true,
    barrierLabel: 'journal',
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final settle = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic);
      final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.55, curve: Curves.easeOut));
      return FadeTransition(
        opacity: fade,
        child: AnimatedBuilder(
          animation: settle,
          child: child,
          builder: (context, c) {
            final v = settle.value;
            return Transform.translate(
              offset: Offset(0, -20 * (1 - v)),
              child: Transform.scale(
                  scale: 0.96 + 0.04 * v,
                  alignment: Alignment.topCenter,
                  child: c),
            );
          },
        ),
      );
    },
  );
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay(
      {required this.isDark, required this.isTr, required this.primary});

  final bool isDark;
  final bool isTr;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded,
                size: 44, color: primary.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(
              isTr ? 'Bu güne ait günlük yok' : 'No entries for this day',
              textAlign: TextAlign.center,
              style: AstraKit.heading2(context, isDark, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              isTr
                  ? 'Takvimde noktalı günler günlük içerir.'
                  : 'Dotted days on the calendar have entries.',
              textAlign: TextAlign.center,
              style: AstraKit.mutedText(context, isDark, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
