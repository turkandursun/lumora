import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/theme_choice/presentation/screens/theme_choice_screen.dart';

/// The app's shared background, driven by the user's chosen ASTRA theme:
/// the text-free sunset or moon scene, softened with a light veil so the
/// dark text and pastel cards on every screen stay readable.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  /// Fallback wash shown before the scene image loads (and if theming is off).
  static const List<Color> gradient = [
    Color(0xFFF3EBFB),
    Color(0xFFFBEBF3),
  ];

  @override
  Widget build(BuildContext context) => _AstraBackdrop(child: child);
}

class _AstraBackdrop extends StatefulWidget {
  const _AstraBackdrop({this.child});

  final Widget? child;

  @override
  State<_AstraBackdrop> createState() => _AstraBackdropState();
}

class _AstraBackdropState extends State<_AstraBackdrop> {
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
          ? 'assets/images/astra_sun_bg.png'
          : 'assets/images/astra_dark_plain.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_asset != null)
          Image.asset(_asset!,
              fit: BoxFit.cover, alignment: Alignment.topCenter)
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppBackground.gradient,
              ),
            ),
          ),
        // Light veil keeps dark text and pastel cards legible on every screen.
        Container(color: Colors.white.withValues(alpha: 0.62)),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
