import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'astra_screen_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/providers/astra_theme_provider.dart';
import '../core/services/ai_service.dart';
import '../core/services/crisis_detection_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'crisis_support_sheet.dart';
import 'luma_avatar.dart';
import 'lumora_palette.dart';

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Theme-aware colours for Luma's chat sheet, so the panel matches the app's
/// moon (violet-on-night) / sun (gold-on-cream) themes instead of always
/// painting the dark night surface.
class _ChatPalette {
  const _ChatPalette(this.isDark);

  final bool isDark;

  /// Sheet surface: the deep night purple on the moon theme, a warm cream on
  /// the sun theme (so it never sits as a dark slab over the bright scene).
  Color get sheet =>
      isDark ? const Color(0xFF1A1330) : const Color(0xFFFBF3E4);

  /// Luma's star accent — violet at night, gold in daylight.
  Color get star =>
      isDark ? LumoraPalette.lightPurple : AstraKit.gold(isDark);

  Color get heading => AstraKit.heading(isDark);
  Color get body => AstraKit.ink(isDark);
  Color get muted => AstraKit.muted(isDark);
  Color get handle => AstraKit.faint(isDark);

  /// Incoming (Luma) bubble surface + hairline.
  Color get botBubble =>
      isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.72);
  Color get botBorder => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : AstraKit.primary(isDark).withValues(alpha: 0.22);

  /// Outgoing (user) bubble gradient + its text colour.
  List<Color> get userGradient => isDark
      ? LumoraPalette.ctaGradient
      : const [Color(0xFFF0D68A), Color(0xFFB8860B)];
  Color get userText => isDark ? Colors.white : const Color(0xFF1A0F00);

  /// Input field surface + hairline.
  Color get inputFill =>
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.66);
  Color get inputBorder => isDark
      ? Colors.white.withValues(alpha: 0.14)
      : AstraKit.primary(isDark).withValues(alpha: 0.3);

  /// Send button gradient + glow + icon.
  List<Color> get sendGradient => isDark
      ? LumoraPalette.ctaGradient
      : const [Color(0xFFF0D68A), Color(0xFFB8860B)];
  Color get sendGlow => isDark ? LumoraPalette.primaryPurple : AstraKit.gold(isDark);
  Color get sendIcon => isDark ? Colors.white : const Color(0xFF1A0F00);

  /// Crisis/error banner text.
  Color get bannerText => isDark ? LumoraPalette.warmCream : const Color(0xFF7A3350);
}

/// Lightweight session-only chat panel for talking to Luma — opened as a
/// bottom sheet from [LumaCompanion]'s speech bubble. Conversation history
/// is not persisted: it lives only in this widget's state and is gone once
/// the sheet closes.
class LumaChatSheet extends ConsumerStatefulWidget {
  const LumaChatSheet({super.key, this.moodContext});

  final String? moodContext;

  static Future<void> show(BuildContext context, {String? moodContext}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LumaChatSheet(moodContext: moodContext),
    );
  }

  @override
  ConsumerState<LumaChatSheet> createState() => _LumaChatSheetState();
}

class _LumaChatSheetState extends ConsumerState<LumaChatSheet> {
  final _aiService = AiService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];

  bool _isSending = false;
  bool _hasError = false;
  bool _sessionReady = Supabase.instance.client.auth.currentSession != null;

  // Drives Luma's mouth animation while she "speaks" her reply.
  bool _lumaTalking = false;
  Timer? _talkTimer;

  @override
  void initState() {
    super.initState();
    if (!_sessionReady) {
      _waitForSession();
    }
  }

  Future<void> _waitForSession() async {
    final ready = await _aiService.ensureSessionReady();
    if (!mounted) return;
    setState(() => _sessionReady = ready);
  }

  @override
  void dispose() {
    _talkTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    debugPrint('[LumaChat] send button tapped');
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending || !_sessionReady) return;

    final languageCode = Localizations.localeOf(context).languageCode == 'tr' ? 'tr' : 'en';

    // Local, offline keyword check — shown immediately, before the network
    // call to Luma even starts, so it appears whether or not the AI
    // response ever comes back.
    if (CrisisDetectionService.containsCrisisLanguage(text)) {
      CrisisSupportSheet.show(context);
    }

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _inputController.clear();
      _isSending = true;
      _hasError = false;
    });
    _scrollToBottom();

    try {
      final reply = await _aiService.sendLumaMessage(
        message: text,
        language: languageCode,
        context: widget.moodContext,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
        _isSending = false;
        _lumaTalking = true;
      });
      // Keep her mouth moving briefly, as if speaking the reply — longer for
      // longer answers, capped so it never drags.
      _talkTimer?.cancel();
      final talkMs = (reply.length * 45).clamp(900, 3500);
      _talkTimer = Timer(Duration(milliseconds: talkMs), () {
        if (mounted) setState(() => _lumaTalking = false);
      });
    } catch (e) {
      debugPrint('[LumaChat] _send caught error: $e');
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _hasError = true;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = ref.watch(astraThemeProvider) == AstraThemeMode.dark;
    final palette = _ChatPalette(isDark);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Container(
          decoration: BoxDecoration(
            color: palette.sheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _Header(title: l10n.lumaChatTitle, palette: palette),
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyState(text: l10n.lumaChatEmptyState, palette: palette)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          itemCount: _messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return AstraEntrance(
                                offset: 16,
                                scaleFrom: 0.96,
                                child: _ThinkingBubble(text: l10n.lumaChatThinking, palette: palette),
                              );
                            }
                            final message = _messages[index];
<<<<<<< Updated upstream
                            final isLatestLuma = !message.isUser &&
                                index == _messages.length - 1 &&
                                !_isSending;
                            return _MessageBubble(
                              message: message,
                              animateAvatar: isLatestLuma,
                              speaking: _lumaTalking,
                            );
=======
                            return _MessageBubble(message: message, palette: palette);
>>>>>>> Stashed changes
                          },
                        ),
                ),
                if (_hasError) _ErrorBanner(text: l10n.lumaChatError, palette: palette),
                _InputBar(
                  controller: _inputController,
                  hint: _sessionReady ? l10n.lumaChatInputHint : l10n.lumaChatSessionLoading,
                  enabled: !_isSending && _sessionReady,
                  onSend: _send,
                  palette: palette,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Luma's face: a soft, twinkling star. Reused at different sizes across
/// the chat so the whole conversation feels like talking to one character.
class _LumaStar extends StatefulWidget {
  const _LumaStar({this.size = 26, this.accent = LumoraPalette.lightPurple});

  final double size;

  /// Star glow / gradient tint — violet on the moon theme, gold on the sun
  /// theme, so Luma's face matches the active theme.
  final Color accent;

  @override
  State<_LumaStar> createState() => _LumaStarState();
}

class _LumaStarState extends State<_LumaStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle;

  @override
  void initState() {
    super.initState();
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.35,
      height: s * 1.35,
      child: AnimatedBuilder(
        animation: _twinkle,
        builder: (context, _) {
          final t = _twinkle.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s * 0.9,
                height: s * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent
                          .withValues(alpha: 0.35 + 0.35 * t),
                      blurRadius: 10 + t * 10,
                      spreadRadius: 1 + t * 2,
                    ),
                  ],
                ),
              ),
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [
                    LumoraPalette.warmCream,
                    widget.accent,
                  ],
                ).createShader(rect),
                child: Icon(Icons.star_rounded, size: s, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.palette});

  final String title;
  final _ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: palette.handle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
<<<<<<< Updated upstream
=======
              _LumaStar(size: 28, accent: palette.star),
              const SizedBox(width: 8),
>>>>>>> Stashed changes
              Expanded(
                child: Text(
                  title,
                  style: LumoraPalette.bodyStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: palette.muted),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text, required this.palette});

  final String text;
  final _ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
<<<<<<< Updated upstream
            const LumaAvatar(size: 96),
=======
            _LumaStar(size: 66, accent: palette.star),
>>>>>>> Stashed changes
            const SizedBox(height: 18),
            Text(
              isTr ? 'Merhaba, ben Luma ✨' : "Hi, I'm Luma ✨",
              textAlign: TextAlign.center,
              style: LumoraPalette.storyTitleStyle(fontSize: 21, color: palette.heading),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: LumoraPalette.bodyStyle(
                fontSize: 14,
                color: palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
<<<<<<< Updated upstream
  const _MessageBubble({
    required this.message,
    this.animateAvatar = false,
    this.speaking = false,
  });
=======
  const _MessageBubble({required this.message, required this.palette});
>>>>>>> Stashed changes

  final _ChatMessage message;
  final _ChatPalette palette;

  /// When true, Luma's animated star avatar (mouth-flap) is shown beside this
  /// bubble instead of the small static star — used for her latest reply.
  final bool animateAvatar;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(colors: palette.userGradient)
            : null,
        color: isUser ? null : palette.botBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser ? null : Border.all(color: palette.botBorder),
      ),
      child: Text(
        message.text,
        style: LumoraPalette.bodyStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isUser ? palette.userText : palette.body,
        ),
      ),
    );

    if (isUser) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
<<<<<<< Updated upstream
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: animateAvatar
                ? LumaAvatar(size: 46, speaking: speaking)
                : const LumaAvatar(size: 30),
=======
            padding: const EdgeInsets.only(right: 8, bottom: 6),
            child: _LumaStar(size: 22, accent: palette.star),
>>>>>>> Stashed changes
          ),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.text, required this.palette});

  final String text;
  final _ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, bottom: 4),
            child: LumaAvatar(size: 46, speaking: true),
          ),
          Flexible(
            child: _ThinkingBubbleBody(text: text),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubbleBody extends StatelessWidget {
  const _ThinkingBubbleBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.botBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: palette.botBorder),
        ),
        child: Text(
          text,
          style: LumoraPalette.bodyStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: palette.muted,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text, required this.palette});

  final String text;
  final _ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LumoraPalette.accentPink.withValues(alpha: palette.isDark ? 0.14 : 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LumoraPalette.accentPink.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.spa_outlined, size: 16, color: palette.bannerText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: LumoraPalette.bodyStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: palette.bannerText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.onSend,
    required this.palette,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final VoidCallback onSend;
  final _ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: palette.inputFill,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: palette.inputBorder),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: LumoraPalette.bodyStyle(fontSize: 14.5, color: palette.body),
                cursorColor: palette.star,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  // Keep transparent so our own theme-aware field surface shows
                  // through instead of the global TextField fill.
                  filled: false,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: LumoraPalette.bodyStyle(
                    fontSize: 14.5,
                    color: palette.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(enabled: enabled, onTap: onSend, palette: palette),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap, required this.palette});

  final bool enabled;
  final VoidCallback onTap;
  final _ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: palette.sendGradient),
        boxShadow: [
          BoxShadow(
            color: palette.sendGlow.withValues(alpha: enabled ? 0.45 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Icon(Icons.arrow_upward_rounded, color: palette.sendIcon, size: 20),
        ),
      ),
    );
  }
}
