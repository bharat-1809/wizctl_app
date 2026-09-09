import 'package:flutter/material.dart';

import '../motion/reduced_motion.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// An empty machined well standing in for content that has not arrived, with
/// a faint sheen crossing it.
///
/// First loads use skeletons in the geometry of the real row so the layout
/// never collapses and then jumps.
class WizSkeleton extends StatefulWidget {
  /// Null fills the width it is offered, as Skeleton.jsx's `width = '100%'`
  /// does. A skeleton therefore needs a parent that bounds it: in an
  /// unbounded row it asserts rather than quietly measuring nothing.
  final double? width;

  final double height;

  /// A round skeleton is as wide as it is tall: Skeleton.jsx
  /// `width: circle ? height : width`.
  final bool circle;

  const WizSkeleton({
    super.key,
    this.width,
    this.height = defaultHeight,
    this.circle = false,
  });

  /// Skeleton.jsx `height = 16`.
  static const double defaultHeight = 16;

  /// The sheen: Skeleton.jsx
  /// `linear-gradient(90deg,transparent,rgba(255,255,255,.055),transparent)`
  /// — the kit's hairline alpha, at the middle of the sweep.
  static const double sheenAlpha = .055;

  /// How far it travels: Skeleton.jsx
  /// `@keyframes wz-sheen{0%{transform:translateX(-100%)}
  /// 100%{transform:translateX(100%)}}`, in fractions of the well's width.
  static const double sheenFrom = -1;
  static const double sheenTo = 1;

  /// Where reduced motion parks the sweep, as a fraction of that travel.
  static const double parkedT = .5;

  @override
  State<WizSkeleton> createState() => _WizSkeletonState();
}

class _WizSkeletonState extends State<WizSkeleton>
    with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _sheen;

  /// The platform's "reduce motion" switch, read where the dependency is
  /// registered so that turning it on stops the loop rather than merely
  /// freezing what it paints.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var motion = context.wiz.motion;
    _reduced = wizReducedMotion(context);
    var sheen = _sheen;
    if (sheen == null) {
      sheen = _sheen = AnimationController(vsync: this, duration: motion.sheen);
    } else {
      sheen.duration = motion.sheen;
    }
    if (_reduced) {
      if (sheen.isAnimating) sheen.stop();
    } else if (!sheen.isAnimating) {
      sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var sheen = _sheen!;
    var span = WizSkeleton.sheenTo - WizSkeleton.sheenFrom;
    return WizSurface(
      spec: wiz.elevation.well,
      // Skeleton.jsx `borderRadius: circle ? '50%' : var(--radius-2)`.
      radius: BorderRadius.circular(
        widget.circle ? widget.height / 2 : wiz.space.r2,
      ),
      gradient: wizVertical(c.char1000, c.char900),
      // `double.infinity`, not null: the sheen is a childless `DecoratedBox`,
      // which takes `constraints.smallest` and so collapses a null width to
      // nothing under loose constraints. Same idiom as a full-width
      // `WizButton` (`wiz_button.dart`).
      width: widget.circle ? widget.height : (widget.width ?? double.infinity),
      height: widget.height,
      child: AnimatedBuilder(
        animation: sheen,
        // Hoisted out of the builder: only the offset changes.
        child: DecoratedBox(
          key: const Key('wiz-skeleton-sheen'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                c.highlightBase.withValues(alpha: 0),
                c.highlightBase.withValues(alpha: WizSkeleton.sheenAlpha),
                c.highlightBase.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        builder: (context, child) {
          // Reduced motion parks the sweep in the middle of the well, so a
          // still skeleton keeps its highlight rather than showing bare
          // metal. Skeleton.jsx runs `wz-sheen` on `var(--ease-tactile)`.
          var t = _reduced
              ? WizSkeleton.parkedT
              : wiz.motion.tactile.transform(sheen.value);
          return FractionalTranslation(
            translation: Offset(WizSkeleton.sheenFrom + span * t, 0),
            child: child,
          );
        },
      ),
    );
  }
}
