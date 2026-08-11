import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin, RouteAware {
  _ActiveTab _active = _ActiveTab.home;
  // The Profile tab is built lazily the first time it's opened, so its entrance
  // animations play when the user actually sees it — not silently while hidden.
  bool _profileVisited = false;
  DateTime? _lastBackup;

  // Ticking these replays the entrance choreography (greeting → bell → the rest
  // cascading up) on each tab EVERY time it becomes active, not just on first
  // build — every AstraEntrance under the tab's AstraEntranceReplay re-runs.
  final ValueNotifier<int> _homeReplay = ValueNotifier<int>(0);
  final ValueNotifier<int> _profileReplay = ValueNotifier<int>(0);

  // Drives the raised FAB's radial "quick add" menu: 0 = closed, 1 = open. The
  // '+' rotates to an 'X', the scene blurs, and the actions spring outward.
  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  }

  void _switchTab(_ActiveTab tab) {
    if (_fabAnim.value > 0) _fabAnim.reverse();
    if (_active == tab) return;
    setState(() {
      _active = tab;
      if (tab == _ActiveTab.profile) _profileVisited = true;
    });
    // Replay the incoming tab's entrance cascade.
    if (tab == _ActiveTab.home) {
      _homeReplay.value++;
    } else {
      _profileReplay.value++;
    }
  }

  void _toggleFab() {
    HapticFeedback.lightImpact();
    if (_fabAnim.value == 0 && !_fabAnim.isAnimating) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
  }

  void _fabAction(String route) {
    _fabAnim.reverse();
    context.push(route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) astraRouteObserver.subscribe(this, route);
  }

  /// A pushed screen was popped and the shell is visible again — replay the
  /// active tab's entrance cascade so returning from a card also re-animates.
  @override
  void didPopNext() {
    if (_active == _ActiveTab.home) {
      _homeReplay.value++;
    } else {
      _profileReplay.value++;
    }
  }

  @override
  void dispose() {
    astraRouteObserver.unsubscribe(this);
    _homeReplay.dispose();
    _profileReplay.dispose();
    _fabAnim.dispose();
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
      // Only built once the user first opens Profile, so its cascade animates
      // in view rather than finishing while the tab is still hidden.
      _profileVisited ? const ProfileScreen() : const SizedBox.shrink(),
    ];
    final activeIndex = _active == _ActiveTab.home ? 0 : 1;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      // Both tabs stay alive (state + scroll preserved). Each is wrapped in an
      // [AstraEntranceReplay]; switching to a tab ticks its notifier so its
      // entrance cascade (greeting → bell → the rest sliding up) replays every
      // time — not only on first launch.
      body: Stack(
        children: [
          for (var i = 0; i < screens.length; i++)
            IgnorePointer(
              ignoring: activeIndex != i,
              child: Opacity(
                opacity: activeIndex == i ? 1 : 0,
                child: AstraEntranceReplay(
                  notifier: i == 0 ? _homeReplay : _profileReplay,
                  child: screens[i],
                ),
              ),
            ),
          // Radial quick-add menu overlay (blur + springing actions).
          _FabMenuOverlay(
            anim: _fabAnim,
            isDark: isDark,
            onClose: () => _fabAnim.reverse(),
            onAction: _fabAction,
          ),
        ],
      ),
      bottomNavigationBar: _ShellBottomNav(
        isDark: isDark,
        active: _active,
        fabAnim: _fabAnim,
        onHome: () => _switchTab(_ActiveTab.home),
        onStats: () => context.push(AppRoutes.stats),
        onQuickAdd: _toggleFab,
        onAi: _openAiChat,
        onProfile: () => _switchTab(_ActiveTab.profile),
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
    required this.fabAnim,
    required this.onHome,
    required this.onStats,
    required this.onQuickAdd,
    required this.onAi,
    required this.onProfile,
  });

  final bool isDark;
  final _ActiveTab active;
  final Animation<double> fabAnim;
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
                  anim: fabAnim,
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

/// The raised, elevated center button — a circular FAB that opens the quick-add
/// menu. As the menu opens it spins ~45° (spring) and its leaf morphs into a
/// close 'X'.
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.label,
    required this.isDark,
    required this.barColor,
    required this.anim,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final Color barColor;
  final Animation<double> anim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Lavender pill on the dark theme, gold on the light theme — matching the
    // rest of the interface's theme accent.
    final gradient = isDark
        ? const [_lavender, _lavenderDeep]
        : const [Color(0xFFF0D68A), Color(0xFFB8860B)];
    final glow = isDark ? _lavender : const Color(0xFFD4AF37);
    final iconColor = isDark ? Colors.white : const Color(0xFF1A0F00);
    final spin = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
    return Semantics(
      button: true,
      label: label,
      child: BouncyTap(
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
          child: AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              // Spin 45° (0.125 turns) and cross-fade leaf → X as it opens.
              return Transform.rotate(
                angle: spin.value * 0.7853981633974483, // 45°
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: (1 - anim.value).clamp(0.0, 1.0),
                      child: Icon(Icons.eco_rounded, color: iconColor, size: 26),
                    ),
                    Opacity(
                      opacity: anim.value.clamp(0.0, 1.0),
                      child: Icon(Icons.close_rounded, color: iconColor, size: 26),
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

/// Quick-add options that spring out from the FAB — one action, plus the
/// journal / dream / calm shortcuts — over a blurred, dimmed scene. Reachable
/// only while the FAB menu is open.
class _FabMenuOverlay extends StatelessWidget {
  const _FabMenuOverlay({
    required this.anim,
    required this.isDark,
    required this.onClose,
    required this.onAction,
  });

  final Animation<double> anim;
  final bool isDark;
  final VoidCallback onClose;
  final void Function(String route) onAction;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final items = <(IconData, String, String)>[
      (Icons.edit_note_rounded, isTr ? 'Günlük Yaz' : 'Write journal', AppRoutes.journalEntry),
      (Icons.nightlight_round, isTr ? 'Yeni Rüya' : 'New dream', AppRoutes.newDream),
      (Icons.spa_rounded, isTr ? 'Sakinleş' : 'Calm', AppRoutes.calm),
      (Icons.dynamic_feed_rounded, isTr ? 'Akış' : 'Feed', AppRoutes.feed),
    ];

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final v = anim.value;
        if (v == 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: Stack(
            children: [
              // Blurred, dimmed scrim — tap anywhere to close.
              GestureDetector(
                onTap: onClose,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14 * v, sigmaY: 14 * v),
                  child: Container(color: Colors.black.withValues(alpha: 0.42 * v)),
                ),
              ),
              // Actions stack, springing up from just above the FAB.
              Positioned(
                left: 0,
                right: 0,
                bottom: 96,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _FabMenuItem(
                        icon: items[i].$1,
                        label: items[i].$2,
                        // Bottom item leads, cascading upward.
                        progress: _staggered(v, items.length - 1 - i, items.length),
                        onTap: () => onAction(items[i].$3),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Per-item eased progress with a small stagger across the open animation.
  double _staggered(double v, int order, int total) {
    final start = order * 0.08;
    final local = ((v - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(local);
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({required this.icon, required this.label, required this.progress, required this.onTap});

  final IconData icon;
  final String label;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - progress)),
        child: Transform.scale(
          scale: 0.8 + 0.2 * progress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: BouncyTap(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xF01B1330),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0x55C084FC)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: const Color(0xFFC084FC), size: 20),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(color: Color(0xFFF4EEFF), fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
