import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../hobbies/presentation/providers/hobbies_providers.dart';
import '../../../hobbies/presentation/screens/hobbies_screen.dart' show hobbyLabel;
import '../../../journal/presentation/providers/journal_entries_provider.dart';
import '../../../journal/presentation/providers/journal_streak_provider.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../rewards/domain/rewards.dart';
import '../../data/profile_repository.dart';

/// Profile tab — a profile card, a stats summary, an achievements preview,
/// the user's chosen hobbies and a settings menu.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _displayName() {
    final user = Supabase.instance.client.auth.currentUser;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return '';
  }

  Future<void> _editName(bool isTr) async {
    final controller = TextEditingController(text: _displayName());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SakuraHomePalette.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          isTr ? 'Takma adın' : 'Your name',
          style: AppTheme.displayFont(
              fontSize: 18, color: SakuraHomePalette.textDeep),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          style: AppTheme.bodyFont(
              fontSize: 15, color: SakuraHomePalette.textDeep),
          cursorColor: SakuraHomePalette.blossomPink,
          decoration: InputDecoration(
            hintText: isTr ? 'İsmini yaz' : 'Type your name',
            hintStyle: AppTheme.bodyFont(color: SakuraHomePalette.textMuted),
            filled: true,
            fillColor: SakuraHomePalette.lavender,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isTr ? 'Vazgeç' : 'Cancel',
              style: AppTheme.bodyFont(color: SakuraHomePalette.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(
              isTr ? 'Kaydet' : 'Save',
              style: AppTheme.bodyFont(
                  color: SakuraHomePalette.blossomPink,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await ProfileRepository().updateFullName(result);
    if (mounted) setState(() {});
  }

  Future<void> _backupNow(bool isTr) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isTr ? 'Yedekleniyor...' : 'Backing up...'),
    ));
    try {
      await ref.read(cloudBackupServiceProvider).backup();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(isTr ? 'Yedeklendi 🌸' : 'Backed up 🌸'),
        ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(isTr ? 'Yedeklenemedi: $e' : "Couldn't back up: $e"),
        ));
    }
  }

  Future<void> _restoreNow(bool isTr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SakuraHomePalette.cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          isTr ? 'Buluttan geri yükle' : 'Restore from cloud',
          style: AppTheme.displayFont(
              fontSize: 18, color: SakuraHomePalette.textDeep),
        ),
        content: Text(
          isTr
              ? 'Bu cihazdaki veriler, buluttaki son yedekle değiştirilecek. Devam edilsin mi?'
              : 'Data on this device will be replaced with your latest cloud backup. Continue?',
          style: AppTheme.bodyFont(
              fontSize: 14, color: SakuraHomePalette.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTr ? 'Vazgeç' : 'Cancel',
                style: AppTheme.bodyFont(color: SakuraHomePalette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTr ? 'Geri yükle' : 'Restore',
                style: AppTheme.bodyFont(
                    color: SakuraHomePalette.blossomPink,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final ok = await ref.read(cloudBackupServiceProvider).restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(ok
            ? (isTr
                ? 'Geri yüklendi. Değişikliklerin görünmesi için uygulamayı yeniden başlat.'
                : 'Restored. Restart the app to see your data.')
            : (isTr
                ? 'Bulutta yedek bulunamadı.'
                : 'No cloud backup found.')),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isTr
            ? 'Geri yüklenemedi. (Sunucu kurulumu gerekebilir.)'
            : "Couldn't restore. (Server setup may be needed.)"),
      ));
    }
  }

  String _memberSince(bool isTr) {
    final createdAt = Supabase.instance.client.auth.currentUser?.createdAt;
    final date = createdAt == null ? null : DateTime.tryParse(createdAt);
    if (date == null) return '';
    final locale = isTr ? 'tr' : 'en';
    final label = DateFormat.yMMMM(locale).format(date.toLocal());
    return isTr ? '$label\'den beri üye' : 'Member since $label';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final hobbies = ref.watch(hobbiesProvider).toList();

    final journaledDays =
        ref.watch(journalEntryDaysProvider).valueOrNull?.length ?? 0;
    final streak = ref.watch(journalStreakProvider).count;
    final moodCount = ref.watch(moodLogProvider).length;
    final dreams = ref.watch(dreamsStreamProvider).valueOrNull?.length ?? 0;
    final periodDays = ref.watch(periodDaysProvider).length;
    final goalStreak = ref.watch(goalStreakProvider).count;

    final reward = computeRewardProgress(
      journaledDays: journaledDays,
      streak: streak,
      dreams: dreams,
      periodDays: periodDays,
      goalStreak: goalStreak,
    );

    final name = _displayName();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileTitle,
                  style: AppTheme.displayFont(
                      fontSize: 24, color: SakuraHomePalette.textDeep),
                ),
                const SizedBox(height: 18),
                _ProfileHeaderCard(
                  name: name.isEmpty ? (isTr ? 'Sen' : 'You') : name,
                  subtitle: _memberSince(isTr),
                  onEdit: () => _editName(isTr),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '$streak',
                        label: isTr ? 'Gün serisi' : 'Day streak',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.menu_book_rounded,
                        value: '$journaledDays',
                        label: isTr ? 'Günlük' : 'Entries',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.wb_sunny_rounded,
                        value: '$moodCount',
                        label: isTr ? 'Ruh hali' : 'Moods',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AchievementPreviewCard(
                  reward: reward,
                  isTr: isTr,
                  onTap: () => context.push(AppRoutes.rewards),
                ),
                const SizedBox(height: 16),
                _HobbiesCard(
                  hobbies: hobbies,
                  isTr: isTr,
                  onEdit: () => context.push(AppRoutes.hobbies),
                ),
                const SizedBox(height: 20),
                Text(
                  isTr ? 'Ayarlar' : 'Settings',
                  style: AppTheme.bodyFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SakuraHomePalette.textDeep,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: l10n.profileMenuReminders,
                  onTap: () => context.push(AppRoutes.reminders),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.track_changes_outlined,
                  label: l10n.profileMenuGoals,
                  onTap: () => context.push(AppRoutes.goals),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.bar_chart_rounded,
                  label: isTr ? 'İstatistikler' : 'Statistics',
                  onTap: () => context.push(AppRoutes.stats),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.profileMenuAppLock,
                  onTap: () => context.push(AppRoutes.appLock),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.cloud_upload_rounded,
                  label: isTr ? 'Verilerimi yedekle' : 'Back up my data',
                  onTap: () => _backupNow(isTr),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.cloud_download_rounded,
                  label: isTr ? 'Buluttan geri yükle' : 'Restore from cloud',
                  onTap: () => _restoreNow(isTr),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: l10n.profileMenuLogout,
                  onTap: () async {
                    try {
                      await ref.read(journalEntriesRepositoryProvider).deleteAll();
                    } catch (_) {}
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar + name + "member since" header, with an edit button for the name.
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.subtitle,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: SakuraHomePalette.ctaGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              letter,
              style: AppTheme.displayFont(fontSize: 26, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.displayFont(
                      fontSize: 19, color: SakuraHomePalette.textDeep),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTheme.bodyFont(
                      fontSize: 12.5,
                      color: SakuraHomePalette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded,
                size: 20, color: SakuraHomePalette.branchMauve),
          ),
        ],
      ),
    );
  }
}

/// A small stat tile: an icon, a big number and a caption.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: SakuraHomePalette.blossomPink),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.displayFont(
                fontSize: 20, color: SakuraHomePalette.textDeep),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.bodyFont(
              fontSize: 11.5,
              color: SakuraHomePalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact preview of the "growing star" rewards screen: the star, level,
/// progress toward the next level and total points. Tap to open Rewards.
class _AchievementPreviewCard extends StatelessWidget {
  const _AchievementPreviewCard({
    required this.reward,
    required this.isTr,
    required this.onTap,
  });

  final RewardProgress reward;
  final bool isTr;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Star grows a little with each level (clamped so it always fits).
    final starSize = (26 + reward.level * 2.5).clamp(26.0, 46.0).toDouble();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: SakuraHomePalette.cardWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          SakuraHomePalette.blossomPink.withValues(alpha: 0.14),
                    ),
                    child: Icon(Icons.star_rounded,
                        size: starSize, color: SakuraHomePalette.blossomPink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTr
                              ? 'Seviye ${reward.level}'
                              : 'Level ${reward.level}',
                          style: AppTheme.displayFont(
                              fontSize: 18, color: SakuraHomePalette.textDeep),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reward.isMaxLevel
                              ? (isTr ? 'En yüksek seviye!' : 'Max level!')
                              : (isTr
                                  ? 'Sonraki seviyeye ${reward.pointsToNext} puan'
                                  : '${reward.pointsToNext} pts to next level'),
                          style: AppTheme.bodyFont(
                            fontSize: 12.5,
                            color: SakuraHomePalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: SakuraHomePalette.branchMauve),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 9,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                              color: SakuraHomePalette.branchMauve
                                  .withValues(alpha: 0.18)),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            width: constraints.maxWidth * reward.fraction,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: SakuraHomePalette.ctaGradient,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isTr ? '${reward.points} puan' : '${reward.points} points',
                style: AppTheme.bodyFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SakuraHomePalette.blossomPink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HobbiesCard extends StatelessWidget {
  const _HobbiesCard({
    required this.hobbies,
    required this.isTr,
    required this.onEdit,
  });

  final List<String> hobbies;
  final bool isTr;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      decoration: BoxDecoration(
        color: SakuraHomePalette.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: SakuraHomePalette.branchMauve.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.interests_rounded,
                  color: SakuraHomePalette.blossomPink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTr ? 'Hobilerim' : 'My hobbies',
                  style: AppTheme.bodyFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SakuraHomePalette.textDeep,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded,
                    size: 18, color: SakuraHomePalette.branchMauve),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (hobbies.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Text(
                isTr
                    ? 'Henüz hobi eklemedin. Eklemek için dokun.'
                    : "You haven't added hobbies yet. Tap to add.",
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  color: SakuraHomePalette.textMuted,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in hobbies)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: SakuraHomePalette.blossomPink.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: SakuraHomePalette.blossomPink
                              .withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      hobbyLabel(id, isTr),
                      style: AppTheme.bodyFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: SakuraHomePalette.textDeep,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: SakuraHomePalette.cardWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: SakuraHomePalette.branchMauve.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: SakuraHomePalette.blossomPink, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SakuraHomePalette.textDeep,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SakuraHomePalette.branchMauve,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
