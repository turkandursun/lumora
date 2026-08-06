import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/ai_service.dart';
import '../core/services/crisis_detection_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'crisis_support_sheet.dart';
import 'lumora_palette.dart';

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Lightweight session-only chat panel for talking to Luma — opened as a
/// bottom sheet from [LumaCompanion]'s speech bubble. Conversation history
/// is not persisted: it lives only in this widget's state and is gone once
/// the sheet closes.
class LumaChatSheet extends StatefulWidget {
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
  State<LumaChatSheet> createState() => _LumaChatSheetState();
}

class _LumaChatSheetState extends State<LumaChatSheet> {
  final _aiService = AiService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];

  bool _isSending = false;
  bool _hasError = false;
  bool _sessionReady = Supabase.instance.client.auth.currentSession != null;

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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Container(
          decoration: const BoxDecoration(
            color: LumoraPalette.nightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _Header(title: l10n.lumaChatTitle),
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyState(text: l10n.lumaChatEmptyState)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          itemCount: _messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return _ThinkingBubble(text: l10n.lumaChatThinking);
                            }
                            final message = _messages[index];
                            return _MessageBubble(message: message);
                          },
                        ),
                ),
                if (_hasError) _ErrorBanner(text: l10n.lumaChatError),
                _InputBar(
                  controller: _inputController,
                  hint: _sessionReady ? l10n.lumaChatInputHint : l10n.lumaChatSessionLoading,
                  enabled: !_isSending && _sessionReady,
                  onSend: _send,
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
  const _LumaStar({this.size = 26});

  final double size;

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
                      color: LumoraPalette.lightPurple
                          .withValues(alpha: 0.35 + 0.35 * t),
                      blurRadius: 10 + t * 10,
                      spreadRadius: 1 + t * 2,
                    ),
                  ],
                ),
              ),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [
                    LumoraPalette.warmCream,
                    LumoraPalette.lightPurple,
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
  const _Header({required this.title});

  final String title;

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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _LumaStar(size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: LumoraPalette.bodyStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.6)),
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
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LumaStar(size: 66),
            const SizedBox(height: 18),
            Text(
              isTr ? 'Merhaba, ben Luma ✨' : "Hi, I'm Luma ✨",
              textAlign: TextAlign.center,
              style: LumoraPalette.storyTitleStyle(fontSize: 21),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: LumoraPalette.bodyStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(colors: LumoraPalette.ctaGradient)
            : null,
        color: isUser ? null : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        message.text,
        style: LumoraPalette.bodyStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: isUser ? 1 : 0.9),
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
          const Padding(
            padding: EdgeInsets.only(right: 8, bottom: 6),
            child: _LumaStar(size: 22),
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          text,
          style: LumoraPalette.bodyStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
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
          color: LumoraPalette.accentPink.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LumoraPalette.accentPink.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.spa_outlined, size: 16, color: LumoraPalette.warmCream),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: LumoraPalette.bodyStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: LumoraPalette.warmCream,
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
  });

  final TextEditingController controller;
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
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: LumoraPalette.bodyStyle(fontSize: 14.5, color: Colors.white),
                cursorColor: LumoraPalette.lightPurple,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  // Keep transparent so the dark chat bubble shows through
                  // instead of the light theme's default softLavender fill.
                  filled: false,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: LumoraPalette.bodyStyle(
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
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
        gradient: const LinearGradient(colors: LumoraPalette.ctaGradient),
        boxShadow: [
          BoxShadow(
            color: LumoraPalette.primaryPurple.withValues(alpha: enabled ? 0.45 : 0.15),
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
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
