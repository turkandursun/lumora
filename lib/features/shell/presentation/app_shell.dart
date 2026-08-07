import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/cloud_backup_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/astra_screen_kit.dart';
import '../../../theme/luma_chat_sheet.dart';
import '../../journal/presentation/screens/home_screen.dart';
import '../../profile/presentation/screens/profile_screen.dart';

/// Main app shell shown after onboarding/login. Only Home and Profile are
/// persistent [IndexedStack] tabs — the other three bottom-nav slots are
/// actions: İstatistikler pushes a coming-soon screen, the raised center
/// button jumps to Home's journal writing flow, and AI opens Luma's chat
/// sheet directly, none of which need their own preserved tab state.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

enum _ActiveTab { home, profile }

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  _ActiveTab _active = _ActiveTab.home;
  DateTime? _lastBackup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back up whenever the user leaves the app, so the latest data is safe in
    // the cloud. Debounced so rapid pause/resume cycles don't spam uploads.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final now = DateTime.now();
      if (_lastBackup != null &&
          now.difference(_lastBackup!) < const Duration(seconds: 20)) {
        return;
      }
      _lastBackup = now;
      // Fire-and-forget; failures must never disrupt the app.
      ref.read(cloudBackupServiceProvider).backup().catchError((_) {});
    }
  }

  void _openAiChat() {
    LumaChatSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _active == _ActiveTab.home ? 0 : 1,
        children: screens,
      ),
      bottomNavigationBar: _ShellBottomNav(
        active: _active,
        onHome: () => setState(() => _active = _ActiveTab.home),
        onStats: () => context.push(AppRoutes.stats),
        onQuickAdd: () => context.push(AppRoutes.feed),
        onAi: _openAiChat,
        onProfile: () => setState(() => _active = _ActiveTab.profile),
      ),
    );
  }
}

// The whole bar uses the app's lavender theme accent, matching the Profile
// screen — including the raised leaf quick-add button.
const _lavender = Color(0xFFC084FC);
const _lavenderDeep = Color(0xFF8B5CF6);

/// Dark glass bottom bar matching Home's cards, with a raised circular center
/// button for the quick-add action.
class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({
    required this.active,
    required this.onHome,
    required this.onStats,
    required this.onQuickAdd,
    required this.onAi,
    required this.onProfile,
  });

  final _ActiveTab active;
  final VoidCallback onHome;
  final VoidCallback onStats;
  final VoidCallback onQuickAdd;
  final VoidCallback onAi;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF211C30),
        border: Border(top: BorderSide(color: _lavender.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    filledIcon: Icons.home_rounded,
                    label: l10n.shellTabHome,
                    isActive: active == _ActiveTab.home,
                    onTap: onHome,
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_outlined,
                    filledIcon: Icons.bar_chart_rounded,
                    label: l10n.shellTabStats,
                    isActive: false,
                    onTap: onStats,
                  ),
                  const SizedBox(width: 56),
                  _NavItem(
                    icon: Icons.smart_toy_outlined,
                    filledIcon: Icons.smart_toy_rounded,
                    label: l10n.shellTabAi,
                    isActive: false,
                    onTap: onAi,
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    filledIcon: Icons.person_rounded,
                    label: l10n.shellTabProfile,
                    isActive: active == _ActiveTab.profile,
                    onTap: onProfile,
                  ),
                ],
              ),
              Positioned(
                top: -20,
                child: _QuickAddButton(label: l10n.shellTabQuickAdd, onTap: onQuickAdd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _lavender : AstraKit.muted(true);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Semantics(
          selected: isActive,
          button: true,
          label: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActive ? filledIcon : icon, color: color, size: 23),
              const SizedBox(height: 4),
              Text(
                label,
                style: AstraKit.body(
                  true,
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised, elevated center button — a distinct circular FAB-style
/// quick-add action, floating above the rest of the bar.
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_lavender, _lavenderDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _lavender.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFF211C30), width: 3),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
