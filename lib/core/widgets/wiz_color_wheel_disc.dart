import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_elevation.dart';
import '../theme/wiz_theme.dart';
import '../util/color_maths.dart';
import 'wiz_color_wheel.dart';
import 'wiz_surface.dart';

/// The colour wheel's face, internal to [WizColorWheel]: the conic hue ring
/// under its chassis rim, the white wash that bleaches the centre, and the
/// raised puck sitting on the current colour.
///
/// Everything it draws it is told — it holds no gesture, focus or semantics
/// logic, and never changes a colour. Those all stay in [WizColorWheel].
class WizColorWheelDisc extends StatelessWidget {
  /// The disc's diameter, already clamped to
  /// `[WizColorWheel.minSize, WizColorWheel.maxSize]`.
  final double diameter;

  /// Where the puck sits: hue in degrees from 12 o'clock, saturation as the
  /// fraction of the usable radius out from the centre.
  final double hue;
  final double saturation;

  /// A puck under the finger tracks it exactly; a released one eases across
  /// on the tactile curve.
  final bool dragging;

  const WizColorWheelDisc({
    super.key,
    required this.diameter,
    required this.hue,
    required this.saturation,
    required this.dragging,
  });

  /// ColorWheel.jsx centre wash:
  /// `radial-gradient(circle, rgba(255,255,255,.95) 0%, rgba(255,255,255,0) 62%)`.
  static const double _whiteAlpha = .95;

  /// CSS `radial-gradient` sizes to farthest-corner; Flutter's `radius` is a
  /// fraction of the shortest side, so the square wash box needs √2/2 to
  /// reach the corner.
  static const double _washRadius = math.sqrt2 / 2;

  /// ColorWheel.jsx inner disc: `inset 0 2px 10px rgba(0,0,0,.45)`.
  static const double _innerInsetAlpha = .45;
  static const double _innerInsetOffsetY = 2;
  static const double _innerInsetBlur = 10;

  /// ColorWheel.jsx puck ring: `0 0 0 4px rgba(250,248,244,.92)` — ivory-hi
  /// spread by [WizColorWheel.puckRing].
  static const double _puckRingAlpha = .92;

  /// ColorWheel.jsx puck shadow: `0 4px 10px rgba(0,0,0,.6)`.
  static const double _puckShadowAlpha = .60;
  static const double _puckShadowOffsetY = 4;
  static const double _puckShadowBlur = 10;

  /// ColorWheel.jsx puck glow: `0 0 26px -2px rgba(<current>,.8)` — the
  /// colour under the puck spilling past it.
  static const double _puckGlowAlpha = .80;
  static const double _puckGlowBlur = 26;
  static const double _puckGlowSpread = -2;

  /// The hue ring: ColorWheel.jsx
  /// `conic-gradient(from -90deg, red, yellow, green, teal, cyan, indigo,
  /// violet, magenta, red)` — eight of the kit's hues from 12 o'clock round
  /// to red again, so the ring and the puck agree on where hue 0 sits.
  ///
  /// The turn is rotated back a quarter to start at 12, not begun at
  /// `-π/2`: a [SweepGradient] measures from 3 o'clock and never wraps, so
  /// a negative start left the quadrant between 12 and 3 clamped to the
  /// last stop — solid red, with yellow missing and a hard edge at 3.
  Widget _ring(WizTheme wiz) {
    var c = wiz.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          transform: const GradientRotation(-math.pi / 2),
          colors: <Color>[
            c.hueRed,
            c.hueYellow,
            c.hueGreen,
            c.hueTeal,
            c.hueCyan,
            c.hueIndigo,
            c.hueViolet,
            c.hueMagenta,
            c.hueRed,
          ],
        ),
        boxShadow: wiz.elevation.knob.outer,
      ),
    );
  }

  /// The chassis rim over the ring's outer edge: ColorWheel.jsx
  /// `inset 0 0 0 8px var(--char-900)`.
  Widget _rim(WizTheme wiz) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: wiz.colors.char900,
        width: WizColorWheel.ringInset,
      ),
    ),
  );

  /// The wash inside the rim: white at the centre fading to nothing at
  /// [WizColorWheel.whiteStop], over an inner shadow that sinks the disc.
  Widget _wash(WizTheme wiz, double inner) {
    var c = wiz.colors;
    return WizSurface(
      spec: WizShadowSpec(
        insets: <WizInset>[
          WizInset(
            offsetY: _innerInsetOffsetY,
            blur: _innerInsetBlur,
            color: c.shadowBase.withValues(alpha: _innerInsetAlpha),
          ),
        ],
      ),
      radius: BorderRadius.circular(inner / 2),
      gradient: RadialGradient(
        radius: _washRadius,
        colors: <Color>[
          c.highlightBase.withValues(alpha: _whiteAlpha),
          c.highlightBase.withValues(alpha: 0),
        ],
        stops: const <double>[0, WizColorWheel.whiteStop],
      ),
    );
  }

  /// The raised puck: the current colour, ringed in ivory, casting a shadow
  /// and glowing in its own light.
  Widget _puck(WizTheme wiz, Color current) {
    var c = wiz.colors;
    return Container(
      width: WizColorWheel.puckSize,
      height: WizColorWheel.puckSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: c.ivoryHi.withValues(alpha: _puckRingAlpha),
            spreadRadius: WizColorWheel.puckRing,
          ),
          BoxShadow(
            color: c.shadowBase.withValues(alpha: _puckShadowAlpha),
            offset: const Offset(0, _puckShadowOffsetY),
            blurRadius: _puckShadowBlur,
          ),
          BoxShadow(
            color: current.withValues(alpha: _puckGlowAlpha),
            blurRadius: _puckGlowBlur,
            spreadRadius: _puckGlowSpread,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var r = diameter / 2;
    // ColorWheel.jsx: the puck rides `r - 18`, from 12 o'clock clockwise.
    var reach = (r - WizColorWheel.radiusMargin) * saturation;
    var radians = (hue - 90) * math.pi / 180;
    var puck = Offset(
      r + math.cos(radians) * reach,
      r + math.sin(radians) * reach,
    );

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        // The puck sits on the rim at full saturation and its glow spills
        // past it, as does the ring's own cast shadow: the design clips
        // neither.
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: _ring(wiz)),
          Positioned.fill(child: _rim(wiz)),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(WizColorWheel.ringInset),
              child: _wash(wiz, diameter - WizColorWheel.ringInset * 2),
            ),
          ),
          AnimatedPositioned(
            duration: dragging ? Duration.zero : wiz.motion.release,
            curve: wiz.motion.tactile,
            left: puck.dx - WizColorWheel.puckSize / 2,
            top: puck.dy - WizColorWheel.puckSize / 2,
            child: _puck(wiz, hsvToColor(hue, saturation)),
          ),
        ],
      ),
    );
  }
}
