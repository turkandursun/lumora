import 'package:flutter/material.dart';

/// A gentle, calm page transition: a soft fade paired with a small upward
/// slide — the same elegant feel as the rest of the app, applied to every
/// pushed route via [ThemeData.pageTransitionsTheme].
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// The transitions theme wiring [SoftPageTransitionsBuilder] on every platform
/// so navigation feels consistent across Android, iOS, web and desktop.
const PageTransitionsTheme kSoftPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: SoftPageTransitionsBuilder(),
    TargetPlatform.iOS: SoftPageTransitionsBuilder(),
    TargetPlatform.macOS: SoftPageTransitionsBuilder(),
    TargetPlatform.windows: SoftPageTransitionsBuilder(),
    TargetPlatform.linux: SoftPageTransitionsBuilder(),
    TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
  },
);
