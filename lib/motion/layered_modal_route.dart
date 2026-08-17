import 'package:flutter/material.dart';

/// ============================================================================
/// EFFECT 4 — Contextual Pseudo-3D Scale-Down Layering (Modal Sheets)
/// ============================================================================
///
/// THEORETICAL FRAMEWORK
/// ----------------------------------------------------------------------------
/// Every route sitting *below* a newly-pushed route receives a
/// `secondaryAnimation` from the framework — driven 0→1 in lockstep with the
/// new route's entrance transition — specifically so the outgoing/background
/// route can react to whatever is being pushed on top of it.
/// `MaterialPageRoute` ignores this by default (it only uses the primary
/// `animation` for its own entrance). This kit's [ScalablePageRoute]
/// (imperative `Navigator.push`) and [ScalablePage] (go_router / Navigator
/// 2.0 `Page` API) both read `secondaryAnimation` to uniformly scale and
/// round the background route:
///
///     scale(t)  = lerp(1.0, 0.92, curve(t))
///     radius(t) = lerp(0,   24,   curve(t))
///
/// using `Curves.easeOutCubic` so the recede "settles" rather than snapping.
/// The modal sheet itself is presented as a *separate*, transparent-barrier
/// route ([showLayeredModal]) sliding up from the bottom on its own primary
/// `animation` — `secondaryAnimation` belongs exclusively to the route(s)
/// underneath it, never to itself.
///
/// RENDERING MECHANICS
/// ----------------------------------------------------------------------------
/// - `Transform.scale` + `ClipRRect` around the *entire* background route's
///   subtree, driven by one `AnimatedBuilder` — cheap, compositor-level
///   transform/clip, no re-layout of the background screen's content.
/// - `showLayeredModal` uses `Navigator.of(context, rootNavigator: true)
///   .push` with `opaque: false` so the route(s) beneath remain in the tree
///   (and keep receiving `secondaryAnimation`) instead of being disposed.
/// ============================================================================

Widget _scaleDownTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final entrance = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  final recede = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);

  return FadeTransition(
    opacity: entrance,
    child: AnimatedBuilder(
      animation: recede,
      child: child,
      builder: (context, child) {
        final scale = 1.0 - 0.08 * recede.value;
        final radius = 24.0 * recede.value;
        return Transform.scale(
          scale: scale,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Drop-in replacement for `MaterialPageRoute` — use it as the route factory
/// for every top-level screen in an imperative `Navigator` so each screen
/// correctly scales down whenever something is pushed on top of it via
/// [showLayeredModal] or another [ScalablePageRoute].
class ScalablePageRoute<T> extends MaterialPageRoute<T> {
  ScalablePageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _scaleDownTransitionsBuilder(context, animation, secondaryAnimation, child);
  }
}

/// go_router / Navigator 2.0 equivalent — return this from a `GoRoute`'s
/// `pageBuilder` (or a `ShellRoute`'s) so that screen participates in the
/// same background scale-down as [ScalablePageRoute]:
///
/// ```dart
/// GoRoute(
///   path: '/home',
///   pageBuilder: (context, state) => ScalablePage(
///     key: state.pageKey,
///     child: const HomeScreen(),
///   ),
/// )
/// ```
class ScalablePage extends Page<void> {
  const ScalablePage({required this.child, super.key, super.name, super.arguments});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return PageRouteBuilder<void>(
      settings: this,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: _scaleDownTransitionsBuilder,
    );
  }
}

/// Presents [builder] as a sheet sliding up from the bottom over a dimming
/// scrim, while every [ScalablePageRoute] / [ScalablePage] beneath it scales
/// down in response via their own `secondaryAnimation`.
///
/// Pushed on the root navigator with `opaque: false` so the screen(s)
/// beneath stay mounted (and keep receiving `secondaryAnimation`) instead of
/// being torn down.
Future<T?> showLayeredModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double heightFactor = 0.86,
  Color barrierColor = const Color(0x66000000),
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      // Drawn manually below (see barrierColor lerp) so it can be combined
      // with the slide-up progress instead of jumping to full opacity.
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return AnimatedBuilder(
          animation: curved,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      color: Color.lerp(Colors.transparent, barrierColor, curved.value),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - curved.value),
                    child: FractionallySizedBox(
                      heightFactor: heightFactor,
                      child: Material(
                        color: Colors.transparent,
                        child: builder(context),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
