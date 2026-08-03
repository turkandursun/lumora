import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/crisis_detection_service.dart';
import '../../../../core/services/dream_interpretation_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/crisis_support_sheet.dart';
import '../../../../theme/responsive_content.dart';
import '../../data/dream_symbol_keywords.dart';
import '../../data/dreams_repository.dart';
import '../providers/dreams_providers.dart';
import 'dream_reflection_screen.dart' show dreamFamiliarPersonLabels, dreamFeelingLabels;

/// Dreams are shown as a night scene regardless of the app's light/dark
/// theme choice — the moon setting fits the subject either way, and it
/// keeps this screen from needing a from-scratch bright variant.
const _isDark = true;

/// A symbol's localized label and its gentle, non-definitive association —
/// resolved in the presentation layer (which has an [AppLocalizations]
/// instance) and keyed by [DreamSymbolKeys], mirroring `defaultGoalCopy`'s
/// split between locale-independent data and localized presentation copy.
class DreamSymbolCopy {
  const DreamSymbolCopy({required this.label, required this.description});

  final String label;
  final String description;
}

Map<String, DreamSymbolCopy> dreamSymbolCopy(AppLocalizations l10n) => {
      DreamSymbolKeys.water:
          DreamSymbolCopy(label: l10n.dreamSymbolWaterLabel, description: l10n.dreamSymbolWaterDesc),
      DreamSymbolKeys.flying:
          DreamSymbolCopy(label: l10n.dreamSymbolFlyingLabel, description: l10n.dreamSymbolFlyingDesc),
      DreamSymbolKeys.falling:
          DreamSymbolCopy(label: l10n.dreamSymbolFallingLabel, description: l10n.dreamSymbolFallingDesc),
      DreamSymbolKeys.house:
          DreamSymbolCopy(label: l10n.dreamSymbolHouseLabel, description: l10n.dreamSymbolHouseDesc),
      DreamSymbolKeys.teeth:
          DreamSymbolCopy(label: l10n.dreamSymbolTeethLabel, description: l10n.dreamSymbolTeethDesc),
      DreamSymbolKeys.running:
          DreamSymbolCopy(label: l10n.dreamSymbolRunningLabel, description: l10n.dreamSymbolRunningDesc),
      DreamSymbolKeys.lost:
          DreamSymbolCopy(label: l10n.dreamSymbolLostLabel, description: l10n.dreamSymbolLostDesc),
      DreamSymbolKeys.snake:
          DreamSymbolCopy(label: l10n.dreamSymbolSnakeLabel, description: l10n.dreamSymbolSnakeDesc),
      DreamSymbolKeys.death:
          DreamSymbolCopy(label: l10n.dreamSymbolDeathLabel, description: l10n.dreamSymbolDeathDesc),
      DreamSymbolKeys.baby:
          DreamSymbolCopy(label: l10n.dreamSymbolBabyLabel, description: l10n.dreamSymbolBabyDesc),
      DreamSymbolKeys.exam:
          DreamSymbolCopy(label: l10n.dreamSymbolExamLabel, description: l10n.dreamSymbolExamDesc),
      DreamSymbolKeys.ocean:
          DreamSymbolCopy(label: l10n.dreamSymbolOceanLabel, description: l10n.dreamSymbolOceanDesc),
      DreamSymbolKeys.car:
          DreamSymbolCopy(label: l10n.dreamSymbolCarLabel, description: l10n.dreamSymbolCarDesc),
      DreamSymbolKeys.stairs:
          DreamSymbolCopy(label: l10n.dreamSymbolStairsLabel, description: l10n.dreamSymbolStairsDesc),
      DreamSymbolKeys.mirror:
          DreamSymbolCopy(label: l10n.dreamSymbolMirrorLabel, description: l10n.dreamSymbolMirrorDesc),
      DreamSymbolKeys.door:
          DreamSymbolCopy(label: l10n.dreamSymbolDoorLabel, description: l10n.dreamSymbolDoorDesc),
      DreamSymbolKeys.light:
          DreamSymbolCopy(label: l10n.dreamSymbolLightLabel, description: l10n.dreamSymbolLightDesc),
    };

/// Minimum number of dreams a symbol must appear in before it's called out
/// as "recurring" — see [_recurringSymbolInsight].
const _recurringSymbolThreshold = 3;

/// The insight line shown below the list header when a symbol has appeared
/// in [_recurringSymbolThreshold] or more saved dreams — the single most
/// frequent qualifying symbol, or `null` if none qualifies yet.
String? _recurringSymbolInsight(AppLocalizations l10n, List<DreamRow> dreams) {
  final counts = <String, int>{};
  for (final dream in dreams) {
    for (final tag in symbolTagsFor(dream)) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }

  final qualifying = counts.entries.where((e) => e.value >= _recurringSymbolThreshold).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (qualifying.isEmpty) return null;

  final label = dreamSymbolCopy(l10n)[qualifying.first.key]?.label ?? qualifying.first.key;
  return l10n.dreamJournalRecurringSymbolInsight(label);
}

/// Dream journal — write freeform dream entries and see gentle,
/// locally-detected symbol tags on each one. Symbol detection itself stays
/// entirely rule-based (see `dream_symbol_keywords.dart`); a dream's
/// expanded view additionally offers an optional, explicitly-requested AI
/// reflection via [DreamInterpretationService] (see `_AiInterpretationSection`),
/// cached on the entry once generated. Backed by a local Drift database via
/// [DreamsRepository].
class DreamJournalScreen extends ConsumerWidget {
  const DreamJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dreamsAsync = ref.watch(dreamsStreamProvider);
    final primary = AstraKit.primary(_isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: _isDark,
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 4),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: _isDark,
                        primaryColor: primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.dreamJournalTitle, style: AstraKit.heading1(_isDark, fontSize: 24)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                  child: Text(l10n.dreamJournalSubtitle, style: AstraKit.mutedText(_isDark)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                  child: AstraGoldButton(
                    isDark: _isDark,
                    label: l10n.dreamJournalWriteButton,
                    onTap: () => context.push(AppRoutes.newDream),
                  ),
                ),
                Expanded(
                  child: dreamsAsync.when(
                    data: (dreams) => _DreamListSection(dreams: dreams, primary: primary),
                    loading: () => Center(child: CircularProgressIndicator(color: primary)),
                    error: (_, __) => Center(
                      child: Text(l10n.dreamJournalLoadError, style: AstraKit.mutedText(_isDark)),
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

class _DreamListSection extends StatelessWidget {
  const _DreamListSection({required this.dreams, required this.primary});

  final List<DreamRow> dreams;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final insight = _recurringSymbolInsight(l10n, dreams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Text(
                l10n.dreamJournalListHeader(dreams.length),
                style: AstraKit.body(_isDark, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              _MoonPhaseIcon(dreamCount: dreams.length, primary: primary),
            ],
          ),
        ),
        if (insight != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    insight,
                    style: AstraKit.mutedText(_isDark, fontSize: 12).copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: dreams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(l10n.dreamJournalEmptyState, textAlign: TextAlign.center, style: AstraKit.mutedText(_isDark)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 100),
                  itemCount: dreams.length,
                  itemBuilder: (context, index) => _DreamCard(dream: dreams[index], primary: primary),
                ),
        ),
      ],
    );
  }
}

class _DreamCard extends ConsumerStatefulWidget {
  const _DreamCard({required this.dream, required this.primary});

  final DreamRow dream;
  final Color primary;

  @override
  ConsumerState<_DreamCard> createState() => _DreamCardState();
}

class _DreamCardState extends ConsumerState<_DreamCard> {
  // Lazily constructed — touches `Supabase.instance.client`, which should
  // only happen once the user actually requests an interpretation, not on
  // every dream card built.
  late final _interpretationService = DreamInterpretationService();

  bool _expanded = false;
  bool _isInterpreting = false;
  bool _interpretError = false;

  Future<void> _interpret() async {
    if (_isInterpreting) return;
    final dream = widget.dream;
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode == 'tr' ? 'tr' : 'en';

    // Local, offline keyword check — shown immediately, before the network
    // call even starts, so it appears whether or not the AI response ever
    // comes back. Checked over the same text sent to the AI.
    final crisisCheckText =
        [dream.content, dream.firstThought, dream.lifeConnection].whereType<String>().join('\n');
    if (CrisisDetectionService.containsCrisisLanguage(crisisCheckText)) {
      CrisisSupportSheet.show(context);
    }

    setState(() {
      _isInterpreting = true;
      _interpretError = false;
    });

    try {
      final interpretation = await _interpretationService.interpretDream(
        dreamText: dream.content,
        language: languageCode,
        symbols: symbolTagsFor(dream),
        moodTag: dream.feelingTag != null ? dreamFeelingLabels(l10n)[dream.feelingTag] : null,
        firstThought: dream.firstThought,
        lifeConnection: dream.lifeConnection,
      );
      await ref.read(dreamsRepositoryProvider).saveAiInterpretation(id: dream.id, interpretation: interpretation);
      if (!mounted) return;
      setState(() => _isInterpreting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInterpreting = false;
        _interpretError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('Rüya yorumu hatası: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dream = widget.dream;
    final primary = widget.primary;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final tags = symbolTagsFor(dream);
    final symbolCopy = dreamSymbolCopy(l10n);
    final feelingLabels = dreamFeelingLabels(l10n);
    final familiarPersonLabels = dreamFamiliarPersonLabels(l10n);

    final hasReflectionDetails =
        dream.familiarPerson != null || dream.firstThought != null || dream.lifeConnection != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AstraGlassCard(
        isDark: _isDark,
        primaryColor: primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.18),
                    border: Border.all(color: primary.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.nights_stay_rounded, color: primary, size: 19),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat.yMMMd(locale).format(dream.date),
                  style: AstraKit.body(_isDark, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Text(
                dream.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AstraKit.body(_isDark, fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
              secondChild: Text(dream.content, style: AstraKit.body(_isDark, fontSize: 13.5, fontWeight: FontWeight.w500)),
            ),
            if (tags.isNotEmpty || dream.feelingTag != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (dream.feelingTag != null && feelingLabels[dream.feelingTag] != null)
                    _FeelingChip(label: feelingLabels[dream.feelingTag]!, primary: primary),
                  for (final tag in tags)
                    if (symbolCopy[tag] != null) _SymbolChip(symbolKey: tag, copy: symbolCopy[tag]!, primary: primary),
                ],
              ),
            ],
            if (_expanded && hasReflectionDetails) ...[
              const SizedBox(height: 14),
              Divider(color: primary.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 12),
              if (dream.familiarPerson != null)
                _ReflectionDetailRow(
                  label: l10n.dreamCardFamiliarPersonLabel,
                  value: familiarPersonLabels[dream.familiarPerson] ?? dream.familiarPerson!,
                ),
              if (dream.firstThought != null)
                _ReflectionDetailRow(label: l10n.dreamCardFirstThoughtLabel, value: dream.firstThought!),
              if (dream.lifeConnection != null)
                _ReflectionDetailRow(label: l10n.dreamCardLifeConnectionLabel, value: dream.lifeConnection!),
            ],
            if (_expanded) ...[
              const SizedBox(height: 14),
              _AiInterpretationSection(
                interpretation: dream.aiInterpretation,
                isLoading: _isInterpreting,
                hasError: _interpretError,
                primary: primary,
                onInterpret: _interpret,
              ),
            ],
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _expanded ? l10n.dreamCardShowLess : l10n.dreamCardShowMore,
                  style: AstraKit.body(_isDark, fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-interactive pill naming the reflection flow's answered feeling —
/// visually distinct from the tappable symbol chips beside it.
class _FeelingChip extends StatelessWidget {
  const _FeelingChip({required this.label, required this.primary});

  final String label;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: primary.withValues(alpha: 0.22),
        border: Border.all(color: primary.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AstraKit.body(_isDark, fontSize: 11.5, fontWeight: FontWeight.w700, color: primary)),
    );
  }
}

/// A labeled reflection answer shown only once a dream card is expanded.
class _ReflectionDetailRow extends StatelessWidget {
  const _ReflectionDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AstraKit.label(_isDark, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: AstraKit.body(_isDark, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Optional AI-generated dream reflection — additive alongside the local
/// symbol tags above, never replacing them. Shows a call-to-action button
/// when nothing's cached yet, a loading state while the `dream-interpret`
/// Edge Function call is in flight, and once a reflection exists, a
/// visually distinct card (soft "AI Insight" label) plus a small
/// "Re-interpret" option to explicitly regenerate it.
class _AiInterpretationSection extends StatelessWidget {
  const _AiInterpretationSection({
    required this.interpretation,
    required this.isLoading,
    required this.hasError,
    required this.primary,
    required this.onInterpret,
  });

  final String? interpretation;
  final bool isLoading;
  final bool hasError;
  final Color primary;
  final VoidCallback onInterpret;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading) {
      return _AiLoadingRow(text: l10n.dreamCardInterpretingStatus, primary: primary);
    }

    final hasInterpretation = interpretation != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasInterpretation) _AiInsightCard(text: interpretation!, label: l10n.dreamCardAiInsightLabel, primary: primary),
        if (hasError) ...[
          if (hasInterpretation) const SizedBox(height: 10),
          _WarmErrorBanner(text: l10n.dreamCardInterpretError),
        ],
        if (hasInterpretation || hasError) const SizedBox(height: 10),
        _InterpretButton(
          label: hasInterpretation ? l10n.dreamCardReinterpretButton : l10n.dreamCardInterpretButton,
          primary: primary,
          onTap: onInterpret,
        ),
      ],
    );
  }
}

class _AiLoadingRow extends StatelessWidget {
  const _AiLoadingRow({required this.text, required this.primary});

  final String text;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primary)),
        ),
        const SizedBox(width: 10),
        Text(text, style: AstraKit.mutedText(_isDark, fontSize: 12.5)),
      ],
    );
  }
}

/// The cached AI reflection — a soft "AI Insight" label keeps it visually
/// distinct from the tappable local symbol chips above it, so it's clear
/// this line came from an optional AI call rather than the local dictionary.
class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.text, required this.label, required this.primary});

  final String text;
  final String label;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: primary.withValues(alpha: 0.10),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 13, color: primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AstraKit.label(_isDark, fontSize: 10.5).copyWith(letterSpacing: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: AstraKit.body(_isDark, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)
                .copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _WarmErrorBanner extends StatelessWidget {
  const _WarmErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    const errorColor = Color(0xFFE07A7A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: errorColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined, size: 15, color: errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AstraKit.body(_isDark, fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _InterpretButton extends StatelessWidget {
  const _InterpretButton({required this.label, required this.primary, required this.onTap});

  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: primary.withValues(alpha: 0.12),
            border: Border.all(color: primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 13, color: primary),
              const SizedBox(width: 6),
              Text(label, style: AstraKit.body(_isDark, fontSize: 12, fontWeight: FontWeight.w700, color: primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small tappable tag naming a detected symbol — tapping opens a brief
/// popover with its gentle association.
class _SymbolChip extends StatelessWidget {
  const _SymbolChip({required this.symbolKey, required this.copy, required this.primary});

  final String symbolKey;
  final DreamSymbolCopy copy;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showSymbolPopover(context, copy, primary),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: primary.withValues(alpha: 0.14),
            border: Border.all(color: primary.withValues(alpha: 0.4)),
          ),
          child: Text(copy.label, style: AstraKit.body(_isDark, fontSize: 11.5, fontWeight: FontWeight.w700, color: primary)),
        ),
      ),
    );
  }
}

void _showSymbolPopover(BuildContext context, DreamSymbolCopy copy, Color primary) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: AstraGlassCard(
        isDark: _isDark,
        primaryColor: primary,
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.label, style: AstraKit.body(_isDark, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(copy.description, style: AstraKit.mutedText(_isDark, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}

/// Small decorative moon that visually waxes as the dream count grows —
/// new moon at 0-2 entries, growing crescent at 3-6, half moon at 7-14,
/// full moon at 15+. Purely charming, not a real feature.
class _MoonPhaseIcon extends StatelessWidget {
  const _MoonPhaseIcon({required this.dreamCount, required this.primary});

  final int dreamCount;
  final Color primary;

  double get _litFraction {
    if (dreamCount <= 2) return 0.12;
    if (dreamCount <= 6) return 0.42;
    if (dreamCount <= 14) return 0.75;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _MoonPhasePainter(_litFraction, primary)),
    );
  }
}

class _MoonPhasePainter extends CustomPainter {
  const _MoonPhasePainter(this.litFraction, this.primary);

  final double litFraction;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primary.withValues(alpha: 0.35);
    canvas.drawCircle(center, radius - 0.5, basePaint);

    canvas.saveLayer(Rect.fromCircle(center: center, radius: radius), Paint());
    canvas.drawCircle(center, radius, Paint()..color = primary);
    if (litFraction < 0.98) {
      final dx = radius * (2 * (1 - litFraction));
      canvas.drawCircle(
        center.translate(dx, 0),
        radius,
        Paint()..blendMode = BlendMode.dstOut,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MoonPhasePainter oldDelegate) =>
      oldDelegate.litFraction != litFraction || oldDelegate.primary != primary;
}
