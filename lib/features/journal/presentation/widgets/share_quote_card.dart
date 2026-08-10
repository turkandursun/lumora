import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

/// Turns the day's quote into a small, branded image and hands it to the OS
/// share sheet — the "share as a beautiful card" flow other wellbeing apps use
/// for their daily quote. Tapping share opens a preview of the card first, so
/// the user always sees exactly what they're sending.
class ShareQuoteCard {
  const ShareQuoteCard._();

  static Future<void> share({
    required BuildContext context,
    required String quoteText,
    required bool isTr,
    String? author,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(quoteText: quoteText, isTr: isTr, author: author),
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

class _ShareSheetState extends State<_ShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final shareText = widget.author != null
          ? '"${widget.quoteText}" — ${widget.author}'
          : (widget.isTr ? "Lumora'dan bugünün ilhamı ✨" : "Today's inspiration from Lumora ✨");
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
          SnackBar(content: Text(widget.isTr ? 'Paylaşılamadı, tekrar dene.' : "Couldn't share, please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The captured card.
            RepaintBoundary(
              key: _cardKey,
              child: _QuoteImageCard(quoteText: widget.quoteText, author: widget.author),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0x55C084FC)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      widget.isTr ? 'Kapat' : 'Close',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _share,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(
                      widget.isTr ? 'Paylaş' : 'Share',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The branded, capture-ready quote card. Fixed size so the exported PNG looks
/// identical on every device.
class _QuoteImageCard extends StatelessWidget {
  const _QuoteImageCard({required this.quoteText, this.author});

  final String quoteText;
  final String? author;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE3C264);
    const ink = Color(0xFFF6EFDE);
    return Container(
      width: 340,
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B1F4C), Color(0xFF160E2C), Color(0xFF0D0919)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.58, 1.0],
        ),
        border: Border.all(color: const Color(0x66C9A7F5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Soft celestial glow in the upper-right — gives the card depth.
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [gold.withValues(alpha: 0.18), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Faint oversized opening quotation mark as a design accent.
            Positioned(
              left: 20,
              top: 46,
              child: Text(
                '“',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 96,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: gold.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 26, 30, 26),
              child: Column(
                children: [
                  // ASTRA wordmark, centered.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: gold, size: 15),
                      const SizedBox(width: 9),
                      Text(
                        'ASTRA',
                        style: GoogleFonts.cinzel(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 6,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  // Quote + author, scaled down if a long quote needs it.
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 280,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                quoteText,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: ink,
                                ),
                              ),
                              if (author != null) ...[
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 20, height: 1.4, color: gold),
                                    const SizedBox(width: 9),
                                    Text(
                                      author!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: gold,
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
                  // Ornamental divider with a small star — no wordmark text.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 44, height: 1, color: gold.withValues(alpha: 0.4)),
                      const SizedBox(width: 12),
                      Icon(Icons.auto_awesome, size: 11, color: gold.withValues(alpha: 0.9)),
                      const SizedBox(width: 12),
                      Container(width: 44, height: 1, color: gold.withValues(alpha: 0.4)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
