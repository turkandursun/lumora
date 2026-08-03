import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../core/providers/auth_listener.dart';
import '../../../../core/providers/cloud_backup_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../dreams/presentation/providers/dreams_providers.dart';
import '../../../goals/presentation/providers/goals_providers.dart';
import '../../../hobbies/presentation/providers/hobbies_providers.dart';
import '../../../hobbies/presentation/screens/hobbies_screen.dart' show hobbyLabel;
import '../../../journal/presentation/providers/journal_streak_provider.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../rewards/domain/rewards.dart';
import '../../data/profile_repository.dart';
import '../providers/visit_tracker_providers.dart';

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

  Future<void> _editName(bool isTr, bool isDark, Color primary) async {
    final controller = TextEditingController(text: _displayName());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(isTr ? 'Takma adın' : 'Your name', style: AstraKit.heading2(isDark, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w500),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: isTr ? 'İsmini yaz' : 'Type your name',
            hintStyle: AstraKit.mutedText(isDark),
            filled: true,
            fillColor: isDark ? const Color(0x33231845) : const Color(0x55FFF8EE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary.withValues(alpha: 0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTr ? 'Vazgeç' : 'Cancel', style: AstraKit.mutedText(isDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(isTr ? 'Kaydet' : 'Save', style: AstraKit.body(isDark, color: primary, fontWeight: FontWeight.w700)),
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

  Future<void> _restoreNow(bool isTr, bool isDark, Color primary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1233) : const Color(0xFFFFF8EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(isTr ? 'Buluttan geri yükle' : 'Restore from cloud', style: AstraKit.heading2(isDark, fontSize: 18)),
        content: Text(
          isTr
              ? 'Bu cihazdaki veriler, buluttaki son yedekle değiştirilecek. Devam edilsin mi?'
              : 'Data on this device will be replaced with your latest cloud backup. Continue?',
          style: AstraKit.mutedText(isDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isTr ? 'Vazgeç' : 'Cancel', style: AstraKit.mutedText(isDark)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isTr ? 'Geri yükle' : 'Restore', style: AstraKit.body(isDark, color: primary, fontWeight: FontWeight.w700)),
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
    final mode = ref.watch(astraThemeProvider);
    final isDark = mode == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);

    final visitDays = ref.watch(visitDaysCountProvider).valueOrNull ?? 0;
    final journaledDays =
        ref.watch(journalEntryDaysProvider).valueOrNull?.length ?? 0;
    final streak = ref.watch(journalStreakProvider).count;
    final moodCount = ref.watch(moodLogProvider).length;
    final dreams = ref.watch(dreamsStreamProvider).valueOrNull?.length ?? 0;
    final goalStreak = ref.watch(goalStreakProvider).count;

    final reward = computeRewardProgress(
      journaledDays: journaledDays,
      streak: streak,
      dreams: dreams,
      goalStreak: goalStreak,
    );

    final name = _displayName();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.profileTitle, style: AstraKit.heading1(isDark, fontSize: 24)),
                const SizedBox(height: 18),
                _ProfileHeaderCard(
                  name: name.isEmpty ? (isTr ? 'Sen' : 'You') : name,
                  subtitle: _memberSince(isTr),
                  isDark: isDark,
                  primary: primary,
                  onEdit: () => _editName(isTr, isDark, primary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '$visitDays',
                        label: isTr ? 'Gün serisi' : 'Day streak',
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.menu_book_rounded,
                        value: '$journaledDays',
                        label: isTr ? 'Günlük' : 'Entries',
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.wb_sunny_rounded,
                        value: '$moodCount',
                        label: isTr ? 'Ruh hali' : 'Moods',
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AchievementPreviewCard(
                  reward: reward,
                  isTr: isTr,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => context.push(AppRoutes.rewards),
                ),
                const SizedBox(height: 16),
                _HobbiesCard(
                  hobbies: hobbies,
                  isTr: isTr,
                  isDark: isDark,
                  primary: primary,
                  onEdit: () => context.push(AppRoutes.hobbies),
                ),
                const SizedBox(height: 20),
                Text(
                  isTr ? 'Ayarlar' : 'Settings',
                  style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.track_changes_outlined,
                  label: l10n.profileMenuGoals,
                  isDark: isDark,
                  primary: primary,
                  onTap: () => context.push(AppRoutes.goals),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.bar_chart_rounded,
                  label: isTr ? 'İstatistikler' : 'Statistics',
                  isDark: isDark,
                  primary: primary,
                  onTap: () => context.push(AppRoutes.stats),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.cloud_upload_rounded,
                  label: isTr ? 'Verilerimi yedekle' : 'Back up my data',
                  isDark: isDark,
                  primary: primary,
                  onTap: () => _backupNow(isTr),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.cloud_download_rounded,
                  label: isTr ? 'Buluttan geri yükle' : 'Restore from cloud',
                  isDark: isDark,
                  primary: primary,
                  onTap: () => _restoreNow(isTr, isDark, primary),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: l10n.profileMenuLogout,
                  isDark: isDark,
                  primary: primary,
                  onTap: () async {
                    await clearLocalUserData(ref);
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
    required this.isDark,
    required this.primary,
    required this.onEdit,
  });

  final String name;
  final String subtitle;
  final bool isDark;
  final Color primary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final letter = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      borderRadius: 22,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Text(letter, style: AstraKit.heading1(isDark, fontSize: 26).copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AstraKit.heading2(isDark, fontSize: 19)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: AstraKit.mutedText(isDark, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, size: 20, color: primary),
          ),
        ],
      ),
    );
  }
}

/// A small stat tile: an icon, a big number and a caption.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label, required this.isDark, required this.primary});

  final IconData icon;
  final String value;
  final String label;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: 18,
      child: Column(
        children: [
          Icon(icon, size: 22, color: primary),
          const SizedBox(height: 8),
          Text(value, style: AstraKit.heading1(isDark, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: AstraKit.mutedText(isDark, fontSize: 11.5)),
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
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final RewardProgress reward;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Star grows a little with each level (clamped so it always fits).
    final starSize = (26 + reward.level * 2.5).clamp(26.0, 46.0).toDouble();
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.16)),
                      child: Icon(Icons.star_rounded, size: starSize, color: primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isTr ? 'Seviye ${reward.level}' : 'Level ${reward.level}', style: AstraKit.heading2(isDark, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(
                            reward.isMaxLevel
                                ? (isTr ? 'En yüksek seviye!' : 'Max level!')
                                : (isTr ? 'Sonraki seviyeye ${reward.pointsToNext} puan' : '${reward.pointsToNext} pts to next level'),
                            style: AstraKit.mutedText(isDark, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AstraKit.muted(isDark)),
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
                            Container(color: primary.withValues(alpha: 0.16)),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              width: constraints.maxWidth * reward.fraction,
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [primary, primary.withValues(alpha: 0.7)])),
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
                  style: AstraKit.body(isDark, fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                ),
              ],
            ),
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
    required this.isDark,
    required this.primary,
    required this.onEdit,
  });

  final List<String> hobbies;
  final bool isTr;
  final bool isDark;
  final Color primary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.interests_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(isTr ? 'Hobilerim' : 'My hobbies', style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: Icon(Icons.edit_rounded, size: 18, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (hobbies.isEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Text(
                isTr ? 'Henüz hobi eklemedin. Eklemek için dokun.' : "You haven't added hobbies yet. Tap to add.",
                style: AstraKit.mutedText(isDark, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in hobbies)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(hobbyLabel(id, isTr), style: AstraKit.body(isDark, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.isDark, required this.primary, required this.onTap});

  final IconData icon;
  final String label;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: isDark,
      primaryColor: primary,
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AstraKit.body(isDark, fontSize: 15, fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right_rounded, color: AstraKit.muted(isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
