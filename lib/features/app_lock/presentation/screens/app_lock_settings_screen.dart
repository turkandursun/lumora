import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../domain/app_section.dart';
import '../providers/app_lock_providers.dart';
import '../widgets/section_lock_gate.dart';
import 'pin_setup_screen.dart';
import 'pin_verify_screen.dart';

/// PIN screens stay night-themed regardless of the app's light/dark choice
/// — same reasoning as the dream journal.
const _isDark = true;

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
    final primary = AstraKit.primary(_isDark);

    final hasPin = hasPinAsync.valueOrNull ?? false;
    final protectedSections = protectedAsync.valueOrNull ?? const <AppSection>{};
    final loading = hasPinAsync.isLoading || protectedAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AstraMountainBackground(
        isDark: _isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AstraCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      isDark: _isDark,
                      primaryColor: primary,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.appLockTitle, style: AstraKit.heading1(_isDark, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 12),
                if (loading)
                  Expanded(child: Center(child: CircularProgressIndicator(color: primary)))
                else
                  Expanded(
                    child: ListView(
                      children: [
                        _SectionHeading(text: l10n.appLockPinSectionHeading),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.password_rounded,
                          label: hasPin ? l10n.appLockChangePinLabel : l10n.appLockSetPinLabel,
                          primary: primary,
                          onTap: () =>
                              hasPin ? _onChangePin(context, ref) : _onSetPin(context, ref),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeading(text: l10n.appLockSectionsHeading),
                        if (!hasPin) ...[
                          const SizedBox(height: 8),
                          Text(l10n.appLockSectionsHint, style: AstraKit.mutedText(_isDark, fontSize: 12.5)),
                        ],
                        const SizedBox(height: 10),
                        for (final section in _sections) ...[
                          _ToggleRow(
                            icon: _sectionIcons[section]!,
                            label: sectionDisplayName(l10n, section),
                            value: protectedSections.contains(section),
                            enabled: hasPin,
                            primary: primary,
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
    return Text(text, style: AstraKit.mutedText(_isDark, fontSize: 13, fontWeight: FontWeight.w700));
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.primary,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final Color primary;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.45;
    return Opacity(
      opacity: opacity,
      child: AstraGlassCard(
        isDark: _isDark,
        primaryColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        borderRadius: 18,
        child: Row(
          children: [
            Icon(icon, color: primary, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AstraKit.body(_isDark, fontSize: 15, fontWeight: FontWeight.w600))),
            Switch(value: value, activeThumbColor: primary, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.primary, required this.onTap});

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AstraGlassCard(
      isDark: _isDark,
      primaryColor: primary,
      padding: EdgeInsets.zero,
      borderRadius: 18,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AstraKit.body(_isDark, fontSize: 15, fontWeight: FontWeight.w600))),
                Icon(Icons.chevron_right_rounded, color: AstraKit.muted(_isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
