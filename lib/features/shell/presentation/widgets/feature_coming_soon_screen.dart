import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/mood_gradient_background.dart';

/// Everything [FeatureComingSoonScreen] needs to identify which not-yet-built
/// feature it's standing in for — passed as a route's `extra` since it's
/// simple UI data, not app state worth a provider.
class FeatureComingSoonArgs {
  const FeatureComingSoonArgs({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

/// Shared placeholder pushed for home-feature-grid entries that don't have
/// a real screen yet — shows the feature's own name and icon (rather than a
/// generic message) so it reads as "this is coming" instead of a dead end.
class FeatureComingSoonScreen extends StatelessWidget {
  const FeatureComingSoonScreen({super.key, required this.args});

  final FeatureComingSoonArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: LumoraPalette.nightBackground,
      body: MoodGradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Icon(args.icon, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  args.title,
                  style: AppTheme.displayFont(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    l10n.comingSoonBody,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyFont(
                      color: Colors.white.withValues(alpha: 0.72),
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
