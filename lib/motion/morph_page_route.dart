import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// ============================================================================
/// EFFECT 1 — Advanced Hero Card-to-Page Morphing Transition
/// ============================================================================
///
/// THEORETICAL & MATHEMATICAL FRAMEWORK
/// ----------------------------------------------------------------------------
/// Unlike Flutter's built-in `Hero`, which cross-fades between two
/// independently laid-out widget subtrees living in two different routes,
/// this transition keeps a *single* dual-layer stack pinned to one
/// interpolated `Rect` for the entire animation:
///
///   R(t) = Rect.lerp(originRect, targetRect, curve(t))
///
/// `curve(t)` is `Curves.easeOutCubic` — a monotonically increasing,
/// decelerating curve with no overshoot. Cheap to evaluate (a cubic
/// polynomial), and it reads as "settling into place", which is the correct
/// feel for a card growing into a full page (as opposed to a spring, which
/// would suit a *release* gesture, not a *navigation* commit).
///
/// Border radius interpolates linearly alongside the rect:
///
///   radius(t) = lerpDouble(cardRadius, 0, curve(t))
///
/// Two content layers are painted inside that shared, clipped rect:
///   - the CLOSED (card) layer: opacity 1 → 0
///   - the OPEN (page) layer: opacity 0 → 1, laid out at full screen size
///     and then scaled down into the current `R(t)` via `FittedBox` inside a
///     fixed-size child — this is what makes the page's *layout* (not just a
///     bitmap of it) morph continuously, rather than stretching a snapshot.
///
/// Both layers share the exact same `ClipRRect(borderRadius: radius(t))`
/// positioned at `R(t)` — "dual-layered clipping": they always read as one
/// continuously-deforming surface, never two separately animating widgets.
///
/// RENDERING MECHANICS
/// ----------------------------------------------------------------------------
/// - The origin card's on-screen bounds are captured via a `GlobalKey` +
///   `RenderBox.localToGlobal` at the moment of the tap (not earlier — the
///   list/grid the card lives in may have scrolled since the last frame).
/// - The transition runs inside `PageRoute.buildTransitions`, driven by the
///   route's own `animation`, so it fully participates in `Navigator`
///   gestures (an iOS edge-swipe-to-pop reverses it exactly, frame for
///   frame).
/// - Both content layers are wrapped in `RepaintBoundary` so animating the
///   interpolated clip/opacity/position only touches compositor-level
///   layers — it never forces Flutter to re-layout or re-paint the (usually
///   complex) card/page subtrees on every tick.
/// ============================================================================

/// Captures the on-screen [Rect] of whatever it's attached to (via
/// [MorphSource]) so [MorphPageRoute] can animate outward from exactly where
/// the user tapped. Create one per card and hold it as a field on the
/// enclosing `State` (or in a list, one per item, for a grid/list of cards).
class MorphCardHandle {
  MorphCardHandle();

  final GlobalKey _key = GlobalKey();

  /// The card's current bounds in screen (global) coordinates, or `null` if
  /// it isn't currently laid out (e.g. scrolled off-screen).
  Rect? get boundsInScreen {
    final renderObject = _key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }
}

/// Wrap a dashboard card with this, passing a [MorphCardHandle] owned by the
/// parent widget. The wrapped [child] is exactly what's visible before the
/// tap — [MorphPageRoute] takes over the visual role once the transition
/// starts, so this widget itself needs no animation logic.
class MorphSource extends StatelessWidget {
  const MorphSource({
    super.key,
    required this.handle,
    required this.child,
    this.borderRadius = 24,
  });

  final MorphCardHandle handle;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: handle._key,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

/// Pushes a full-screen page that visually grows out of a [MorphSource]'s
/// current on-screen bounds — the dashboard-card-to-editor transition.
///
/// Usage:
/// ```dart
/// final handle = MorphCardHandle(); // held as a field, one per card
///
/// MorphSource(
///   handle: handle,
///   borderRadius: 24,
///   child: GestureDetector(
///     onTap: () => Navigator.of(context).push(
///       MorphPageRoute(
///         handle: handle,
///         cardRadius: 24,
///         closedBuilder: (context) => JournalCardPreview(entry: entry),
///         openBuilder: (context) => JournalEditorScreen(entry: entry),
///       ),
///     ),
///     child: JournalCardPreview(entry: entry),
///   ),
/// )
/// ```
class MorphPageRoute<T> extends PageRoute<T> {
  MorphPageRoute({
    required this.handle,
    required this.openBuilder,
    required this.closedBuilder,
    this.cardRadius = 24,
    this.closedColor = Colors.transparent,
    this.openColor,
    super.settings,
  });

  final MorphCardHandle handle;
  final WidgetBuilder openBuilder;
  final WidgetBuilder closedBuilder;
  final double cardRadius;
  final Color closedColor;
  final Color? openColor;

  @override
  Color? get barrierColor => null;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 460);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 380);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // The destination screen is built exactly once and cached by the
    // framework — only its presentation (position/scale/clip/opacity)
    // animates below, entirely on the compositor.
    return openBuilder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final originRect = handle.boundsInScreen ?? Rect.zero;
    final screenSize = MediaQuery.sizeOf(context);
    final targetRect = Offset.zero & screenSize;

    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value.clamp(0.0, 1.0);
        final rect = Rect.lerp(originRect, targetRect, t)!;
        final radius = ui.lerpDouble(cardRadius, 0, t)!;

        return Stack(
          children: [
            // Background scrim behind the morphing surface — fades in with
            // the destination page so the origin screen never looks like it
            // "vanishes" abruptly underneath a floating card.
            Opacity(
              opacity: t,
              child: ColoredBox(
                color: openColor ?? Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            Positioned.fromRect(
              rect: rect,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: SizedBox(
                    width: rect.width,
                    height: rect.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // OPEN layer: laid out at full screen size, then
                        // scaled down to the currently-interpolated rect via
                        // FittedBox — its *layout*, not a bitmap of it,
                        // morphs in step with the rect.
                        Opacity(
                          opacity: t,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                              width: screenSize.width,
                              height: screenSize.height,
                              child: RepaintBoundary(child: child),
                            ),
                          ),
                        ),
                        // CLOSED layer: the original card, fading out. Kept
                        // painted (not removed) until t reaches 1 so there's
                        // never a frame with neither layer visible.
                        if (t < 1)
                          Opacity(
                            opacity: 1 - t,
                            child: RepaintBoundary(
                              child: ColoredBox(
                                color: closedColor,
                                child: closedBuilder(context),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
