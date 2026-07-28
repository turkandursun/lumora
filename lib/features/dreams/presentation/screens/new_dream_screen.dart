import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/lumora_palette.dart';
import '../../../../theme/dream_pastel_background.dart';
import '../../../../theme/responsive_content.dart';
import '../providers/dreams_providers.dart';

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
      backgroundColor: LumoraPalette.nightBackground,
      body: DreamPastelBackground(
        child: SafeArea(
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                      Text(
                        l10n.dreamEntryTitle,
                        style: AppTheme.displayFont(fontSize: 20, color: Colors.white),
                      ),
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
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _error != null
                                    ? LumoraPalette.accentPink.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              style: LumoraPalette.bodyStyle(color: Colors.white),
                              cursorColor: LumoraPalette.lightPurple,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                // Don't inherit the light theme's filled
                                // softLavender fill — keep the field
                                // transparent so the dark translucent card
                                // (and the dream motifs behind it) show
                                // through and the white text stays readable.
                                filled: false,
                                hintText: l10n.dreamEntryPlaceholder,
                                hintStyle: LumoraPalette.bodyStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              onChanged: (_) {
                                if (_error != null) setState(() => _error = null);
                              },
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: AppTheme.bodyFont(
                              fontSize: 12.5,
                              color: LumoraPalette.accentPink,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _SaveButton(
                          label: l10n.dreamEntrySaveButton,
                          isSaving: _isSaving,
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.isSaving, required this.onTap});

  final String label;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: LumoraPalette.ctaGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: LumoraPalette.primaryPurple.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: isSaving ? null : onTap,
          child: Center(
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: LumoraPalette.bodyStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
