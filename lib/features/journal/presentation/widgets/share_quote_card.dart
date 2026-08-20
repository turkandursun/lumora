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
                              isTr: widget.isTr,
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
/// at 1080×1920). A calm, serene, palette-themed design: a soft vertical
/// gradient in the selected theme colour, gentle corner glows, a few quiet
/// stars, a faint quotation mark, the ASTRA wordmark, the quote in an elegant
/// serif, the author, and an ASTRA footer with a soft tagline — so a shared
/// image always carries the app's name. Rounded ("oval") corners on export.
class _QuoteImageCard extends StatelessWidget {
  const _QuoteImageCard(
      {required this.quoteText, required this.isTr, this.author});

  final String quoteText;
  final bool isTr;
  final String? author;

  static const _cream = Color(0xFFFBF6F0); // near-white quote text
  static const _accent = Color(0xFFEFE2D2); // soft ivory brand accent (calm)

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

    // Soft, serene on-theme gradient — gentle and calming, not dramatic.
    final bgTop = Color.lerp(primary, Colors.white, 0.30)!;
    final bgMid = Color.lerp(primary, secondary, 0.55)!;
    final bgDeep = Color.lerp(secondary, const Color(0xFF2E2138), 0.30)!;
    final glow = Color.lerp(primary, Colors.white, 0.40)!;

    return Container(
      width: 360,
      height: 640,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(44),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgMid, bgDeep],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soft corner glows for gentle depth.
          Positioned(top: -90, right: -80, child: _glow(glow, 300, 0.30)),
          Positioned(
              bottom: -80, left: -90, child: _glow(secondary, 280, 0.22)),

          // A few soft, sparse stars — calm, never busy.
          _star(46, 96, 9, 0.40),
          _star(300, 150, 12, 0.50),
          _star(58, 470, 10, 0.42),
          _star(292, 512, 8, 0.36),

          // Inset hairline frame for a quiet "framed" feel.
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: _cream.withValues(alpha: 0.18), width: 1),
                ),
              ),
            ),
          ),

          // Oversized opening quotation mark, very faint behind the quote.
          Positioned(
            left: 40,
            top: 150,
            child: Text(
              '“',
              style: GoogleFonts.playfairDisplay(
                fontSize: 140,
                height: 1,
                fontWeight: FontWeight.w700,
                color: _cream.withValues(alpha: 0.10),
              ),
            ),
          ),

          // Content.
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 60, 44, 52),
            child: Column(
              children: [
                // ASTRA wordmark.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 12, color: _accent.withValues(alpha: 0.9)),
                    const SizedBox(width: 12),
                    Text(
                      'ASTRA',
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 7,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.auto_awesome,
                        size: 12, color: _accent.withValues(alpha: 0.9)),
                  ],
                ),

                // Quote + author, centred and shrunk to fit if very long.
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 270,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              quoteText,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                height: 1.55,
                                color: _cream,
                              ),
                            ),
                            if (author != null) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 22,
                                      height: 1.2,
                                      color:
                                          _accent.withValues(alpha: 0.8)),
                                  const SizedBox(width: 10),
                                  Text(
                                    author!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                      color: _accent,
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

                // Footer: a quiet divider, the ASTRA brand, and a soft tagline —
                // so whoever sees the shared image knows the app by name.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 34,
                        height: 1,
                        color: _cream.withValues(alpha: 0.28)),
                    const SizedBox(width: 12),
                    Icon(Icons.auto_awesome,
                        size: 10, color: _cream.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Container(
                        width: 34,
                        height: 1,
                        color: _cream.withValues(alpha: 0.28)),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  'ASTRA',
                  style: GoogleFonts.cinzel(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                    color: _cream.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isTr ? 'kendine bir an' : 'a moment for you',
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.5,
                    color: _cream.withValues(alpha: 0.6),
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
