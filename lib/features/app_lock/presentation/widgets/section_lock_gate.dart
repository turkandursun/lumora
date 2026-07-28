import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/app_section.dart';
import '../providers/app_lock_providers.dart';
import '../screens/pin_verify_screen.dart';

/// This section's localized display name — shown in the settings toggle
/// list and interpolated into its PIN-entry heading.
String sectionDisplayName(AppLocalizations l10n, AppSection section) {
  switch (section) {
    case AppSection.journalWriting:
      return l10n.appLockSectionJournalWriting;
    case AppSection.aiChat:
      return l10n.appLockSectionAiChat;
    case AppSection.dreamJournal:
      return l10n.appLockSectionDreamJournal;
  }
}

/// Genuine navigation guard for routes/tabs backed by go_router or an
/// [IndexedStack]: renders [builder]'s real content, unless [section] is
/// both PIN-protected and not yet unlocked this session, in which case it
/// renders [PinVerifyScreen] in its place — the protected content is never
/// built at all.
class SectionLockGate extends ConsumerWidget {
  const SectionLockGate({super.key, required this.section, required this.builder});

  final AppSection section;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedSections = ref.watch(sectionUnlockProvider);
    if (unlockedSections.contains(section)) return builder(context);

    final protectedSections = ref.watch(protectedSectionsProvider);
    return protectedSections.when(
      loading: () => const _SectionLockLoading(),
      error: (_, __) => builder(context),
      data: (sections) {
        if (!sections.contains(section)) return builder(context);
        final l10n = AppLocalizations.of(context);
        return PinVerifyScreen(
          title: l10n.appLockSectionUnlockTitle(sectionDisplayName(l10n, section)),
          dismissible: false,
          onSuccess: () => ref.read(sectionUnlockProvider.notifier).unlock(section),
        );
      },
    );
  }
}

class _SectionLockLoading extends StatelessWidget {
  const _SectionLockLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

/// Imperative counterpart to [SectionLockGate], for actions that open UI
/// outside go_router (e.g. a modal bottom sheet) rather than navigating to
/// a route. Returns `true` immediately if [section] isn't protected or is
/// already unlocked this session; otherwise pushes a dismissible PIN screen
/// and returns whether it was entered correctly.
Future<bool> ensureSectionUnlocked(
  BuildContext context,
  WidgetRef ref,
  AppSection section,
) async {
  if (ref.read(sectionUnlockProvider).contains(section)) return true;

  final protectedSections = await ref.read(appLockServiceProvider).getProtectedSections();
  if (!protectedSections.contains(section)) return true;
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context);
  final unlocked = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PinVerifyScreen(
        title: l10n.appLockSectionUnlockTitle(sectionDisplayName(l10n, section)),
      ),
    ),
  );

  if (unlocked == true) {
    ref.read(sectionUnlockProvider.notifier).unlock(section);
    return true;
  }
  return false;
}
