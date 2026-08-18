import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_glass_theme.dart';
import '../screens/journal_entry_screen.dart';

/// Gentle, inviting prompts encouraging the user to write down their thoughts.
const _promptsTr = [
  'Bugün zihninden neler geçiyor? Hislerini kaleme al...',
  'Bugün kendini nasıl hissediyorsun? Birkaç cümle yaz...',
  'İç dünyana küçük bir yolculuk yap, günlüğünü doldur...',
  'Bugün seni gülümseten ya da düşündüren ne oldu?',
];

const _promptsEn = [
  "What's on your mind today? Write down your feelings...",
  'How are you feeling today? Put down a few sentences...',
  'Take a small journey inside yourself and write a note...',
  'What made you smile or pause to think today?',
];

/// The main Journal Writing hero card on Home, positioned right between the
/// motivation quote carousel and the dream journal banner. Restyled
/// (Aug 2026) onto the fixed [LumaGlass] pink glass theme — layout/content
/// unchanged from the original card.
class HomeStatsRow extends ConsumerWidget {
  const HomeStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    // Rotate prompt gently by hour of day
    final promptIndex = DateTime.now().hour % _promptsTr.length;
    final promptText = isTr ? _promptsTr[promptIndex] : _promptsEn[promptIndex];

    return AstraMorphContainer(
      borderRadius: 24,
      openBuilder: (_) => const JournalEntryScreen(),
      closedBuilder: (context, open) => BouncyTap(
      onTap: open,
      child: LumaGlassCard(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // Glowing pencil/book emblem
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: LumaGlass.accentGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LumaGlass.accentShadow,
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Title + Inviting Prompt Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            l10n.homeFeatureJournalTitle,
                            style: LumaGlass.sans(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: LumaGlass.cardTitle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('✨', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promptText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LumaGlass.sans(fontSize: 12.5, color: LumaGlass.subtitle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Action Arrow Button / Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: LumaGlass.sparkle.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: LumaGlass.sparkle.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isTr ? 'Yaz' : 'Write',
                        style: LumaGlass.sans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: LumaGlass.accentInk,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: LumaGlass.accentInk,
                      ),
                    ],
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
