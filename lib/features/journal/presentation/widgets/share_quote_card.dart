import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../theme/astra_design_tokens.dart';
import '../../../../theme/luma_glass_theme.dart';

/// Turns the day's quote into a premium, Instagram-story-sized (9:16) branded
/// image and hands it to the OS share sheet, so it looks great posted to an IG
/// story, sent on WhatsApp/Snap, etc. Tapping share first opens a preview that
/// grows in from the centre (like the mood-check box) with the card's details
/// appearing in sequence — never a bottom sheet.
class ShareQuoteCard {
  const ShareQuoteCard._();

  static Future<void> share({
    required BuildContext context,
    required String quoteText,
    required bool isTr,
    String? author,
  }) async {
    // Centered dialog (not a bottom sheet): the card appears from the middle of
    // the screen and grows/shrinks in place, matching the mood-picker box.
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'share-card',
      barrierColor: Colors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) =>
          _ShareSheet(quoteText: quoteText, isTr: isTr, author: author),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.quoteText, required this.isTr, this.author});

  final String quoteText;
  final bool isTr;
  final String? author;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;
  bool _closing = false;

  // Grows in / shrinks out from the centre (like the mood picker box), while the
  // small sparkle row + buttons fade in one after another underneath it.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _cardScale = Tween<double>(begin: 0.82, end: 1.0)
      .animate(CurvedAnimation(
          parent: _c,
          curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack)));
  late final Animation<double> _cardFade = CurvedAnimation(
      parent: _c, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));

  // Staggered "appears in sequence" entrance for the three sparkles above the
  // card and the action buttons below it.
  Animation<double> _step(double start, double end) => CurvedAnimation(
      parent: _c, curve: Interval(start, end, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    await _c.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      // 360 x 640 logical  ×  pixelRatio 3  =  1080 x 1920  (Instagram story).
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final shareText = widget.author != null
          ? '"${widget.quoteText}" — ${widget.author}'
          : (widget.isTr
              ? "Lumora'dan bugünün ilhamı ✨"
              : "Today's inspiration from Lumora ✨");
      final params = ShareParams(
        text: shareText,
        files: [
          XFile.fromData(bytes, name: 'lumora_quote.png', mimeType: 'image/png'),
        ],
      );
      await SharePlus.instance.share(params);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isTr
                  ? 'Paylaşılamadı, tekrar dene.'
                  : "Couldn't share, please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _sparkle(Animation<double> a, double size, double opacity) {
    return AnimatedBuilder(
      animation: a,
      builder: (_, __) {
        final v = a.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: (v).clamp(0.0, 1.0) * opacity,
          child: Transform.scale(
            scale: 0.4 + 0.6 * v,
            child: Icon(Icons.auto_awesome,
                size: size, color: LumaGlass.sparkle(context)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sparkles that pop in one after another above the card.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _sparkle(_step(0.30, 0.62), 16, 0.7),
                    const SizedBox(width: 14),
                    _sparkle(_step(0.40, 0.72), 22, 1.0),
                    const SizedBox(width: 14),
                    _sparkle(_step(0.50, 0.82), 16, 0.7),
                  ],
                ),
                const SizedBox(height: 14),
                // The 9:16 card — grows in from the centre. Scaled to fit the
                // screen for preview, but captured at full 1080×1920.
                Flexible(
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: ScaleTransition(
                      scale: _cardScale,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: _QuoteImageCard(
                              quoteText: widget.quoteText,
                              author: widget.author),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Buttons fade/slide in last.
                _StaggerIn(
                  animation: _step(0.62, 1.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _dismiss,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: Text(
                            widget.isTr ? 'Kapat' : 'Close',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _share,
                          style: FilledButton.styleFrom(
                            backgroundColor: LumaGlass.sparkle(context),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.ios_share_rounded, size: 18),
                          label: Text(
                            widget.isTr ? 'Paylaş' : 'Share',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
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

/// A tiny fade + slide-up wrapper, mirroring the app's `AstraEntrance` feel so
/// the elements settle in one after another.
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, c) {
        final v = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: c),
        );
      },
      child: child,
    );
  }
}

/// The branded, capture-ready 9:16 quote card (fixed 360×640 logical → exported
/// at 1080×1920). A premium, palette-themed "celestial" design: a rich vertical
/// gradient in the selected theme colour, soft corner glows, a scattered star
/// field, an oversized quotation mark, the ASTRA wordmark, the quote in an
/// elegant serif, the author, and a small Lumora footer.
class _QuoteImageCard extends StatelessWidget {
  const _QuoteImageCard({required this.quoteText, this.author});

  final String quoteText;
  final String? author;

  static const _cream = Color(0xFFFBF4EC); // near-white quote text
  static const _gold = Color(0xFFE9D3A0); // champagne brand accent

  Widget _glow(Color color, double size, double alpha) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: alpha), Colors.transparent],
            ),
          ),
        ),
      );

  Widget _star(double left, double top, double size, double alpha) => Positioned(
        left: left,
        top: top,
        child: Icon(Icons.auto_awesome,
            size: size, color: _cream.withValues(alpha: alpha)),
      );

  @override
  Widget build(BuildContext context) {
    final palette = AstraThemeTokens.of(context).palette;
    final primary = palette.primary;
    final secondary = palette.secondary;

    // Rich, premium, on-theme gradient: bright top → saturated mid → deep base.
    final bgTop = Color.lerp(primary, Colors.white, 0.10)!;
    final bgMid = secondary;
    final bgDeep = Color.lerp(secondary, const Color(0xFF17101F), 0.44)!;
    final glow = Color.lerp(primary, Colors.white, 0.32)!;

    return Container(
      width: 360,
      height: 640,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgMid, bgDeep],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soft celestial corner glows for depth.
          Positioned(top: -84, right: -74, child: _glow(glow, 280, 0.34)),
          Positioned(bottom: -70, left: -86, child: _glow(secondary, 260, 0.26)),

          // A scattered star field.
          _star(40, 70, 10, 0.55),
          _star(300, 120, 14, 0.7),
          _star(60, 300, 8, 0.4),
          _star(320, 360, 9, 0.5),
          _star(46, 520, 12, 0.6),
          _star(288, 548, 8, 0.45),
          _star(180, 96, 7, 0.35),

          // Inset hairline frame for a premium "framed" feel.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: _cream.withValues(alpha: 0.22), width: 1),
                ),
              ),
            ),
          ),

          // Oversized opening quotation mark behind the quote.
          Positioned(
            left: 34,
            top: 168,
            child: Text(
              '“',
              style: GoogleFonts.playfairDisplay(
                fontSize: 150,
                height: 1,
                fontWeight: FontWeight.w700,
                color: _gold.withValues(alpha: 0.16),
              ),
            ),
          ),

          // Content.
          Padding(
            padding: const EdgeInsets.fromLTRB(42, 58, 42, 50),
            child: Column(
              children: [
                // ASTRA wordmark.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, size: 13, color: _gold),
                    const SizedBox(width: 11),
                    Text(
                      'ASTRA',
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 7,
                        color: _gold,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Icon(Icons.auto_awesome, size: 13, color: _gold),
                  ],
                ),

                // Quote + author, centred and shrunk to fit if very long.
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 268,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              quoteText,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 27,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: _cream,
                              ),
                            ),
                            if (author != null) ...[
                              const SizedBox(height: 26),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 24, height: 1.4, color: _gold),
                                  const SizedBox(width: 10),
                                  Text(
                                    author!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: _gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer: ornamental divider + Lumora handle.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 40,
                        height: 1,
                        color: _cream.withValues(alpha: 0.32)),
                    const SizedBox(width: 12),
                    const Icon(Icons.auto_awesome,
                        size: 11, color: _cream),
                    const SizedBox(width: 12),
                    Container(
                        width: 40,
                        height: 1,
                        color: _cream.withValues(alpha: 0.32)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'lumora',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3.5,
                    color: _cream.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
