import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/reduced_motion.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// A needle sweeping a recessed ring: the inline loader, only ever inside a
/// key, a banner or a toast. Anything larger gets a [WizFilamentBar].
class WizSpinner extends StatefulWidget {
  /// The well's diameter; the ring and needle scale off it.
  final double size;

  /// Amber for work the user asked for, secondary ink for background work.
  final bool accent;

  const WizSpinner({super.key, this.size = defaultSize, this.accent = true});

  /// Spinner.jsx `size = 22` (spec §11.2, "sizes 16–22").
  static const double defaultSize = 22;

  /// How far the ring sits inside the well and how thick it is: Spinner.jsx
  /// `inset: Math.max(1, size * 0.09)` and the mask's
  /// `Math.max(1.5, size * 0.11)`.
  static const double insetRatio = 0.09;
  static const double insetMin = 1;
  static const double thicknessRatio = 0.11;
  static const double thicknessMin = 1.5;

  /// The needle: Spinner.jsx `conic-gradient(from 0deg,rgba(0,0,0,0) 0deg,
  /// rgba(0,0,0,0) 210deg,${c} 355deg,${c} 360deg)` (spec §11.2, "needle
  /// sweep (conic 210° → 355°)"). Degrees clockwise from 12.
  static const double arcStartDeg = 210;
  static const double arcEndDeg = 355;

  @override
  State<WizSpinner> createState() => _WizSpinnerState();
}

class _WizSpinnerState extends State<WizSpinner>
    with SingleTickerProviderStateMixin {
  // Built in didChangeDependencies, never as a field initialiser: its
  // duration comes from context.wiz.motion, and an InheritedWidget lookup
  // like that isn't safe before the element has established dependencies.
  AnimationController? _spin;

  /// The platform's "reduce motion" switch, read where the dependency is
  /// registered so that turning it on stops the sweep rather than merely
  /// freezing what it paints.
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var motion = context.wiz.motion;
    _reduced = wizReducedMotion(context);
    var spin = _spin;
    if (spin == null) {
      spin = _spin = AnimationController(vsync: this, duration: motion.spin);
    } else {
      spin.duration = motion.spin;
    }
    if (_reduced) {
      if (spin.isAnimating) spin.stop();
    } else if (!spin.isAnimating) {
      // Spinner.jsx `animation: 'wz-sweep 900ms linear infinite'` — a needle
      // sweeps at one rate, so no curve.
      spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    return Semantics(
      // Spinner.jsx `role="status" aria-label="Loading"`. Its own node: a
      // bare label merges into whichever node it lands in, so a spinner
      // sitting inside a key or a banner would otherwise pour "Loading" into
      // that part's label rather than announcing itself.
      container: true,
      label: 'Loading',
      child: WizSurface(
        spec: wiz.elevation.well,
        radius: BorderRadius.circular(widget.size / 2),
        gradient: wizVertical(c.char1000, c.char900),
        width: widget.size,
        height: widget.size,
        child: RotationTransition(
          // Reduced motion parks the needle where the painter draws it: at
          // the start of its arc.
          turns: _reduced ? const AlwaysStoppedAnimation(0) : _spin!,
          child: CustomPaint(
            painter: _NeedlePainter(
              widget.accent ? c.amber400 : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The needle itself: an arc that fades in from nothing at
/// [WizSpinner.arcStartDeg] to the full colour at [WizSpinner.arcEndDeg], so
/// it reads as a tail chasing a head rather than a rotating dash.
class _NeedlePainter extends CustomPainter {
  final Color color;

  const _NeedlePainter(this.color);

  /// A conic gradient measures from 12 o'clock, a canvas from 3, as
  /// `wiz_dial_painter.dart` and `wiz_color_wheel_disc.dart` also account
  /// for.
  static double _rad(double deg) => (deg - 90) * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    var extent = size.shortestSide;
    var inset = math.max(WizSpinner.insetMin, extent * WizSpinner.insetRatio);
    var thickness = math.max(
      WizSpinner.thicknessMin,
      extent * WizSpinner.thicknessRatio,
    );
    // The stroke straddles the path, so the path runs down the middle of
    // the ring the JSX's mask cuts.
    var rect = (Offset.zero & size).deflate(inset + thickness / 2);
    var start = _rad(WizSpinner.arcStartDeg);
    var end = _rad(WizSpinner.arcEndDeg);
    // No `Paint.color` beside the shader: the shader would win and the
    // colour would be dead weight. The sweep's own angles line up with the
    // arc, and `TileMode.clamp` (the default) holds the full colour across
    // the round cap at the head.
    var paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: end,
        colors: [color.withValues(alpha: 0), color],
      ).createShader(rect);
    canvas.drawArc(rect, start, end - start, false, paint);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.color != color;
}
