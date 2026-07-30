import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/theme_choice/presentation/screens/theme_choice_screen.dart';

/// Full-bleed home background using the chosen text-free ASTRA scene (sunset
/// or moon), softened with a light veil so the dark cards and text on top
/// stay readable. Falls back to a plain pastel wash until the asset loads.
class AstraHomeBackground extends StatefulWidget {
  const AstraHomeBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AstraHomeBackground> createState() => _AstraHomeBackgroundState();
}

class _AstraHomeBackgroundState extends State<AstraHomeBackground> {
  String? _asset;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(astraThemeKey);
    final asset = theme == 'light'
        ? 'assets/images/astra_sun_bg.png'
        : 'assets/images/astra_dark_plain.png';
    if (mounted) setState(() => _asset = asset);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_asset != null)
          Image.asset(_asset!, fit: BoxFit.cover, alignment: Alignment.topCenter)
        else
          const ColoredBox(color: Color(0xFFF3EBFB)),
        // Keep the scene vivid; only darken the top a touch so the white
        // greeting stays legible. The white cards below carry their own
        // contrast against the photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x5C000000), Color(0x00000000)],
              stops: [0.0, 0.28],
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
