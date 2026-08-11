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
  ConsumerState<SealedJournalsScreen> createState() => _SealedJournalsScreenState();
}

class _SealedJournalsScreenState extends ConsumerState<SealedJournalsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<bool> _confirmDelete(BuildContext context, JournalEntryRow entry, bool isTr, bool isDark, Color primary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isTr ? 'Günlüğü sil' : 'Delete entry', style: AstraKit.heading2(isDark, fontSize: 18)),
        content: Text(
          isTr ? 'Bu günlük kaydı kalıcı olarak silinecek. Emin misin?' : 'This entry will be permanently deleted. Are you sure?',
          style: AstraKit.mutedText(isDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isTr ? 'Vazgeç' : 'Cancel', style: AstraKit.mutedText(isDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isTr ? 'Sil' : 'Delete',
                style: AstraKit.body(isDark, fontWeight: FontWeight.w700, color: const Color(0xFFE07A7A))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(journalEntriesRepositoryProvider).delete(entry.id, supabaseId: entry.supabaseId);
      return true;
    }
    return false;
  }

  /// Opens the entry as a premium "sheet of paper" that drops onto the screen.
  void _openEntry(JournalEntryRow entry, String localeStr, bool isTr, bool isDark, Color primary) {
    Navigator.of(context).push(_paperDropRoute(
      _JournalDetailPage(
        entry: entry,
        localeStr: localeStr,
        isTr: isTr,
        isDark: isDark,
        primary: primary,
        onDelete: () async {
          final deleted = await _confirmDelete(context, entry, isTr, isDark, primary);
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
    final primary = AstraKit.primary(isDark);
    final entriesAsync = ref.watch(allJournalEntriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: entriesAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: primary)),
            error: (_, __) => Center(
              child: Text(isTr ? 'Günlükler yüklenemedi.' : 'Could not load your journals.', style: AstraKit.mutedText(isDark)),
            ),
            data: (entries) {
              // Map of day → entries, plus the set of days that have entries.
              final byDay = <DateTime, List<JournalEntryRow>>{};
              for (final e in entries) {
                byDay.putIfAbsent(_dayKey(e.createdAt), () => []).add(e);
              }
              // Default selection: the most recent day that has an entry.
              final selected = _selectedDay ??
                  (entries.isNotEmpty ? _dayKey(entries.first.createdAt) : _dayKey(DateTime.now()));
              final dayEntries = byDay[_dayKey(selected)] ?? const <JournalEntryRow>[];

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
                          ? _EmptyDay(isDark: isDark, isTr: isTr, primary: primary)
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
                                  onOpen: () => _openEntry(dayEntries[i], localeStr, isTr, isDark, primary),
                                  onDelete: () => _confirmDelete(context, dayEntries[i], isTr, isDark, primary),
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
  const _Header({required this.isDark, required this.isTr, required this.primary});

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
              Text(isTr ? 'Günlüklerim' : 'My Journals', style: AstraKit.heading1(isDark, fontSize: 22)),
              Text(isTr ? 'Bir tarih seç, o günün günlükleri gelsin.' : 'Pick a date to see that day’s entries.',
                  style: AstraKit.mutedText(isDark, fontSize: 12)),
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
    final text = AstraKit.ink(isDark);
    final muted = AstraKit.muted(isDark);
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
        titleTextStyle: AstraKit.heading2(isDark, fontSize: 16),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AstraKit.mutedText(isDark, fontSize: 11.5),
        weekendStyle: AstraKit.mutedText(isDark, fontSize: 11.5),
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
        selectedDecoration: BoxDecoration(shape: BoxShape.circle, color: primary),
        selectedTextStyle: const TextStyle(color: Color(0xFF1A0F00), fontWeight: FontWeight.w800),
        markerDecoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.9)),
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
        : (entry.content.trim().isNotEmpty ? entry.content.trim() : (isTr ? 'Günlük' : 'Entry'));
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
                        Icon(Icons.schedule_rounded, size: 12, color: primary.withValues(alpha: 0.85)),
                        const SizedBox(width: 5),
                        Text(time, style: AstraKit.body(isDark, fontSize: 12, fontWeight: FontWeight.w700, color: primary)),
                        if (hasPhoto) ...[
                          const SizedBox(width: 9),
                          Icon(Icons.photo_rounded, size: 13, color: primary.withValues(alpha: 0.7)),
                        ],
                        if (hasAudio) ...[
                          const SizedBox(width: 7),
                          Icon(Icons.graphic_eq_rounded, size: 13, color: primary.withValues(alpha: 0.7)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AstraKit.heading2(isDark, fontSize: 16)),
                  ],
                ),
              ),
              InkResponse(
                onTap: onDelete,
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline_rounded, size: 19, color: AstraKit.muted(isDark)),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The premium reading view: the entry rendered on a warm, ruled sheet of paper
/// that drops onto the dimmed screen. Handwritten-style body so it feels like
/// something actually written, not a database row.
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

  static const _inkColor = Color(0xFF3A2A12);
  static const _paperColor = Color(0xFFFBF4E4);

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMMM yyyy · EEEE', localeStr).format(entry.createdAt);
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                decoration: BoxDecoration(
                  color: _paperColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x1A000000)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 20)),
                    BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: CustomPaint(painter: _RuledPaperPainter())),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 20, 18, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$dateLabel · $time',
                                    style: GoogleFonts.kalam(fontSize: 13.5, color: const Color(0xFF7A5A2A), fontWeight: FontWeight.w700),
                                  ),
                                ),
                                _PaperIconBtn(icon: Icons.delete_outline_rounded, onTap: onDelete),
                                const SizedBox(width: 4),
                                _PaperIconBtn(icon: Icons.close_rounded, onTap: () => Navigator.of(context).maybePop()),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Divider(color: Color(0x22000000), height: 18),
                            if (hasTitle) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.title!,
                                style: GoogleFonts.playfairDisplay(fontSize: 25, fontWeight: FontWeight.w700, color: _inkColor),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (hasPhoto) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (hasText)
                              Text(
                                entry.content,
                                style: GoogleFonts.kalam(fontSize: 18, height: 1.65, color: _inkColor, fontWeight: FontWeight.w400),
                              ),
                            if (hasAudio) ...[
                              const SizedBox(height: 16),
                              VoiceEntryPlayer(audioPath: entry.audioPath!),
                            ],
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

class _PaperIconBtn extends StatelessWidget {
  const _PaperIconBtn({required this.icon, required this.onTap});

  final IconData icon;
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
          color: const Color(0x0F000000),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF7A5A2A)),
      ),
    );
  }
}

/// Faint ruled lines + a soft margin rule, behind the journal text.
class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x0F5A3A12)
      ..strokeWidth = 1;
    for (double y = 70; y < size.height - 10; y += 30) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 18, y), line);
    }
    final margin = Paint()
      ..color = const Color(0x22C0392B)
      ..strokeWidth = 1.4;
    canvas.drawLine(const Offset(22, 8), Offset(22, size.height - 8), margin);
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter oldDelegate) => false;
}

/// Route that drops the page in from just above, with a soft spring settle and
/// a slight tilt — like a sheet of paper landing on the desk.
Route<T> _paperDropRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: const Color(0x8C000000),
    barrierDismissible: true,
    barrierLabel: 'journal',
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final drop = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
      final fade = CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
      return FadeTransition(
        opacity: fade,
        child: AnimatedBuilder(
          animation: drop,
          child: child,
          builder: (context, c) {
            final v = drop.value;
            return Transform.translate(
              offset: Offset(0, -42 * (1 - v)),
              child: Transform.rotate(
                angle: -0.05 * (1 - v),
                alignment: Alignment.topCenter,
                child: Transform.scale(scale: 0.9 + 0.1 * v, alignment: Alignment.topCenter, child: c),
              ),
            );
          },
        ),
      );
    },
  );
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isDark, required this.isTr, required this.primary});

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
            Icon(Icons.event_note_rounded, size: 44, color: primary.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(
              isTr ? 'Bu güne ait günlük yok' : 'No entries for this day',
              textAlign: TextAlign.center,
              style: AstraKit.heading2(isDark, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              isTr ? 'Takvimde noktalı günler günlük içerir.' : 'Dotted days on the calendar have entries.',
              textAlign: TextAlign.center,
              style: AstraKit.mutedText(isDark, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
