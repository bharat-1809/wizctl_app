import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wiz_motion.dart';

/// Screen enter: opacity only, over `screenEnter` on the tactile curve
/// (spec §12, "screen enter 300 opacity only"; §9, "Screen transitions are
/// a 300 ms opacity fade"). Nothing slides, and a pop fades back out over
/// the same 300 ms rather than snapping.
///
/// Takes its [motion] rather than reading `context.wiz`: a router builds
/// its pages where the theme's tokens are not in scope.
CustomTransitionPage<T> wizFadePage<T>({
  required LocalKey key,
  required Widget child,
  required WizMotion motion,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: motion.screenEnter,
    reverseTransitionDuration: motion.screenEnter,
    // `CurveTween.animate`, not a `CurvedAnimation`: this builder runs for
    // every transition and every frame of it, and an evaluated tween holds
    // no listener on the route's animation, so there is nothing left to
    // dispose behind it.
    transitionsBuilder: (context, animation, secondary, child) =>
        FadeTransition(
          opacity: CurveTween(curve: motion.tactile).animate(animation),
          child: child,
        ),
  );
}
