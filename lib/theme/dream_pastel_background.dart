import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/presentation/widgets/lumora_auth_decor.dart';
import '../features/theme_choice/presentation/screens/theme_choice_screen.dart';

/// A soft, pastel "dream sky" background shared across the dream-journal
/// screens.
///
/// Unlike MoodGradientBackground, this does NOT react to the selected
/// mood — the dream section keeps one calm, dreamy identity: a pastel
/// lavender twilight wash with the moon, stars and sakura motifs, plus a
/// gentle pink dream-glow. The gradient is deliberately kept medium-dark
/// (a "pastel dusk" rather than a light pastel) so the white text and the
/// translucent frosted cards layered on top stay readable.
class DreamPastelBackground extends StatefulWidget {
  const DreamPastelBackground({super.key, this.child});

  /// Optional foreground content painted above the scene and motifs.
  final Widget? child;

  /// Fallback pastel-dusk gradient shown before the themed scene loads.
  static const List<Color> _dreamGradient = [
    Color(0xFF2B2548),
    Color(0xFF4B3F6E),
    Color(0xFF6E5E97),
    Color(0xFF9C88C0),
  ];

  @override
  State<DreamPastelBackground> createState() => _DreamPastelBackgroundState();
}

class _DreamPastelBackgroundState extends State<DreamPastelBackground> {
  String? _asset;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(astraThemeKey);
    if (mounted) {
      setState(() => _asset = theme == 'light'
          ? 'assets/images/astra_sun_bg_g5.png'
          : 'assets/images/astra_dark_plain.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_asset != null)
          Image.asset(_asset!, fit: BoxFit.cover, alignment: Alignment.topCenter)
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: DreamPastelBackground._dreamGradient,
                stops: [0.0, 0.42, 0.72, 1.0],
              ),
            ),
          ),
        // Dark scrim so the dream screens' white text and frosted cards keep
        // their contrast on top of the (often bright) themed scene.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xB3241A3D), Color(0x99241A3D)],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, child: SakuraCorner()),
        const Positioned(top: 0, right: 0, child: SakuraCorner(mirrored: true)),
        const Positioned(top: 118, right: 46, child: Butterfly()),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}