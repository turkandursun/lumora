import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/journal_entries_provider.dart';
import '../widgets/voice_entry_player.dart';

/// "Mühürlü Günlükler" — a read-only archive of every sealed journal entry,
/// grouped day by day, newest first. Each entry shows the time it was sealed,
/// its written text, and (when present) an inline player for its attached
/// voice note. Reached from the journal writing screen and PIN-gated through
/// the same [AppSection.journalWriting] lock as the writing screen itself.
class SealedJournalsScreen extends ConsumerWidget {
  const SealedJournalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final primary =
        isDark ? const Color(0xFFE3C264) : const Color(0xFFD4AF37);
    final localeStr = Localizations.localeOf(context).toString();
    final entriesAsync = ref.watch(allJournalEntriesProvider);
    final photoPaths =
        ref.watch(journalPhotoPathsProvider).valueOrNull ?? const {};

    return Scaffold(
      body: _MountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: ResponsiveContent(
                  child: Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        primary: primary,
                        isDark: isDark,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_rounded,
                                    size: 15, color: primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isTr
                                        ? 'Mühürlü Günlükler'
                                        : 'Sealed Journals',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFFF4EEFF)
                                          : const Color(0xFF1A1005),
                                    ).copyWith(shadows: [
                                      Shadow(
                                        color: isDark
                                            ? const Color(0x99000000)
                                            : const Color(0x33FFFFFF),
                                        blurRadius: 8,
                                      ),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isTr
                                  ? 'Geçmiş anıların, tarih tarih.'
                                  : 'Your past moments, day by day.',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xCCD8C8FF)
                                    : const Color(0xCC5A481F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Body
              Expanded(
                child: entriesAsync.when(
                  loading: () =>
                      Center(child: CircularProgressIndicator(color: primary)),
                  error: (_, __) => Center(
                    child: Text(
                      isTr
                          ? 'Günlükler yüklenemedi.'
                          : 'Could not load your journals.',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return _EmptyState(
                          isDark: isDark, isTr: isTr, primary: primary);
                    }
                    final groups = _groupByDay(entries);
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
                      itemCount: groups.length,
                      itemBuilder: (context, i) {
                        final group = groups[i];
                        return ResponsiveContent(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DayHeader(
                                date: group.day,
                                localeStr: localeStr,
                                isDark: isDark,
                                primary: primary,
                              ),
                              for (final entry in group.entries)
                                _EntryCard(
                                  entry: entry,
                                  isDark: isDark,
                                  primary: primary,
                                  localeStr: localeStr,
                                  photoPath: photoPaths[entry.id.toString()],
                                ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouping
// ─────────────────────────────────────────────────────────────────────────────

class _DayGroup {
  _DayGroup(this.day) : entries = [];
  final DateTime day;
  final List<JournalEntryRow> entries;
}

/// Groups entries (already newest-first) into per-day buckets while preserving
/// order: newest day first, and newest entry first within each day.
List<_DayGroup> _groupByDay(List<JournalEntryRow> entries) {
  final byKey = <String, _DayGroup>{};
  final order = <String>[];
  for (final e in entries) {
    final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
    final key = '${d.year}-${d.month}-${d.day}';
    var group = byKey[key];
    if (group == null) {
      group = _DayGroup(d);
      byKey[key] = group;
      order.add(key);
    }
    group.entries.add(e);
  }
  return [for (final key in order) byKey[key]!];
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.date,
    required this.localeStr,
    required this.isDark,
    required this.primary,
  });

  final DateTime date;
  final String localeStr;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('d MMMM yyyy, EEEE', localeStr).format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 13, color: primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: isDark
                    ? const Color(0xFFEADBFF)
                    : const Color(0xFF5A4820),
              ).copyWith(shadows: [
                Shadow(
                  color: isDark
                      ? const Color(0x99000000)
                      : const Color(0x40FFFFFF),
                  blurRadius: 6,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.isDark,
    required this.primary,
    required this.localeStr,
    this.photoPath,
  });

  final JournalEntryRow entry;
  final bool isDark;
  final Color primary;
  final String localeStr;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm', localeStr).format(entry.createdAt);
    final hasTitle = entry.title != null && entry.title!.trim().isNotEmpty;
    final hasText = entry.content.trim().isNotEmpty;
    final hasAudio = entry.audioPath != null && entry.audioPath!.isNotEmpty;
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCard(
        isDark: isDark,
        primary: primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 13, color: primary.withValues(alpha: 0.85)),
                const SizedBox(width: 5),
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: primary,
                  ),
                ),
                if (hasPhoto) ...[
                  const Spacer(),
                  Icon(Icons.photo_rounded,
                      size: 15, color: primary.withValues(alpha: 0.85)),
                ],
                if (hasAudio) ...[
                  if (!hasPhoto) const Spacer(),
                  const SizedBox(width: 8),
                  Icon(Icons.graphic_eq_rounded,
                      size: 15, color: primary.withValues(alpha: 0.85)),
                ],
              ],
            ),
            if (hasTitle) ...[
              const SizedBox(height: 10),
              Text(
                entry.title!,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF4EEFF)
                      : const Color(0xFF1A1005),
                ),
              ),
            ],
            if (hasPhoto) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: kIsWeb
                      ? Image.network(photoPath!, fit: BoxFit.cover)
                      : Image.file(
                          File(photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                ),
              ),
            ],
            if (hasText) ...[
              const SizedBox(height: 8),
              Text(
                entry.content,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF6ECD2)
                      : const Color(0xFF1A1005),
                ),
              ),
            ],
            if (hasAudio) ...[
              const SizedBox(height: 12),
              VoiceEntryPlayer(audioPath: entry.audioPath!),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isDark,
    required this.isTr,
    required this.primary,
  });

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
            Icon(Icons.menu_book_rounded,
                size: 46, color: primary.withValues(alpha: 0.8)),
            const SizedBox(height: 16),
            Text(
              isTr ? 'Henüz mühürlü bir günlük yok' : 'No sealed journals yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF4EEFF) : const Color(0xFF1A1005),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTr
                  ? 'İlk günlüğünü mühürlediğinde burada tarih tarih belirecek.'
                  : 'Once you seal your first entry it will appear here, day by day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? const Color(0xCCD8C8FF)
                    : const Color(0xCC5A481F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular icon button — mirrors the journal writing screen's app-bar button.
class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0x44231845) : const Color(0x55FFF8EE),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 18, color: primary),
      ),
    );
  }
}

/// Frosted glass card — same premium look as the journal writing screen.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.isDark,
    required this.primary,
    required this.child,
  });

  final bool isDark;
  final Color primary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x59181026)
                : const Color(0x9EFBF1DD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primary.withValues(alpha: 0.40),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Full-bleed mountain scene background, matching the journal writing screen:
/// moon over the peaks for the dark theme, sun for the light theme.
class _MountainBackground extends StatelessWidget {
  const _MountainBackground({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final asset = isDark
        ? 'assets/images/astra_dark_plain.png'
        : 'assets/images/astra_sun_bg_g5.png';
    return ColoredBox(
      color: isDark ? const Color(0xFF0F0B1A) : const Color(0xFFFDF6E9),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Image.asset(
              asset,
              key: ValueKey(asset),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          // Softens the busy scene (rocks, rays, foliage) so it reads as an
          // atmosphere behind the cards rather than competing detail.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [Color(0x55000000), Color(0x00000000)]
                    : const [Color(0x1F000000), Color(0x00000000)],
                stops: const [0.0, 0.30],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
