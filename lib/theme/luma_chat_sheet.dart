import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/ai_service.dart';
import '../core/services/crisis_detection_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'astra_screen_kit.dart';
import 'astra_design_tokens.dart';
import 'crisis_support_sheet.dart';
import 'luma_avatar.dart';

class _Pink {
  _Pink._();

  static AstraPalette _p(BuildContext context) => AstraKit.palette(context);
  static AstraThemeTokens _tokens(BuildContext context) =>
      AstraThemeTokens.of(context);
  static Color bgTop(BuildContext context) => _p(context).gradientTop;
  static Color bgMid(BuildContext context) =>
      Color.lerp(_p(context).gradientTop, _p(context).gradientBottom, 0.5)!;
  static Color bgBottom(BuildContext context) => _p(context).gradientBottom;
  static Color wordmark(BuildContext context) => _p(context).secondary;
  static Color heroInk(BuildContext context) => _tokens(context).textPrimary;
  static Color subtitle(BuildContext context) => _tokens(context).textMuted;
  static Color footer(BuildContext context) => _tokens(context).textMuted;
  static Color cardFill(BuildContext context) =>
      _p(context).surfaceElevated.withValues(alpha: 0.9);
  static Color cardShadow(BuildContext context) => _p(context).focusGlow;
  static Color cardTitle(BuildContext context) => _tokens(context).textPrimary;
  static Color hint(BuildContext context) => _tokens(context).textMuted;
  static Color ink(BuildContext context) => _tokens(context).textSecondary;
  static Color sparkle(BuildContext context) => _p(context).activeAccent;
  static Color glassFillTop(BuildContext context) =>
      _p(context).surfaceElevated.withValues(alpha: 0.55);
  static Color glassFillBottom(BuildContext context) =>
      _p(context).surfaceElevated.withValues(alpha: 0.25);
  static Color glassBorder(BuildContext context) => _p(context).softBorder;
  static List<Color> micGradient(BuildContext context) =>
      [_p(context).buttonPrimary, _p(context).secondary];
  static Color micShadow(BuildContext context) => _p(context).focusGlow;
  static List<Color> userBubble(BuildContext context) =>
      [_p(context).buttonPrimary, _p(context).secondary];
  static Color lumaBubble(BuildContext context) =>
      _p(context).surfaceElevated.withValues(alpha: 0.9);
  static Color lumaBubbleBorder(BuildContext context) => _p(context).softBorder;

  static TextStyle sans(
    BuildContext context, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.manrope(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? ink(context),
        height: height,
        letterSpacing: letterSpacing,
      );
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Lightweight session-only chat panel for talking to Luma — opened as a
/// full-height sheet from [LumaCompanion]'s speech bubble. Conversation history
/// is not persisted: it lives only in this widget's state and is gone once
/// the sheet closes.
///
/// The empty/entry state is the "ASTRA AI" hero (pink gradient, brand
/// wordmark, three-line headline, and a single frosted-glass prompt card
/// holding just the text field — no extra action buttons). Once the first
/// message is sent it switches to the scrolling conversation view.
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
  final _inputFocus = FocusNode();
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
    _inputFocus.dispose();
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

    final languageCode =
        Localizations.localeOf(context).languageCode == 'tr' ? 'tr' : 'en';

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
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _Pink.bgTop(context),
                _Pink.bgMid(context),
                _Pink.bgBottom(context)
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: _messages.isEmpty
                ? _HeroEntry(
                    controller: _inputController,
                    focusNode: _inputFocus,
                    isTr: isTr,
                    enabled: !_isSending && _sessionReady,
                    hint: _sessionReady
                        ? (isTr
                            ? 'Düşüncelerini yaz...'
                            : 'Write your thoughts...')
                        : l10n.lumaChatSessionLoading,
                    onSubmitted: _send,
                  )
                : _ActiveChat(
                    messages: _messages,
                    scrollController: _scrollController,
                    controller: _inputController,
                    focusNode: _inputFocus,
                    isSending: _isSending,
                    hasError: _hasError,
                    lumaTalking: _lumaTalking,
                    thinkingText: l10n.lumaChatThinking,
                    errorText: l10n.lumaChatError,
                    hint: _sessionReady
                        ? l10n.lumaChatInputHint
                        : l10n.lumaChatSessionLoading,
                    enabled: !_isSending && _sessionReady,
                    onSend: _send,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A slim, low-opacity grab handle at the very top — the only dismissal
/// affordance on the hero (the sheet is swipe-to-dismiss). Kept faint so it
/// doesn't intrude on the reference's clean layout.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _Pink.wordmark(context).withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The empty/entry state: the ASTRA AI hero, replicated from the reference.
/// Vertical rhythm is expressed as ratios of the available height so the
/// proportions hold across screen sizes; the whole thing scrolls if the
/// keyboard shrinks the viewport.
///
/// The gap ahead of [_PromptCard] is deliberately generous (~27% of the
/// sheet height) so the card settles low on the screen, well below center
/// — the hero text has plenty of room to breathe above it.
class _HeroEntry extends StatelessWidget {
  const _HeroEntry({
    required this.controller,
    required this.focusNode,
    required this.isTr,
    required this.enabled,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTr;
  final bool enabled;
  final String hint;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: h * 0.014),
                  const _DragHandle(),
                  SizedBox(height: h * 0.04),
                  const _Wordmark(),
                  SizedBox(height: h * 0.05),
                  _Hero(isTr: isTr),
                  SizedBox(height: h * 0.27),
                  _PromptCard(
                    controller: controller,
                    focusNode: focusNode,
                    isTr: isTr,
                    enabled: enabled,
                    hint: hint,
                    onSubmitted: onSubmitted,
                  ),
                  SizedBox(height: h * 0.045),
                  _Footer(isTr: isTr),
                  SizedBox(height: h * 0.02),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sparkle above a wide letter-spaced "ASTRA AI" wordmark, centered.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.auto_awesome, size: 15, color: _Pink.sparkle(context)),
        const SizedBox(height: 8),
        Text(
          'ASTRA AI',
          style: _Pink.sans(
            context,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Pink.wordmark(context),
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }
}

/// The bold three-line headline + spaced subtitle.
class _Hero extends StatelessWidget {
  const _Hero({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headSize = (width * 0.088).clamp(28.0, 40.0);
    return Column(
      children: [
        Text(
          'Your space.\nYour thoughts.\nYour time.',
          textAlign: TextAlign.center,
          style: _Pink.sans(
            context,
            fontSize: headSize,
            fontWeight: FontWeight.w800,
            color: _Pink.heroInk(context),
            height: 1.08,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isTr ? 'Yaz. Konuş. Rahatla.' : 'Write. Talk. Relax.',
          textAlign: TextAlign.center,
          style: _Pink.sans(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _Pink.subtitle(context),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// The frosted-glass prompt card: a title row above a single text field —
/// no chip row, no separate mic/send button. The card's own fill is a
/// [BackdropFilter]-blurred, low-opacity white wash over the pink gradient
/// behind it, so the surface reads as translucent glass tinted by the same
/// pink the rest of the sheet uses (never a flat white box); a soft bright
/// hairline border keeps the card legible as a card without a hard edge.
/// Submitting is via the keyboard's own send action (wired through
/// [onSubmitted]) since there is no in-card button.
class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.controller,
    required this.focusNode,
    required this.isTr,
    required this.enabled,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTr;
  final bool enabled;
  final String hint;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _Pink.glassFillTop(context),
                _Pink.glassFillBottom(context)
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _Pink.glassBorder(context), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: _Pink.cardShadow(context),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 16, color: _Pink.sparkle(context)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isTr
                          ? 'Bugün neler hissediyorsun?'
                          : 'How are you feeling today?',
                      style: _Pink.sans(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _Pink.cardTitle(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 2,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmitted(),
                style: _Pink.sans(context,
                    fontSize: 14, color: _Pink.ink(context)),
                cursorColor: _Pink.sparkle(context),
                decoration: InputDecoration(
                  // Transparent so the frosted-glass card surface shows
                  // through instead of the app-wide softLavender fill.
                  filled: false,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: hint,
                  hintStyle: _Pink.sans(context,
                      fontSize: 14, color: _Pink.hint(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "LUMA burada, seni dinliyor." — the reassuring footer line.
class _Footer extends StatelessWidget {
  const _Footer({required this.isTr});

  final bool isTr;

  @override
  Widget build(BuildContext context) {
    return Text(
      isTr
          ? 'LUMA burada,\nseni dinliyor.'
          : 'LUMA is here,\nlistening to you.',
      textAlign: TextAlign.center,
      style: _Pink.sans(
        context,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _Pink.footer(context),
        height: 1.4,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active conversation view (shown once the first message is sent).
// ---------------------------------------------------------------------------

class _ActiveChat extends StatelessWidget {
  const _ActiveChat({
    required this.messages,
    required this.scrollController,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.hasError,
    required this.lumaTalking,
    required this.thinkingText,
    required this.errorText,
    required this.hint,
    required this.enabled,
    required this.onSend,
    required this.onClose,
  });

  final List<_ChatMessage> messages;
  final ScrollController scrollController;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool hasError;
  final bool lumaTalking;
  final String thinkingText;
  final String errorText;
  final String hint;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChatHeader(onClose: onClose),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemCount: messages.length + (isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return AstraEntrance(
                  offset: 16,
                  scaleFrom: 0.96,
                  child: _ThinkingBubble(text: thinkingText),
                );
              }
              final message = messages[index];
              final isLatestLuma =
                  !message.isUser && index == messages.length - 1 && !isSending;
              return _MessageBubble(
                message: message,
                animateAvatar: isLatestLuma,
                speaking: lumaTalking,
              );
            },
          ),
        ),
        if (hasError) _ErrorBanner(text: errorText),
        _InputBar(
          controller: controller,
          focusNode: focusNode,
          hint: hint,
          enabled: enabled,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
      child: Column(
        children: [
          const _DragHandle(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: _Pink.sparkle(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LUMA',
                  style: _Pink.sans(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _Pink.wordmark(context),
                    letterSpacing: 3,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: _Pink.wordmark(context).withValues(alpha: 0.7)),
                onPressed: onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.animateAvatar = false,
    this.speaking = false,
  });

  final _ChatMessage message;

  /// When true, Luma's animated star avatar (mouth-flap) is shown beside this
  /// bubble instead of the small static star — used for her latest reply.
  final bool animateAvatar;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient:
            isUser ? LinearGradient(colors: _Pink.userBubble(context)) : null,
        color: isUser ? null : _Pink.lumaBubble(context),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border:
            isUser ? null : Border.all(color: _Pink.lumaBubbleBorder(context)),
        boxShadow: [
          BoxShadow(
              color: _Pink.cardShadow(context),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Text(
        message.text,
        style: _Pink.sans(
          context,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isUser
              ? AstraThemeTokens.of(context).textOnAccent
              : _Pink.ink(context),
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
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: animateAvatar
                ? LumaAvatar(size: 46, speaking: speaking)
                : const LumaAvatar(size: 30),
          ),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.text});

  final String text;

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
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _Pink.lumaBubble(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: _Pink.lumaBubbleBorder(context)),
              ),
              child: Text(
                text,
                style: _Pink.sans(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _Pink.subtitle(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _Pink.sparkle(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _Pink.sparkle(context).withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.spa_outlined, size: 16, color: _Pink.sparkle(context)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: _Pink.sans(
                  context,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8A2E4F),
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
    required this.focusNode,
    required this.hint,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool enabled;
  final VoidCallback onSend;

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
                color: _Pink.cardFill(context),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: _Pink.lumaBubbleBorder(context)),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: _Pink.sans(context,
                    fontSize: 14.5, color: _Pink.ink(context)),
                cursorColor: _Pink.sparkle(context),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: _Pink.sans(context,
                      fontSize: 14.5, color: _Pink.hint(context)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(enabled: enabled, onTap: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: _Pink.micGradient(context)),
        boxShadow: [
          BoxShadow(
            color: _Pink.micShadow(context)
                .withValues(alpha: enabled ? 0.45 : 0.15),
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
          child: Icon(
            Icons.arrow_upward_rounded,
            color: AstraThemeTokens.of(context).textOnAccent,
            size: 20,
          ),
        ),
      ),
    );
  }
}
