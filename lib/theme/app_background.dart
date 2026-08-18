import 'package:flutter/material.dart';

import 'astra_design_tokens.dart';

/// Reactive shared background used by secondary screens such as export.
/// It reads ThemeExtension tokens, so account switches and appearance changes
/// cannot leave a stale backdrop from an earlier user.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = AstraThemeTokens.of(context).palette;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.backgroundGradient),
      child: child ?? const SizedBox.expand(),
    );
  }
}
