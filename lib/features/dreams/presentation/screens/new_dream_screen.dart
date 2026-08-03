import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/dreams_providers.dart';

/// Dreams stay night-themed regardless of the app's light/dark choice — see
/// [DreamJournalScreen]'s `_isDark` for the same reasoning.
const _isDark = true;
final _primary = AstraKit.primary(_isDark);

/// Full-screen dream entry form: a large free-form text area plus a save
/// button. Pushed from [DreamJournalScreen]'s "Write a Dream" button.
/// Saving hands off to [DreamReflectionScreen] for its short optional
/// follow-up questions, replacing this screen in the stack so a later
/// "Skip"/"Finish" there pops straight back to the dream list.
class NewDreamScreen extends ConsumerStatefulWidget {
  const NewDreamScreen({super.key});

  @override
  ConsumerState<NewDreamScreen> createState() => _NewDreamScreenState();
}

class _NewDreamScreenState extends ConsumerState<NewDreamScreen> {
  final _controller = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = l10n.dreamEntryValidationEmpty);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final id = await ref.read(dreamsRepositoryProvider).addDream(text);

    if (!mounted) return;
    context.pushReplacement(AppRoutes.dreamReflection, extra: id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: [
                      AstraCircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        isDark: _isDark,
                        primaryColor: _primary,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(l10n.dreamEntryTitle, style: AstraKit.heading1(_isDark, fontSize: 20)),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AstraGlassCard(
                            isDark: _isDark,
                            primaryColor: _error != null ? const Color(0xFFE07A7A) : _primary,
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: AstraKit.body(_isDark),
                              cursorColor: _primary,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                filled: false,
                                hintText: l10n.dreamEntryPlaceholder,
                                hintStyle: AstraKit.mutedText(_isDark),
                              ),
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
                              },
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFE07A7A))),
                        ],
                        const SizedBox(height: 18),
                        AstraGoldButton(
                          isDark: _isDark,
                          label: l10n.dreamEntrySaveButton,
                          isLoading: _isSaving,
                          enabled: !_isSaving,
                          height: 56,
                          onTap: _save,
                        ),
                      ],
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
