import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../data/dilemma_repository.dart';
import '../../domain/dilemma_bank.dart';

/// Tinder-style dilemma cards: swipe left/right to pick a side, see how real
/// app users split, and at the end get a summary you can share to the Safe
/// Space community. A different set of dilemmas rotates in every day.
class DilemmaSwipeScreen extends ConsumerStatefulWidget {
  const DilemmaSwipeScreen({super.key});

  @override
  ConsumerState<DilemmaSwipeScreen> createState() => _DilemmaSwipeScreenState();
}

class _DilemmaSwipeScreenState extends ConsumerState<DilemmaSwipeScreen> {
  static const _threshold = 90.0;

  List<Dilemma> _todays = const [];
  bool _ready = false;

  int _index = 0;
  double _dragX = 0;
  bool _revealed = false;
  bool _choseLeft = false;

  DilemmaStats? _stats;
  bool _loadingStats = false;

  final List<int> _agreePcts = []; // agree% for each answered dilemma
  bool _sharing = false;
  bool _shared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _todays = dailyDilemmas(AppLocalizations.of(context));
    _ready = true;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_revealed) return;
    setState(() => _dragX += d.delta.dx);
  }

  void _onPanEnd(DragEndDetails d, Dilemma dilemma) {
    if (_revealed) return;
    if (_dragX.abs() >= _threshold) {
      _reveal(_dragX < 0, dilemma);
    } else {
      setState(() => _dragX = 0);
    }
  }

  void _reveal(bool left, Dilemma dilemma) {
    if (_revealed) return;
    setState(() {
      _choseLeft = left;
      _dragX = left ? -_threshold : _threshold;
      _revealed = true;
      _stats = null;
      _loadingStats = true;
    });
    _submit(dilemma.id, left);
  }

  Future<void> _submit(int dilemmaId, bool left) async {
    final repo = ref.read(dilemmaRepositoryProvider);
    try {
      await repo.castVote(dilemmaId, left);
      final s = await repo.fetchStats(dilemmaId);
      if (mounted) {
        setState(() {
          _stats = s;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  int _currentAgreePct() {
    final d = _todays[_index];
    final hasReal = _stats != null && _stats!.total > 0;
    final leftPct = hasReal
        ? (_stats!.left * 100 / _stats!.total).round()
        : d.fallbackLeftPct;
    return _choseLeft ? leftPct : 100 - leftPct;
  }

  void _next() {
    _agreePcts.add(_currentAgreePct());
    setState(() {
      _index++;
      _dragX = 0;
      _revealed = false;
      _stats = null;
      _loadingStats = false;
    });
  }

  void _restart() {
    setState(() {
      _todays = List.of(_todays)..shuffle();
      _index = 0;
      _dragX = 0;
      _revealed = false;
      _stats = null;
      _loadingStats = false;
      _agreePcts.clear();
      _sharing = false;
      _shared = false;
    });
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final total = _agreePcts.length;
    final majority = _agreePcts.where((p) => p >= 50).length;
    setState(() => _sharing = true);
    try {
      await ref.read(communityRepositoryProvider).shareAnswer(
            questionDate: DateTime.now(),
            answerText: l10n.dilemmaShareText(majority, total),
            l10n: l10n,
          );
      if (!mounted) return;
      setState(() {
        _sharing = false;
        _shared = true;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.dilemmaShared)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.communityLoadError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(isDark);
    final done = !_ready || _index >= _todays.length;
    final dilemma = done ? null : _todays[_index];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.dilemmaTitle,
                        style: AstraKit.heading1(isDark, fontSize: 24)),
                    const Spacer(),
                    if (!done)
                      Text('${_index + 1}/${_todays.length}',
                          style: AstraKit.mutedText(isDark, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                if (!done)
                  Text(l10n.dilemmaSubtitle,
                      style: AstraKit.mutedText(isDark, fontSize: 13)),
                Expanded(
                  child: done
                      ? _SummaryView(
                          agreePcts: _agreePcts,
                          isDark: isDark,
                          primary: primary,
                          sharing: _sharing,
                          shared: _shared,
                          onShare: _share,
                          onRestart: _restart,
                        )
                      : Center(
                          child: _revealed
                              ? _ResultView(
                                  dilemma: dilemma!,
                                  choseLeft: _choseLeft,
                                  stats: _stats,
                                  loading: _loadingStats,
                                  isDark: isDark,
                                  primary: primary,
                                  onNext: _next,
                                )
                              : _SwipeCard(
                                  dilemma: dilemma!,
                                  dragX: _dragX,
                                  isDark: isDark,
                                  primary: primary,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: (d) => _onPanEnd(d, dilemma),
                                  onChoose: (left) => _reveal(left, dilemma),
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

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.dilemma,
    required this.dragX,
    required this.isDark,
    required this.primary,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onChoose,
  });

  final Dilemma dilemma;
  final double dragX;
  final bool isDark;
  final Color primary;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;
  final void Function(bool left) onChoose;

  @override
  Widget build(BuildContext context) {
    final leftActive = dragX < -14;
    final rightActive = dragX > 14;
    final intensity = (dragX.abs() / 90).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Transform.translate(
        offset: Offset(dragX, 0),
        child: Transform.rotate(
          angle: dragX / 1400,
          child: AstraGlassCard(
            isDark: isDark,
            primaryColor: primary,
            padding: const EdgeInsets.all(20),
            borderRadius: 26,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionPanel(
                  text: dilemma.left,
                  isDark: isDark,
                  primary: primary,
                  active: leftActive,
                  intensity: leftActive ? intensity : 0,
                  onTap: () => onChoose(true),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.16),
                    ),
                    child: Text('⇄',
                        style: TextStyle(fontSize: 20, color: primary)),
                  ),
                ),
                _OptionPanel(
                  text: dilemma.right,
                  isDark: isDark,
                  primary: primary,
                  active: rightActive,
                  intensity: rightActive ? intensity : 0,
                  onTap: () => onChoose(false),
                ),
                const SizedBox(height: 18),
                Text('←   ↔   →',
                    style: AstraKit.mutedText(isDark, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionPanel extends StatelessWidget {
  const _OptionPanel({
    required this.text,
    required this.isDark,
    required this.primary,
    required this.active,
    required this.intensity,
    required this.onTap,
  });

  final String text;
  final bool isDark;
  final Color primary;
  final bool active;
  final double intensity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: primary.withValues(alpha: 0.10 + 0.28 * intensity),
          border: Border.all(
            color: primary.withValues(alpha: active ? 0.9 : 0.25),
            width: active ? 2 : 1,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AstraKit.body(isDark,
              fontSize: 17, fontWeight: FontWeight.w700, height: 1.25),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.dilemma,
    required this.choseLeft,
    required this.stats,
    required this.loading,
    required this.isDark,
    required this.primary,
    required this.onNext,
  });

  final Dilemma dilemma;
  final bool choseLeft;
  final DilemmaStats? stats;
  final bool loading;
  final bool isDark;
  final Color primary;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasReal = stats != null && stats!.total > 0;
    final leftPct = hasReal
        ? (stats!.left * 100 / stats!.total).round()
        : dilemma.fallbackLeftPct;
    final rightPct = 100 - leftPct;
    final agreePct = choseLeft ? leftPct : rightPct;

    return SingleChildScrollView(
      child: AstraGlassCard(
        isDark: isDark,
        primaryColor: primary,
        padding: const EdgeInsets.all(20),
        borderRadius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dilemmaResultAgree(agreePct),
                textAlign: TextAlign.center,
                style: AstraKit.heading2(isDark, fontSize: 18)),
            const SizedBox(height: 6),
            if (loading)
              SizedBox(
                height: 14,
                width: 14,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: primary),
              )
            else
              Text(
                hasReal
                    ? '${stats!.total} ${Localizations.localeOf(context).languageCode == 'tr' ? 'oy' : 'votes'}'
                    : ' ',
                style: AstraKit.mutedText(isDark, fontSize: 11.5),
              ),
            const SizedBox(height: 16),
            _ResultBar(
                text: dilemma.left,
                pct: leftPct,
                chosen: choseLeft,
                isDark: isDark,
                primary: primary),
            const SizedBox(height: 12),
            _ResultBar(
                text: dilemma.right,
                pct: rightPct,
                chosen: !choseLeft,
                isDark: isDark,
                primary: primary),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor:
                      isDark ? Colors.white : const Color(0xFF1A0F00),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.dilemmaNext,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.text,
    required this.pct,
    required this.chosen,
    required this.isDark,
    required this.primary,
  });

  final String text;
  final int pct;
  final bool chosen;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (chosen) ...[
              Icon(Icons.check_circle_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(text,
                  style: AstraKit.body(isDark,
                      fontSize: 14,
                      fontWeight: chosen ? FontWeight.w800 : FontWeight.w600)),
            ),
            Text('%$pct',
                style: AstraKit.body(isDark,
                    fontSize: 14, fontWeight: FontWeight.w800, color: primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct / 100),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: chosen
                            ? [primary, primary.withValues(alpha: 0.7)]
                            : [
                                primary.withValues(alpha: 0.45),
                                primary.withValues(alpha: 0.3)
                              ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.agreePcts,
    required this.isDark,
    required this.primary,
    required this.sharing,
    required this.shared,
    required this.onShare,
    required this.onRestart,
  });

  final List<int> agreePcts;
  final bool isDark;
  final Color primary;
  final bool sharing;
  final bool shared;
  final VoidCallback onShare;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = agreePcts.length;
    final majority = agreePcts.where((p) => p >= 50).length;

    return Center(
      child: SingleChildScrollView(
        child: AstraGlassCard(
          isDark: isDark,
          primaryColor: primary,
          padding: const EdgeInsets.all(22),
          borderRadius: 26,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_rounded, size: 44, color: primary),
              const SizedBox(height: 16),
              Text(l10n.dilemmaDoneTitle,
                  textAlign: TextAlign.center,
                  style: AstraKit.heading1(isDark, fontSize: 22)),
              const SizedBox(height: 10),
              if (total > 0)
                Text(l10n.dilemmaSummaryLine(majority, total),
                    textAlign: TextAlign.center,
                    style: AstraKit.body(isDark, fontSize: 15, height: 1.35)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (sharing || shared || total == 0) ? null : onShare,
                  icon: sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(shared
                          ? Icons.check_rounded
                          : Icons.diversity_3_rounded),
                  label: Text(
                    shared ? l10n.dilemmaShared : l10n.dilemmaShareButton,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor:
                        isDark ? Colors.white : const Color(0xFF1A0F00),
                    disabledBackgroundColor: primary.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onRestart,
                child: Text(l10n.dilemmaRestart,
                    style: TextStyle(
                        color: AstraKit.muted(isDark),
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
