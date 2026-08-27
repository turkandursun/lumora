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

      // Caption always names ASTRA, so anyone who receives the shared image
      // knows which app it came from and can look it up.
      final brand = widget.isTr
          ? "ASTRA'dan bugünün ilhamı ✨"
          : "Today's inspiration from ASTRA ✨";
      final shareText = widget.author != null
          ? '"${widget.quoteText}" — ${widget.author}\n$brand'
          : brand;
      final params = ShareParams(
        text: shareText,
        files: [
          XFile.fromData(bytes, name: 'astra_quote.png', mimeType: 'image/png'),
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

/// The capture-ready 9:16 quote card (fixed 360×640 logical → exported at
/// 1080×1920). A deliberately minimal design that mirrors the in-app vertical
/// quotes feed: a soft two-stop gradient in the active theme colour, an opening
/// quote glyph, the quote in an elegant serif, the author on a short rule, and
/// a single small ASTRA wordmark so a shared image always carries the app's
/// name. Rounded ("oval") corners on export. Wrapped in a [Material] so the
/// captured text never picks up the debug "missing Material" underline.
class _QuoteImageCard extends StatelessWidget {
  const _QuoteImageCard({required this.quoteText, this.author});

  final String quoteText;
  final String? author;

  static const _cream = Color(0xFFFBF6F0); // near-white text

  @override
  Widget build(BuildContext context) {
    final palette = AstraThemeTokens.of(context).palette;
    final primary = palette.primary;
    final secondary = palette.secondary;

    // Soft, calm two-stop gradient in the active theme colour.
    final bgTop = Color.lerp(primary, Colors.white, 0.20)!;
    final bgBottom = secondary;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 360,
        height: 640,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(46, 66, 46, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote + author — vertically centred, shrunk to fit if long.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 268,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded,
                              size: 50,
                              color: _cream.withValues(alpha: 0.55)),
                          const SizedBox(height: 20),
                          Text(
                            quoteText,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: _cream,
                            ),
                          ),
                          if (author != null) ...[
                            const SizedBox(height: 22),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 26,
                                    height: 1.6,
                                    color: _cream.withValues(alpha: 0.75)),
                                const SizedBox(width: 12),
                                Text(
                                  author!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    color: _cream.withValues(alpha: 0.92),
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
              // A single, minimal ASTRA wordmark.
              Text(
                'ASTRA',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: _cream.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
