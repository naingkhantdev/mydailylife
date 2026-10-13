import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The soft colour field every screen sits on, and the reason the app's
/// translucent cards read as frosted glass.
///
/// The glows are radial gradients, which are already soft-edged, so a
/// semi-transparent card on top of them looks frosted without needing a
/// `BackdropFilter` per card — dozens of live blurs in a scrolling list
/// would cost real frame time on mid-range phones. Real blur is kept for the
/// few surfaces that float over *content* (the drawer).
///
/// It is painted per route rather than once behind the navigator: scaffolds
/// are transparent, and a single shared backdrop would let the outgoing page
/// show through the incoming one for the length of every transition.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Glow(
                    center: const Alignment(-1.1, -1.0),
                    radius: 1.1,
                    color: palette.glowPrimary,
                  ),
                  _Glow(
                    center: const Alignment(1.2, -0.2),
                    radius: 0.9,
                    color: palette.glowTertiary,
                  ),
                  _Glow(
                    center: const Alignment(-0.4, 1.15),
                    radius: 1.0,
                    color: palette.glowSecondary,
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Alignment center;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: radius,
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

/// Puts [AmbientBackdrop] under every `MaterialPageRoute`, delegating the
/// actual motion to [inner] so platform behaviour — notably the iOS
/// swipe-back gesture — is kept.
class AmbientPageTransitionsBuilder extends PageTransitionsBuilder {
  const AmbientPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return inner.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      AmbientBackdrop(child: child),
    );
  }
}
