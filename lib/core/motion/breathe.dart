import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'reduced_motion.dart';

/// A powered light's slow emission breathe: opacity `breatheMin` up to full
/// and back over `breathe`, only while [active] (spec §12, "breathe 5.5 s
/// 0.88 → 1 only while on"). With the badge dot's pulse, the only looping
/// animation in the product.
class Breathe extends StatefulWidget {
  /// Whether the light is on: a dark one is not drawn breathing at all.
  final bool active;

  final Widget child;

  const Breathe({super.key, required this.active, required this.child});

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _c;

  /// What the paint reads: the reference runs the breathe on
  /// `var(--ease-tactile)`, so the swell is eased, not linear.
  CurvedAnimation? _eased;

  /// The platform's "reduce motion" switch, read where the dependency is
  /// registered so that turning it on stops the loop rather than merely
  /// freezing what it paints.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The reference runs `@keyframes wz-breathe{0%,100%{opacity:.88}
    // 50%{opacity:1}}` for 5.5 s — the `breathe` token — over a whole round
    // trip, whose peak is the keyframe at 50 %. A controller repeating in
    // reverse plays that peak at the end of each run, so it takes half the
    // token to get there (`design/reference/WizCtl_Desktop.dc.html:26`).
    var motion = context.wiz.motion;
    var halfCycle = motion.breathe ~/ 2;
    _reduced = wizReducedMotion(context);
    var c = _c;
    if (c == null) {
      c = _c = AnimationController(vsync: this, duration: halfCycle);
      _eased = CurvedAnimation(parent: c, curve: motion.tactile);
    } else {
      c.duration = halfCycle;
    }
    _sync();
  }

  /// Breathes a live light and parks any other at full emission — where a
  /// breath tops out, so switching on picks the swell up rather than
  /// stepping down into it.
  void _sync() {
    var c = _c!;
    if (widget.active && !_reduced) {
      if (!c.isAnimating) c.repeat(reverse: true);
    } else if (!c.isCompleted) {
      c.stop();
      c.value = c.upperBound;
    }
  }

  @override
  void didUpdateWidget(Breathe old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    // The curve first: it holds a listener on the controller under it.
    _eased?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var min = context.wiz.motion.breatheMin;
    return AnimatedBuilder(
      animation: _eased!,
      builder: (context, child) =>
          Opacity(opacity: min + (1 - min) * _eased!.value, child: child),
      child: widget.child,
    );
  }
}
