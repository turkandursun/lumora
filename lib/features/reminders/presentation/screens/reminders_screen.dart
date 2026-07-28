import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/reminders_table.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/premium_button.dart';
import '../../../../theme/responsive_content.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../data/reminders_repository.dart';
import '../providers/reminders_providers.dart';
import '../widgets/new_reminder_sheet.dart';

/// Localized title + notification body for each of the four seeded starter
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
      DefaultReminderIconKeys.gratitudeMoment: ReminderCopy(
        title: l10n.reminderGratitudeMomentTitle,
        body: l10n.reminderGratitudeMomentBody,
      ),
      DefaultReminderIconKeys.weeklyReflection: ReminderCopy(
        title: l10n.reminderWeeklyReflectionTitle,
        body: l10n.reminderWeeklyReflectionBody,
      ),
    };

/// The notification copy for [reminder] — one of the four seeded defaults
/// if its icon key matches, otherwise a generic body paired with whatever
/// title the user gave their own custom reminder.
ReminderCopy reminderCopyFor(AppLocalizations l10n, ReminderRow reminder) {
  return defaultReminderCopy(l10n)[reminder.iconKey] ??
      ReminderCopy(title: reminder.title, body: l10n.reminderCustomBody);
}

IconData iconForReminder(String iconKey) {
  switch (iconKey) {
    case DefaultReminderIconKeys.morningJournal:
      return Icons.wb_sunny_outlined;
    case DefaultReminderIconKeys.breathingBreak:
      return Icons.air_rounded;
    case DefaultReminderIconKeys.gratitudeMoment:
      return Icons.favorite_outline;
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
  var next = DateTime(now.year, now.month, now.day, reminder.hour, reminder.minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  if (reminder.frequency == ReminderFrequency.weekly) {
    final weekday = reminder.weekday ?? DateTime.monday;
    while (next.weekday != weekday) {
      next = next.add(const Duration(days: 1));
    }
  }
  return next;
}

String frequencyTimeLabel(BuildContext context, AppLocalizations l10n, ReminderRow reminder) {
  final time =
      '${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
  final frequencyLabel = switch (reminder.frequency) {
    ReminderFrequency.daily => l10n.remindersFrequencyDaily,
    ReminderFrequency.once => l10n.remindersFrequencyOnce,
    ReminderFrequency.weekly => _weekdayName(context, reminder.weekday ?? DateTime.monday),
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
  late final TabController _tabController = TabController(length: 2, vsync: this);
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
    ref.read(notificationServiceProvider).requestPermission();
    ref.read(remindersRepositoryProvider).ensureSeeded(defaultReminderCopy(l10n));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remindersAsync = ref.watch(remindersStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: PremiumButton(
        label: l10n.remindersNewButton,
        icon: Icons.add_rounded,
        expand: false,
        onPressed: () => NewReminderSheet.show(context),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.remindersTitle,
                      style: AppTheme.displayFont(
                          fontSize: 24, color: SakuraHomePalette.textDeep),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: SakuraHomePalette.blossomPink,
                  indicatorWeight: 3,
                  labelColor: SakuraHomePalette.textDeep,
                  unselectedLabelColor: SakuraHomePalette.textMuted,
                  labelStyle: AppTheme.bodyFont(fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: AppTheme.bodyFont(fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: l10n.remindersTabUpcoming),
                    Tab(text: l10n.remindersTabAll),
                  ],
                ),
                Expanded(
                  child: remindersAsync.when(
                    data: (reminders) {
                      final upcoming = reminders.where((r) => r.enabled).toList()
                        ..sort((a, b) => nextOccurrence(a).compareTo(nextOccurrence(b)));
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _ReminderList(reminders: upcoming, emptyText: l10n.remindersEmptyUpcoming),
                          _ReminderList(reminders: reminders, emptyText: l10n.remindersEmptyAll),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: SakuraHomePalette.blossomPink),
                    ),
                    error: (_, __) => Center(
                      child: Text(
                        l10n.remindersLoadError,
                        style: AppTheme.bodyFont(color: SakuraHomePalette.textMuted),
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

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.reminders, required this.emptyText});

  final List<ReminderRow> reminders;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(color: SakuraHomePalette.textMuted),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: reminders.length,
      itemBuilder: (context, index) => _ReminderCard(reminder: reminders[index]),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.reminder});

  final ReminderRow reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SakuraHomePalette.blossomPink.withValues(alpha: 0.16),
            ),
            child: Icon(iconForReminder(reminder.iconKey),
                color: SakuraHomePalette.blossomPink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: AppTheme.bodyFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SakuraHomePalette.textDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  frequencyTimeLabel(context, l10n, reminder),
                  style: AppTheme.bodyFont(
                    fontSize: 12.5,
                    color: SakuraHomePalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.enabled,
            activeThumbColor: SakuraHomePalette.blossomPink,
            onChanged: (value) {
              final copy = value ? reminderCopyFor(l10n, reminder) : null;
              ref.read(remindersRepositoryProvider).setEnabled(reminder, value, copy: copy);
            },
          ),
        ],
      ),
    );
  }
}
