import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/mood_gradients.dart';
import '../../../../theme/mood_theme_provider.dart';
import '../../../mood/presentation/providers/mood_providers.dart';
import '../../../profile/presentation/providers/visit_tracker_providers.dart';
import '../../domain/auth_flow_routes.dart';

/// Mood accent colours — shared with the calendar via [moodSymbolColors], so a
/// day's mood reads identically everywhere. NOT changed here on purpose.
const List<Color> _moodColors = moodSymbolColors;
const List<IconData> _moodIcons = moodSymbolIcons;

/// Shown once right after sign-in: greets by name over the ASTRA moon/sun
/// scene, then asks how they feel today with soft, glowing mood orbs (whose
/// colours match the calendar). Picking a mood sets the app's mood theme and
/// logs it for the day, then hands off to the app.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.isNewSignup = false});

  final bool isNewSignup;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Created eagerly in initState (not a lazy `late final`): the visit check can
  // navigate away before anything ever reads `_controller`, and a lazy
  // initializer would then fire for the first time inside dispose() — creating
  // a ticker on an already-deactivated widget, which crashes.
  late final AnimationController _controller;

  Timer? _timer;
  bool _navigated = false;
  bool _checkingVisit = true;
  bool _visitChecked = false;
  AppMood? _selected;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _checkVisitAndInit();
  }

  Future<void> _checkVisitAndInit() async {
    if (_visitChecked) return;
    _visitChecked = true;

    // Wait briefly for Supabase currentUser to be ready (prevents guest race conditions)
    User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        user = Supabase.instance.client.auth.currentUser;
        if (user != null) break;
      }
    }

    if (!mounted) return;

    if (user == null) {
      // Guest or unauthenticated user -> skip visit recording and advance
      _advance();
      return;
    }

    // Check if today's visit is a new calendar day for this specific user
    final isNewDay = await ref
        .read(visitDaysCountProvider.notifier)
        .recordVisitIfNewDay();

    if (!mounted) return;

    if (!isNewDay && !widget.isNewSignup) {
      // Already opened today → skip the mood check-in AND the reflection,
      // go straight Home.
      if (mounted && !_navigated) {
        _navigated = true;
        context.go(AuthFlowRoutes.home);
      }
    } else {
      // First visit of the day (or new sign up) -> show mood check-in UI and start animation
      _controller.forward();
      if (mounted) {
        setState(() {
          _checkingVisit = false;
        });
      }
    }
  }

  static const _linesTr = [
    'Seni yeniden görmek güzel.',
    'Küçük bir nefes, güzel bir başlangıç.',
    'İçini dökmek için buradayız.',
    'Kendine nazik ol, buradasın ya, bu yeter.',
  ];
  static const _linesEn = [
    "It's good to see you again.",
    'A small breath, a gentle start.',
    "We're here whenever you want to let it out.",
    "Be kind to yourself — you're here, and that's enough.",
  ];

  late final int _lineIndex = Random().nextInt(_linesTr.length);

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String? get _firstName {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fullName = (metadata?['full_name'] as String?)?.trim();
    if (fullName == null || fullName.isEmpty) return null;
    return fullName.split(RegExp(r'\s+')).first;
  }

  Future<void> _advance() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(
      AuthFlowRoutes.afterMood(isNewSignup: widget.isNewSignup),
      extra: widget.isNewSignup ? true : null,
    );
  }

  void _pickMood(AppMood mood) {
    ref.read(moodThemeProvider.notifier).state = mood;
    // Log today's mood so it shows on the calendar for this day.
    ref.read(moodLogProvider.notifier).setForDay(DateTime.now(), mood.index);
    setState(() => _selected = mood);
    _timer?.cancel();
    // Hold on the confirmation beat long enough to read it, then hand off.
    _timer = Timer(const Duration(milliseconds: 2000), _advance);
  }

  /// A warm, mood-specific closing line shown on the confirmation beat.
  String _confirmLine(AppMood mood, bool isTr) {
    if (isTr) {
      switch (mood) {
        case AppMood.happy:
          return 'Bu ışığı sakla. Yarın yine görüşürüz. ✨';
        case AppMood.calm:
          return 'Bu huzur seninle kalsın. Yarın görüşürüz.';
        case AppMood.tired:
          return 'Bugün kendine izin ver. Yarın görüşürüz.';
        case AppMood.sad:
          return 'Yanındayım. Yarın yine buradayım.';
        case AppMood.anxious:
          return 'Derin bir nefes al. Geçecek — yarın görüşürüz.';
      }
    }
    switch (mood) {
      case AppMood.happy:
        return 'Hold on to this light. See you tomorrow. ✨';
      case AppMood.calm:
        return 'May this calm stay with you. See you tomorrow.';
      case AppMood.tired:
        return 'Be gentle with yourself today. See you tomorrow.';
      case AppMood.sad:
        return "I'm here with you. See you again tomorrow.";
      case AppMood.anxious:
        return 'Take a deep breath. It passes — see you tomorrow.';
    }
  }

  String _label(AppLocalizations l10n, AppMood mood) {
    switch (mood) {
      case AppMood.happy:
        return l10n.moodHappy;
      case AppMood.calm:
        return l10n.moodCalm;
      case AppMood.tired:
        return l10n.moodTired;
      case AppMood.sad:
        return l10n.moodSad;
      case AppMood.anxious:
        return l10n.moodAnxious;
    }
  }

  Widget _staggered(int order, Widget child) {
    final start = (0.28 + order * 0.11).clamp(0.0, 0.85);
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.0).animate(anim),
      child: FadeTransition(opacity: anim, child: child),
    );
  }

  Widget _buildPicker(AppLocalizations l10n, bool isDark, bool isTr) {
    return Column(
      key: const ValueKey('pick'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isTr ? 'Bugün nasıl hissediyorsun?' : 'How do you feel today?',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AstraKit.heading(isDark),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final mood in AppMood.values)
              Expanded(
                child: _staggered(
                  mood.index,
                  _MoodOrb(
                    icon: _moodIcons[mood.index],
                    color: _moodColors[mood.index],
                    label: _label(l10n, mood),
                    selected: _selected == mood,
                    isDark: isDark,
                    onTap: () => _pickMood(mood),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirm(
      AppLocalizations l10n, bool isDark, bool isTr, AppMood mood) {
    final color = _moodColors[mood.index];
    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.65, end: 1.0),
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutBack,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              border: Border.all(color: color, width: 2.4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(_moodIcons[mood.index], size: 38, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        // The mood's name grows into place.
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 540),
          curve: Curves.easeOutBack,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Text(
            _label(l10n, mood),
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AstraKit.heading(isDark),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _confirmLine(mood, isTr),
          textAlign: TextAlign.center,
          style: AstraKit.mutedText(isDark, fontSize: 13.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final gold = AstraKit.gold(isDark);
    final name = _firstName;
    final greeting = isTr
        ? (name == null ? 'Hoş geldin' : 'Hoş geldin, $name')
        : (name == null ? 'Welcome' : 'Welcome, $name');
    final line = isTr ? _linesTr[_lineIndex] : _linesEn[_lineIndex];

    if (_checkingVisit) {
      return Scaffold(
        body: AstraMountainBackground(
          isDark: isDark,
          child: const SizedBox.expand(),
        ),
      );
    }

    return Scaffold(
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity:
                    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeartEmblem(gold: gold, isDark: isDark),
                    const SizedBox(height: 22),
                    AstraGlassCard(
                      isDark: isDark,
                      primaryColor: gold,
                      borderRadius: 28,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            textAlign: TextAlign.center,
                            style: AstraKit.heading1(isDark, fontSize: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            line,
                            textAlign: TextAlign.center,
                            style: AstraKit.mutedText(isDark, fontSize: 13.5),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOut,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.94, end: 1.0)
                                      .animate(anim),
                                  child: child,
                                ),
                              ),
                              child: _selected == null
                                  ? _buildPicker(l10n, isDark, isTr)
                                  : _buildConfirm(l10n, isDark, isTr, _selected!),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _selected == null ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: _selected != null,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _advance,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              isTr ? 'Şimdilik geç' : 'Skip for now',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: gold.withValues(alpha: 0.9),
                                shadows: const [
                                  Shadow(
                                      color: Color(0x88000000), blurRadius: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Soft heart inside a gold-ringed glass disc — a warm, welcoming emblem that
/// still belongs to the ASTRA gold-and-glass world.
class _HeartEmblem extends StatelessWidget {
  const _HeartEmblem({required this.gold, required this.isDark});

  final Color gold;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? const Color(0x59181026)
            : Colors.white.withValues(alpha: 0.5),
        border: Border.all(color: gold.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC7FA9).withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.favorite_rounded,
          size: 30, color: Color(0xFFEC7FA9)),
    );
  }
}

/// A glowing, glassy mood orb: a radial wash of the mood's calendar colour
/// with the weather-style symbol, brightening and lifting when selected.
class _MoodOrb extends StatelessWidget {
  const _MoodOrb({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 220),
            scale: selected ? 1.12 : 1.0,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: selected
                      ? [color, color.withValues(alpha: 0.7)]
                      : [
                          color.withValues(alpha: 0.42),
                          color.withValues(alpha: 0.18),
                        ],
                ),
                border: Border.all(
                  color: color.withValues(alpha: selected ? 0.95 : 0.5),
                  width: selected ? 2.4 : 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: selected ? 0.6 : 0.25),
                    blurRadius: selected ? 18 : 10,
                    spreadRadius: selected ? 1 : 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AstraKit.body(
              isDark,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
