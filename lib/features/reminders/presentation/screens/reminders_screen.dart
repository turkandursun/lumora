import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/reminders_table.dart';
import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../data/reminders_repository.dart';
import '../providers/reminders_providers.dart';
import '../widgets/new_reminder_sheet.dart';
import '../widgets/smart_reminders_card.dart';

/// Localized title + notification body for each of the seeded starter
/// reminders, keyed by [DefaultReminderIconKeys]. Lives in the presentation
/// layer since it needs [AppLocalizations]; the repository stays free of
/// any localization concerns.
Map<String, ReminderCopy> defaultReminderCopy(AppLocalizations l10n) => {
      DefaultReminderIconKeys.morningJournal: ReminderCopy(
        title: l10n.reminderMorningJournalTitle,
        body: l10n.reminderMorningJournalBody,
      ),
      DefaultReminderIconKeys.breathingBreak: ReminderCopy(
        title: l10n.reminderBreathingBreakTitle,
        body: l10n.reminderBreathingBreakBody,
      ),
      DefaultReminderIconKeys.weeklyReflection: ReminderCopy(
        title: l10n.reminderWeeklyReflectionTitle,
        body: l10n.reminderWeeklyReflectionBody,
      ),
    };

/// The notification copy for [reminder] — one of the seeded defaults
/// if its icon key matches, otherwise a generic body paired with whatever
/// title the user gave their own custom reminder.
ReminderCopy reminderCopyFor(AppLocalizations l10n, ReminderRow reminder) {
  return defaultReminderCopy(l10n)[reminder.iconKey] ??
      ReminderCopy(title: 'ASTRA', body: reminder.title);
}

IconData iconForReminder(String iconKey) {
  switch (iconKey) {
    case DefaultReminderIconKeys.morningJournal:
      return Icons.wb_sunny_outlined;
    case DefaultReminderIconKeys.breathingBreak:
      return Icons.air_rounded;
    case DefaultReminderIconKeys.weeklyReflection:
      return Icons.auto_awesome_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

/// Next local wall-clock occurrence of [reminder] — used only to sort the
/// "Upcoming" tab (soonest first), not for actual scheduling (see
/// [NotificationService], which does the timezone-aware version of this).
DateTime nextOccurrence(ReminderRow reminder) {
  final now = DateTime.now();
  var next =
      DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  if (reminder.frequency == ReminderFrequency.weekly) {
    final weekday = reminder.weekday ?? DateTime.monday;
    while (next.weekday != weekday) {
      next = next.add(const Duration(days: 1));
    }
  }
  return next;
}

String frequencyTimeLabel(
    BuildContext context, AppLocalizations l10n, ReminderRow reminder) {
  final time =
      '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
  final frequencyLabel = switch (reminder.frequency) {
    ReminderFrequency.daily => l10n.remindersFrequencyDaily,
    ReminderFrequency.once => l10n.remindersFrequencyOnce,
    ReminderFrequency.weekly =>
      _weekdayName(context, reminder.weekday ?? DateTime.monday),
  };
  return '$frequencyLabel - $time';
}

/// Localized full weekday name for [weekday] (1 = Monday .. 7 = Sunday),
/// via `intl` rather than another set of per-day ARB keys.
String _weekdayName(BuildContext context, int weekday) {
  final locale = Localizations.localeOf(context).toString();
  // 2024-01-01 was a Monday, so weekday 1..7 maps directly onto +0..+6 days.
  final reference = DateTime(2024, 1, 1).add(Duration(days: weekday - 1));
  return DateFormat.EEEE(locale).format(reference);
}

/// Reminders list — "Upcoming" (enabled, soonest first) and "All" tabs,
/// backed by a local Drift database and kept in sync with scheduled local
/// notifications. See [RemindersRepository].
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  bool _didInitialSetup = false;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialSetup) return;
    _didInitialSetup = true;
    final l10n = AppLocalizations.of(context);
    final copy = defaultReminderCopy(l10n);
    unawaited(
      ref.read(remindersRepositoryProvider).initializeForCurrentUser(copy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remindersAsync = ref.watch(remindersStreamProvider);
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AstraGoldButton(
        isDark: isDark,
        label: l10n.remindersNewButton,
        icon: Icons.add_rounded,
        expand: false,
        onTap: () => NewReminderSheet.show(context),
      ),
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 4),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.remindersTitle,
                          style:
                              AstraKit.heading1(context, isDark, fontSize: 24)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SmartRemindersCard(isDark: isDark),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: primary,
                  indicatorWeight: 3,
                  labelColor: AstraKit.ink(context, isDark),
                  unselectedLabelColor: AstraKit.muted(context, isDark),
                  labelStyle: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: l10n.remindersTabUpcoming),
                    Tab(text: l10n.remindersTabAll),
                  ],
                ),
                Expanded(
                  child: remindersAsync.when(
                    data: (reminders) {
                      final upcoming = reminders
                          .where((r) => r.enabled)
                          .toList()
                        ..sort((a, b) =>
                            nextOccurrence(a).compareTo(nextOccurrence(b)));
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _ReminderList(
                            reminders: upcoming,
                            emptyText: l10n.remindersEmptyUpcoming,
                            isDark: isDark,
                            primary: primary,
                          ),
                          _ReminderList(
                            reminders: reminders,
                            emptyText: l10n.remindersEmptyAll,
                            isDark: isDark,
                            primary: primary,
                          ),
                        ],
                      );
                    },
                    loading: () => Center(
                        child: CircularProgressIndicator(color: primary)),
                    error: (_, __) => Center(
                      child: Text(l10n.remindersLoadError,
                          style: AstraKit.mutedText(context, isDark)),
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

class _ReminderList extends StatelessWidget {
  const _ReminderList({
    required this.reminders,
    required this.emptyText,
    required this.isDark,
    required this.primary,
  });

  final List<ReminderRow> reminders;
  final String emptyText;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(emptyText,
              textAlign: TextAlign.center,
              style: AstraKit.mutedText(context, isDark)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: reminders.length,
      itemBuilder: (context, index) => _ReminderCard(
          reminder: reminders[index], isDark: isDark, primary: primary),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard(
      {required this.reminder, required this.isDark, required this.primary});

  final ReminderRow reminder;
  final bool isDark;
  final Color primary;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    const errorColor = Color(0xFFE07A7A);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary.withValues(alpha: 0.3)),
        ),
        title: Text(
          isTr ? 'Hatırlatıcıyı Sil' : 'Delete Reminder',
          style: AstraKit.heading2(context, isDark, fontSize: 18),
        ),
        content: Text(
          isTr
              ? 'Bu hatırlatıcıyı silmek istediğine emin misin?'
              : 'Are you sure you want to delete this reminder?',
          style: AstraKit.mutedText(context, isDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isTr ? 'Vazgeç' : 'Cancel',
                style: AstraKit.mutedText(context, isDark)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isTr ? 'Sil' : 'Delete',
              style: const TextStyle(
                  color: errorColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(remindersRepositoryProvider).delete(reminder);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.16),
                border: Border.all(color: primary.withValues(alpha: 0.35)),
              ),
              child: Icon(iconForReminder(reminder.iconKey),
                  color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title,
                      style: AstraKit.body(context, isDark,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(frequencyTimeLabel(context, l10n, reminder),
                      style:
                          AstraKit.mutedText(context, isDark, fontSize: 12.5)),
                ],
              ),
            ),
            Switch(
              value: reminder.enabled,
              activeThumbColor: primary,
              onChanged: (value) {
                final copy = value ? reminderCopyFor(l10n, reminder) : null;
                ref
                    .read(remindersRepositoryProvider)
                    .setEnabled(reminder, value, copy: copy);
              },
            ),
            if (reminder.defaultKey == null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AstraKit.muted(context, isDark),
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context, ref),
                tooltip: isTr ? 'Sil' : 'Delete',
              ),
          ],
        ),
      ),
    );
  }
}
