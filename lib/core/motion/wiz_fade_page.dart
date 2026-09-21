import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wiz_motion.dart';

/// Screen enter: opacity only, over `screenEnter` on the tactile curve
/// (spec §12, "screen enter 300 opacity only"; §9, "Screen transitions are
/// a 300 ms opacity fade"). Nothing slides, and a pop fades back out over
/// the same 300 ms rather than snapping — unless [reduced] says otherwise.
///
/// Takes its [motion] rather than reading `context.wiz`: a router builds
/// its pages where the theme's tokens are not in scope. [reduced] is the
/// platform's "reduce motion" switch, read by the caller for the same reason
/// — a page is built above the navigator, and `wizReducedMotion` needs a
/// context under the `MediaQuery` the app installs.
///
/// A reduced page spends no time on either direction: the builder is
/// unchanged, and a fade with no duration is a snap. It is the durations
/// rather than the transition that go, so a route still reports the
/// `isAnimating`, `didPush` and `didPop` a navigator expects of it.
///
/// [reduced] is sampled here, when the page is constructed, and a route takes
/// its durations from the page that created it — so flipping the platform
/// switch retimes the *next* route, not the one on show. That is the right
/// way round for a setting nobody changes mid-navigation, and it is why the
/// flag is a parameter rather than a read: there is no later frame on which a
/// page could change its mind.
CustomTransitionPage<T> wizFadePage<T>({
  required LocalKey key,
  required Widget child,
  required WizMotion motion,
  bool reduced = false,
}) {
  var fade = reduced ? Duration.zero : motion.screenEnter;
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: fade,
    reverseTransitionDuration: fade,
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
