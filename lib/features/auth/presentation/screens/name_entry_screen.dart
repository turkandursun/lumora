import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/astra_theme_provider.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/responsive_content.dart';
import '../../../profile/data/profile_repository.dart';
import '../../domain/auth_flow_routes.dart';

/// Asked right after a fresh e-mail sign-up: a single "what should we call you?"
/// field, kept out of the sign-up panel so that screen stays short enough to
/// show the ASTRA wordmark + tagline. Saving is best-effort; the flow always
/// continues into the storytelling onboarding.
class NameEntryScreen extends ConsumerStatefulWidget {
  const NameEntryScreen({super.key});

  @override
  ConsumerState<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends ConsumerState<NameEntryScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      try {
        await ProfileRepository().updateFullName(name);
      } catch (_) {
        // Best-effort: never block onboarding on the nickname save.
      }
    }
    if (!mounted) return;
    context.go(AuthFlowRoutes.afterNameEntry, extra: true);
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final gold = AstraKit.gold(isDark);

    final bgAsset = isDark
        ? 'assets/images/astra_entry_bg.png'
        : 'assets/images/astra_sun_entry_g3.png';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'astra_bg',
            child: Image.asset(bgAsset, fit: BoxFit.cover),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ResponsiveContent(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(),
                              AstraGlassCard(
                                isDark: isDark,
                                primaryColor: gold,
                                borderRadius: 24,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 22, 20, 20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      isTr
                                          ? 'Sana nasıl hitap edelim?'
                                          : 'What should we call you?',
                                      textAlign: TextAlign.center,
                                      style: AstraKit.heading1(isDark,
                                          fontSize: 20),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isTr
                                          ? 'İstersen sonra profilinden değiştirebilirsin.'
                                          : 'You can change it later from your profile.',
                                      textAlign: TextAlign.center,
                                      style: AstraKit.mutedText(isDark,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 18),
                                    AstraTextField(
                                      isDark: isDark,
                                      primaryColor: gold,
                                      label: isTr ? 'Adınız' : 'Your Name',
                                      controller: _nameController,
                                      keyboardType: TextInputType.name,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [AutofillHints.name],
                                      onFieldSubmitted: (_) => _continue(),
                                    ),
                                    const SizedBox(height: 20),
                                    AstraGoldButton(
                                      isDark: isDark,
                                      forceGold: true,
                                      label: isTr ? 'Devam et' : 'Continue',
                                      isLoading: _saving,
                                      onTap: _continue,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
