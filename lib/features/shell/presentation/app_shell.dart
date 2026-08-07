import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/astra_theme_provider.dart';
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
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
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
        isDark: isDark,
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

/// The bar follows the app theme: a deep violet surface with a lavender accent
/// on the dark/moon theme, a warm cream surface with a gold accent on the
/// light/sun theme — so it never sits as a dark slab on the bright scene.
const _barDark = Color(0xFF211C30);
const _barLight = Color(0xFFF6EAD3);
const _lavender = Color(0xFFC084FC);
const _lavenderDeep = Color(0xFF8B5CF6);

/// Theme-aware bottom bar matching Home's cards, with a raised circular center
/// button for the quick-add action.
class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({
    required this.isDark,
    required this.active,
    required this.onHome,
    required this.onStats,
    required this.onQuickAdd,
    required this.onAi,
    required this.onProfile,
  });

  final bool isDark;
  final _ActiveTab active;
  final VoidCallback onHome;
  final VoidCallback onStats;
  final VoidCallback onQuickAdd;
  final VoidCallback onAi;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final barColor = isDark ? _barDark : _barLight;
    final accent = AstraKit.primary(isDark);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: accent.withValues(alpha: isDark ? 0.3 : 0.45))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
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
                    isDark: isDark,
                    accent: accent,
                    onTap: onHome,
                  ),
                  _NavItem(
                    icon: Icons.bar_chart_outlined,
                    filledIcon: Icons.bar_chart_rounded,
                    label: l10n.shellTabStats,
                    isActive: false,
                    isDark: isDark,
                    accent: accent,
                    onTap: onStats,
                  ),
                  const SizedBox(width: 56),
                  _NavItem(
                    icon: Icons.smart_toy_outlined,
                    filledIcon: Icons.smart_toy_rounded,
                    label: l10n.shellTabAi,
                    isActive: false,
                    isDark: isDark,
                    accent: accent,
                    onTap: onAi,
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    filledIcon: Icons.person_rounded,
                    label: l10n.shellTabProfile,
                    isActive: active == _ActiveTab.profile,
                    isDark: isDark,
                    accent: accent,
                    onTap: onProfile,
                  ),
                ],
              ),
              Positioned(
                top: -20,
                child: _QuickAddButton(
                  label: l10n.shellTabQuickAdd,
                  isDark: isDark,
                  barColor: barColor,
                  onTap: onQuickAdd,
                ),
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
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool isActive;
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? accent : AstraKit.muted(isDark);
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
                  isDark,
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
  const _QuickAddButton({
    required this.label,
    required this.isDark,
    required this.barColor,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final Color barColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Lavender pill on the dark theme, gold on the light theme — matching the
    // rest of the interface's theme accent.
    final gradient = isDark
        ? const [_lavender, _lavenderDeep]
        : const [Color(0xFFF0D68A), Color(0xFFB8860B)];
    final glow = isDark ? _lavender : const Color(0xFFD4AF37);
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
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              // Ring in the bar's own colour so the button reads as lifted off it.
              border: Border.all(color: barColor, width: 3),
            ),
            child: Icon(
              Icons.eco_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A0F00),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
