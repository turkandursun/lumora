import 'package:flutter/material.dart';

import '../../../../theme/lumora_palette.dart';
import '../../../../theme/sakura_home_palette.dart';

/// A single storytelling beat within onboarding: an illustration medallion,
/// an optional wordmark eyebrow, a headline, and a body line. Shared by
/// every page in [OnboardingScreen] so new beats are just new content.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.illustration,
    required this.title,
    required this.body,
    this.eyebrow,
  });

  final Widget illustration;
  final String title;
  final String body;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IllustrationMedallion(child: illustration),
          const SizedBox(height: 36),
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              textAlign: TextAlign.center,
              style: LumoraPalette.taglineStyle(
                fontSize: 13,
                color: SakuraHomePalette.textDeep.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: LumoraPalette.storyTitleStyle(
              color: SakuraHomePalette.textDeep,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: LumoraPalette.bodyStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w400,
              color: SakuraHomePalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted glass circle that frames each page's icon/illustration, giving
/// the icon a bright, defined disc to sit on against the pastel photo
/// backdrops.
class _IllustrationMedallion extends StatelessWidget {
  const _IllustrationMedallion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: LumoraPalette.primaryPurple.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
