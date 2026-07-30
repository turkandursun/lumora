import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_background.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/mood_gradients.dart';
import '../../../../theme/mood_theme_provider.dart';
import '../../../../theme/sakura_home_palette.dart';
import '../../../mood/presentation/providers/mood_providers.dart';

import '../../../profile/presentation/providers/visit_tracker_providers.dart';

/// Weather-style symbol + colour for each mood, in AppMood order:
/// happy, calm, tired, sad, anxious.
const List<IconData> _moodIcons = [
  Icons.wb_sunny_rounded, // happy -> sun
  Icons.cloud_rounded, // calm -> soft cloud
  Icons.nightlight_round, // tired -> moon
  Icons.grain_rounded, // sad -> rain
  Icons.air_rounded, // anxious -> wind
];
const List<Color> _moodColors = [
  Color(0xFFF4C95D),
  Color(0xFF9FD8B0),
  Color(0xFFB9A7E0),
  Color(0xFF8FA9D9),
  Color(0xFFE59BB0),
];

/// Shown once right after sign-in: greets by name, then asks how they feel
/// today with weather-style mood symbols. Picking a mood sets the app's
/// mood theme, then hands off (via hobbies onboarding for new signups) to the app.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.isNewSignup = false});

  final bool isNewSignup;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  Timer? _timer;
  bool _navigated = false;
  AppMood? _selected;

  @override
  void initState() {
    super.initState();
    ref.read(visitDaysCountProvider.notifier).recordAndLoad();
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
    if (widget.isNewSignup) {
      context.go(AppRoutes.hobbiesOnboarding);
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _pickMood(AppMood mood) {
    ref.read(moodThemeProvider.notifier).state = mood;
    // Log today's mood so it shows on the calendar for this day.
    ref.read(moodLogProvider.notifier).setForDay(DateTime.now(), mood.index);
    setState(() => _selected = mood);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1200), _advance);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final name = _firstName;
    final greeting = isTr
        ? (name == null ? 'Hoş geldin' : 'Hoş geldin, $name')
        : (name == null ? 'Welcome' : 'Welcome, $name');
    final line = isTr ? _linesTr[_lineIndex] : _linesEn[_lineIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 30, color: SakuraHomePalette.blossomPink),
                    const SizedBox(height: 16),
                    Text(
                      greeting,
                      textAlign: TextAlign.center,
                      style: AppTheme.displayFont(
                          fontSize: 30, color: SakuraHomePalette.textDeep),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      line,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyFont(
                          fontSize: 14.5, color: SakuraHomePalette.textMuted),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      isTr ? 'Bugün nasıl hissediyorsun?' : 'How do you feel today?',
                      textAlign: TextAlign.center,
                      style: AppTheme.displayFont(
                          fontSize: 18, color: SakuraHomePalette.textDeep),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final mood in AppMood.values)
                          _MoodChoice(
                            icon: _moodIcons[mood.index],
                            color: _moodColors[mood.index],
                            label: _label(l10n, mood),
                            selected: _selected == mood,
                            onTap: () => _pickMood(mood),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    TextButton(
                      onPressed: _advance,
                      child: Text(
                        isTr ? 'Şimdilik geç' : 'Skip for now',
                        style: AppTheme.bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SakuraHomePalette.textMuted,
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

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : color.withValues(alpha: 0.18),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.4),
                width: selected ? 3 : 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: selected ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.bodyFont(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SakuraHomePalette.textDeep,
            ),
          ),
        ],
      ),
    );
  }
}
