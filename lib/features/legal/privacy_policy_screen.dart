import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/astra_theme_provider.dart';
import '../../theme/astra_screen_kit.dart';
import 'privacy_policy_text.dart';

/// Full, scrollable privacy policy — reachable from the consent screen and the
/// profile, and mirrored by the hostable HTML used for the store listing URL.
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final primary = AstraKit.primary(context, isDark);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(
                      isTr ? 'Gizlilik Politikası' : 'Privacy Policy',
                      style: AstraKit.heading1(context, isDark, fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: AstraGlassCard(
                      isDark: isDark,
                      primaryColor: primary,
                      child: Text(
                        isTr ? privacyPolicyTr : privacyPolicyEn,
                        style: AstraKit.body(context, isDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.5),
                      ),
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
