import 'package:flutter/material.dart';

import '../../../core/theme/wiz_theme.dart';

/// One ring of a radar's ping (spec §10.1 step 2): it grows from
/// [scaleFrom] to full size while it fades away, driven by a clock it is
/// handed rather than one of its own, so every ring on a radar keeps the
/// same beat however many there are.
class PingRing extends StatelessWidget {
  /// The radar's clock, running 0 → 1 over one cycle and repeating.
  final Animation<double> clock;

  /// How far into the cycle this ring starts, 0 → 1.
  final double offset;

  /// The ring at full size.
  final double diameter;

  const PingRing({
    super.key,
    required this.clock,
    required this.offset,
    required this.diameter,
  });

  /// `WizCtl_Mobile.dc.html` lines 72–79, `@keyframes wz-ping`:
  /// `transform: scale(.35)` → `scale(1)` while `opacity` runs `.55` → 0,
  /// over a 1 px stroke of `rgba(255,176,32,.35)`.
  static const double scaleFrom = 0.35;
  static const double alphaFrom = 0.55;
  static const double strokeAlpha = 0.35;
  static const double strokeWidth = 1;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        var t = (clock.value + offset) % 1;
        // The curve the keyframe runs on: the ring leaves fast and coasts out.
        var eased = wiz.motion.tactile.transform(t);
        return Transform.scale(
          scale: scaleFrom + (1 - scaleFrom) * eased,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                // The stroke's own alpha and the keyframe's fade fold into
                // one colour: a ring is a hairline, and an opacity layer per
                // ring would cost a `saveLayer` every frame of the loop.
                color: wiz.colors.amber500.withValues(
                  alpha: strokeAlpha * alphaFrom * (1 - eased),
                ),
                width: strokeWidth,
              ),
            ),
            child: SizedBox(width: diameter, height: diameter),
          ),
        );
      },
    );
  }
}
