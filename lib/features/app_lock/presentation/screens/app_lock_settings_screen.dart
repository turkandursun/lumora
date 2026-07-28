import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/mood_gradient_background.dart';
import '../../domain/app_section.dart';
import '../providers/app_lock_providers.dart';
import '../widgets/section_lock_gate.dart';
import 'pin_setup_screen.dart';
import 'pin_verify_screen.dart';

/// Privacy & Security settings — the screen Profile's menu item opens. Lets
/// the user set a single PIN (one-time setup, changeable afterwards) and
/// choose which sections of the app that PIN protects. A section left
/// toggled off is reached with no PIN prompt at all.
class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  static const _sections = [
    AppSection.journalWriting,
    AppSection.aiChat,
    AppSection.dreamJournal,
  ];

  static const _sectionIcons = {
    AppSection.journalWriting: Icons.edit_note_rounded,
    AppSection.aiChat: Icons.chat_bubble_rounded,
    AppSection.dreamJournal: Icons.nights_stay_rounded,
  };

  Future<void> _onSetPin(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (created == true) ref.invalidate(hasPinProvider);
  }

  Future<void> _onChangePin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PinVerifyScreen(title: l10n.appLockVerifyCurrentPinTitle),
      ),
    );
    if (verified != true || !context.mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appLockPinUpdatedMessage)),
      );
    }
  }

  Future<void> _onSectionToggled(WidgetRef ref, AppSection section, bool value) async {
    await ref.read(appLockServiceProvider).setSectionProtected(section, value);
    ref.invalidate(protectedSectionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasPinAsync = ref.watch(hasPinProvider);
    final protectedAsync = ref.watch(protectedSectionsProvider);

    final hasPin = hasPinAsync.valueOrNull ?? false;
    final protectedSections = protectedAsync.valueOrNull ?? const <AppSection>{};
    final loading = hasPinAsync.isLoading || protectedAsync.isLoading;

    return Scaffold(
      backgroundColor: LumoraPalette.nightBackground,
      body: MoodGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      l10n.appLockTitle,
                      style: AppTheme.displayFont(fontSize: 22, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        _SectionHeading(text: l10n.appLockPinSectionHeading),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.password_rounded,
                          label: hasPin ? l10n.appLockChangePinLabel : l10n.appLockSetPinLabel,
                          onTap: () =>
                              hasPin ? _onChangePin(context, ref) : _onSetPin(context, ref),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeading(text: l10n.appLockSectionsHeading),
                        if (!hasPin) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.appLockSectionsHint,
                            style: AppTheme.bodyFont(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        for (final section in _sections) ...[
                          _ToggleRow(
                            icon: _sectionIcons[section]!,
                            label: sectionDisplayName(l10n, section),
                            value: protectedSections.contains(section),
                            enabled: hasPin,
                            onChanged: (value) => _onSectionToggled(ref, section, value),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.bodyFont(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyFont(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: LumoraPalette.primaryPurple,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodyFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
