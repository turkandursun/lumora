import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/crisis_region_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'luma_glass_theme.dart';

/// Calm, non-alarming crisis support resource sheet — triggered purely by
/// local keyword detection (see `CrisisDetectionService`) on journal
/// entries and Luma chat messages, independent of any network/AI call so
/// it always appears instantly, even offline. Never blocks the app: it's
/// a standard dismissible bottom sheet with an explicit continue action.
/// Restyled onto the app's current [LumaGlass] theme (theme-adaptive).
class CrisisSupportSheet extends StatelessWidget {
  const CrisisSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CrisisSupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final region = detectCrisisRegion();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 40, 0, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [LumaGlass.bgTop(context), LumaGlass.bgBottom(context)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: LumaGlass.sparkle(context).withValues(alpha: 0.3)),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LumaGlass.subtitle(context).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _GlowIcon(),
                const SizedBox(height: 16),
                Text(
                  l10n.crisisSupportOpeningLine,
                  style: LumaGlass.sans(context,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: LumaGlass.cardTitle(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.crisisSupportSubtitle,
                  style: LumaGlass.sans(context,
                      fontSize: 14, color: LumaGlass.subtitle(context)),
                ),
                const SizedBox(height: 22),
                ..._resourcesFor(region, l10n),
                const SizedBox(height: 6),
                Text(
                  l10n.crisisSupportDisclaimer,
                  style: LumaGlass.sans(context,
                      fontSize: 12.5, color: LumaGlass.hint(context)),
                ),
                const SizedBox(height: 20),
                _ContinueButton(
                  label: l10n.crisisSupportContinueButton,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _resourcesFor(CrisisRegion region, AppLocalizations l10n) {
    switch (region) {
      case CrisisRegion.turkey:
        return [
          _ResourceCard(
            icon: Icons.local_phone_rounded,
            label: l10n.crisisResourceTurkeyEmergencyLabel,
            onTap: () => _call('112'),
          ),
          const SizedBox(height: 10),
          _ResourceCard(
            icon: Icons.local_phone_rounded,
            label: l10n.crisisResourceTurkeySocialSupportLabel,
            onTap: () => _call('183'),
          ),
          const SizedBox(height: 10),
        ];
      case CrisisRegion.unitedStates:
        return [
          _ResourceCard(
            icon: Icons.local_phone_rounded,
            label: l10n.crisisResourceUsLabel,
            onTap: () => _call('988'),
          ),
          const SizedBox(height: 10),
        ];
      case CrisisRegion.other:
        return [
          _ResourceCard(
            icon: Icons.language_rounded,
            label: l10n.crisisResourceFindAHelplineLabel,
            description: l10n.crisisResourceFindAHelplineDesc,
            onTap: _openFindAHelpline,
          ),
          const SizedBox(height: 10),
        ];
    }
  }

  static Future<void> _call(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(uri);
    } catch (_) {
      // Nothing sensible to surface if the platform can't place a call
      // (e.g. no telephony) — the number is still visible on the card.
    }
  }

  static Future<void> _openFindAHelpline() async {
    final uri = Uri.parse('https://findahelpline.com');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing sensible to surface if no browser is available.
    }
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: LumaGlass.accentGradient(context)),
        boxShadow: [
          BoxShadow(
            color: LumaGlass.accentShadow(context),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(Icons.favorite_rounded,
          color: LumaGlass.accentInk(context), size: 22),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String label;
  final String? description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: LumaGlass.glassFillTop(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LumaGlass.glassBorder(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      LinearGradient(colors: LumaGlass.accentGradient(context)),
                ),
                child: Icon(icon, color: LumaGlass.accentInk(context), size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: LumaGlass.sans(context,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: LumaGlass.cardTitle(context)),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        description!,
                        style: LumaGlass.sans(context,
                            fontSize: 12, color: LumaGlass.subtitle(context)),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: LumaGlass.sparkle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LumaGlass.glassBorder(context)),
          ),
          child: Text(
            label,
            style: LumaGlass.sans(context,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: LumaGlass.ink(context)),
          ),
        ),
      ),
    );
  }
}
