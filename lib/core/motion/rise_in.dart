import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/wiz_theme.dart';
import 'reduced_motion.dart';

/// Content load-in: rise `riseDistance` and fade over `loadIn` on the
/// tactile curve, each item waiting `stagger` per place in its group
/// (spec §12, "content load-in 340–380 rise 10–12 px + fade, 50–60 ms
/// stagger per card, first build only").
///
/// Runs once on mount; rebuilds never replay it, so a list that changes
/// under a card does not drop that card back to the floor.
class RiseIn extends StatefulWidget {
  /// This item's place in its group: it waits `index × stagger` to rise.
  final int index;

  final Widget child;

  /// False renders the child at rest immediately, for content that was
  /// already on screen or is arriving without a load-in of its own.
  final bool enabled;

  const RiseIn({
    super.key,
    this.index = 0,
    required this.child,
    this.enabled = true,
  });

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _c;

  /// What the paint reads: the rise eases in on `tactile`, so the item
  /// arrives fast and settles rather than drifting up at one rate.
  CurvedAnimation? _eased;

  /// The wait for this item's slot, held in a field so [dispose] can cancel
  /// it: a timer outliving this state would drive a disposed controller.
  Timer? _slot;

  /// The entrance is decided once, on mount.
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var motion = context.wiz.motion;
    var c = _c;
    if (c == null) {
      c = _c = AnimationController(vsync: this, duration: motion.loadIn);
      _eased = CurvedAnimation(parent: c, curve: motion.tactile);
    } else {
      c.duration = motion.loadIn;
    }
    if (_started) return;
    _started = true;
    if (!widget.enabled || wizReducedMotion(context)) {
      // At rest: risen, opaque, and no controller ever started.
      c.value = c.upperBound;
      return;
    }
    _slot = Timer(motion.stagger * widget.index, () {
      if (mounted) _c!.forward();
    });
  }

  @override
  void dispose() {
    _slot?.cancel();
    // The curve first: it holds a listener on the controller under it.
    _eased?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var rise = context.wiz.motion.riseDistance;
    return AnimatedBuilder(
      animation: _eased!,
      builder: (context, child) {
        var t = _eased!.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, rise * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
