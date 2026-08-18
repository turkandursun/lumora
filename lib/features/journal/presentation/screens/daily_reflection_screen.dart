import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../theme/astra_screen_kit.dart';
import '../../../../theme/luma_avatar.dart';
import '../../../../theme/mood_gradients.dart';
import '../../../../theme/mood_theme_provider.dart';
import '../../../auth/domain/auth_flow_routes.dart';
import '../../../auth/domain/registration_flow_state.dart';
import '../providers/journal_entries_provider.dart';

/// Shown right after the mood check-in: "Why do you feel this way today?".
/// A short, gentle journaling beat — what the user writes is saved to their
/// journal, then they land on Home. Fully themed with the selected palette.
class DailyReflectionScreen extends ConsumerStatefulWidget {
  const DailyReflectionScreen({
    super.key,
    this.routeData = const DailyReflectionRouteData(
      DailyReflectionFlow.standalone,
    ),
  });

  final DailyReflectionRouteData routeData;

  @override
  ConsumerState<DailyReflectionScreen> createState() =>
      _DailyReflectionScreenState();
}

class _DailyReflectionScreenState extends ConsumerState<DailyReflectionScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continueToDestination() async {
    if (!mounted) return;
    final current = widget.routeData.registrationIntent;
    if (widget.routeData.flow != DailyReflectionFlow.signup ||
        current == null) {
      context.go(AppRoutes.home);
      return;
    }
    try {
      final next = await registrationFlowStore.advance(
        current,
        RegistrationStep.hobbies,
      );
      if (!mounted) return;
      context.go(AuthFlowRoutes.afterSignupDailyReflection, extra: next);
    } on RegistrationIntentMismatchException {
      if (mounted) context.go(AppRoutes.home);
    }
  }

  Future<void> _saveAndContinue() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      await _continueToDestination();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(journalEntriesRepositoryProvider).save(
            text,
            title: null,
          );
    } catch (_) {
      // Never block the hand-off to Home on a save hiccup.
    }
    await _continueToDestination();
  }

  /// The mood-specific question, e.g. "Bugün neden mutlu hissediyorsun?".
  String _prompt(AppMood? mood, bool isTr) {
    if (mood == null) {
      return isTr ? 'Bugün nasıl hissediyorsun?' : 'How do you feel today?';
    }
    const tr = {
      AppMood.happy: 'mutlu',
      AppMood.calm: 'sakin',
      AppMood.tired: 'yorgun',
      AppMood.sad: 'üzgün',
      AppMood.anxious: 'endişeli',
    };
    const en = {
      AppMood.happy: 'happy',
      AppMood.calm: 'calm',
      AppMood.tired: 'tired',
      AppMood.sad: 'sad',
      AppMood.anxious: 'anxious',
    };
    return isTr
        ? 'Bugün neden ${tr[mood]} hissediyorsun?'
        : 'Why do you feel ${en[mood]} today?';
  }

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final primary = AstraKit.primary(context, false);
    final mood = ref.watch(moodThemeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AstraMountainBackground(
        isDark: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const AstraEntrance(
                  index: 0,
                  intervalMs: 130,
                  offset: 20,
                  child: LumaAvatar(size: 96),
                ),
                const SizedBox(height: 20),
                AstraEntrance(
                  index: 1,
                  intervalMs: 130,
                  offset: 20,
                  child: Text(
                    _prompt(mood, isTr),
                    textAlign: TextAlign.center,
                    style: AstraKit.heading1(context, false, fontSize: 24)
                        .copyWith(height: 1.25),
                  ),
                ),
                const SizedBox(height: 10),
                AstraEntrance(
                  index: 2,
                  intervalMs: 130,
                  offset: 20,
                  child: Text(
                    isTr
                        ? 'İstersen birkaç cümle yaz. Burası tamamen sana ait.'
                        : 'Write a few lines if you like. This space is yours.',
                    textAlign: TextAlign.center,
                    style: AstraKit.mutedText(context, false, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AstraGlassCard(
                    isDark: false,
                    primaryColor: primary,
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: _controller,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      cursorColor: primary,
                      style: AstraKit.body(context, false,
                          fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: isTr
                            ? 'Bugün içinden geçenler…'
                            : "What's on your mind today…",
                        hintStyle:
                            AstraKit.mutedText(context, false, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AstraGoldButton(
                  isDark: false,
                  label: isTr ? 'Kaydet ve devam et' : 'Save & continue',
                  isLoading: _saving,
                  onTap: _saveAndContinue,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : _continueToDestination,
                  child: Text(
                    isTr ? 'Şimdilik geç' : 'Skip for now',
                    style: AstraKit.mutedText(context, false, fontSize: 13.5)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
