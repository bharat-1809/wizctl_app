import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import 'wiz_surface.dart';

/// Geometry shared by the dial's layers (Dial.jsx).
class WizDialGeometry {
  WizDialGeometry._();

  /// Degrees of travel and where it starts (measured clockwise from 12):
  /// Dial.jsx `const sweep = 280` and `const angle = -140 + pct * sweep`.
  static const double sweep = 280;
  static const double start = -140;

  /// Pixels of vertical drag that cover the full range: Dial.jsx
  /// `(drag.current.y - e.clientY) / 160 * (max - min)`.
  static const double dragTravel = 160;

  /// Notches across the range; each crossing fires a detent: Dial.jsx
  /// `Math.round((next - min) / (max - min) * 40)`.
  static const int detents = 40;

  /// Arrow keys move this many steps: Dial.jsx `commit(value + step * 5)`.
  static const int keySteps = 5;

  /// Ratios of the diameter (knob inset, readout well inset, value font,
  /// unit font, index mark height and top offset): Dial.jsx `inset: size *
  /// 0.085`, `inset: size * 0.235`, `fontSize: size * 0.24`, `fontSize:
  /// size * 0.11`, `height: size * 0.125` and `top: size * 0.05`.
  static const double knobInset = 0.085;
  static const double wellInset = 0.235;
  static const double valueFont = 0.24;
  static const double unitFont = 0.11;
  static const double markHeight = 0.125;
  static const double markTop = 0.05;

  /// The index mark stays this many logical pixels wide at every size:
  /// Dial.jsx mark `width: 3`.
  static const double markWidth = 3;

  static double angleFor(double pct) => start + pct * sweep;
}

/// How far into the filled arc the sweep reaches its brightest before
/// settling back: Dial.jsx `var(--amber-400) ${pct * sweep * 0.65}deg`.
const double _arcHotStop = 0.65;

/// The recessed disc with the amber sweep arc and the dead wedge at the
/// bottom. CSS conic angles are from 12 o'clock; Flutter sweeps from 3, so
/// every angle is shifted by a quarter turn.
class WizDialArcPainter extends CustomPainter {
  final double pct;
  final Color amber600, amber400, amber500, dead;
  final List<WizInset> insets;

  WizDialArcPainter({
    required this.pct,
    required this.amber600,
    required this.amber400,
    required this.amber500,
    required this.dead,
    required this.insets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    var filled = pct * WizDialGeometry.sweep / 360;
    var sweepEnd = WizDialGeometry.sweep / 360;
    var startRad = (WizDialGeometry.start - 90) * math.pi / 180;
    // Dial.jsx ends the conic gradient on `transparent`. Transparent
    // charcoal rather than transparent black, so the last visible stop fades
    // out in the dead colour instead of interpolating through it.
    var clear = dead.withValues(alpha: 0);
    var gradient = SweepGradient(
      startAngle: startRad,
      endAngle: startRad + 2 * math.pi,
      colors: [amber600, amber400, amber500, dead, dead, clear, clear],
      stops: [0, filled * _arcHotStop, filled, filled, sweepEnd, sweepEnd, 1],
    );
    canvas.drawOval(rect, Paint()..shader = gradient.createShader(rect));
    paintInsets(
      canvas,
      RRect.fromRectAndRadius(rect, Radius.circular(size.width / 2)),
      insets,
    );
  }

  @override
  bool shouldRepaint(WizDialArcPainter old) => old.pct != pct;
}

/// The knob face's top-left sheen: Dial.jsx `radial-gradient(circle at 32%
/// 22%, rgba(255,255,255,.14), rgba(255,255,255,0) 58%)`. The centre is
/// those percentages in [Alignment]'s -1..1 space (32% → -0.36, 22% → -0.56).
const double _faceHighlightAlpha = .14;
const Alignment _faceHighlightCentre = Alignment(-0.36, -0.56);
const double _faceHighlightStop = .58;

/// The knurled knob face: knurl stripes over a charcoal gradient with a
/// top-left highlight.
class WizKnobFacePainter extends CustomPainter {
  final WizElevation elevation;
  final Color top, bottom, highlight;

  WizKnobFacePainter({
    required this.elevation,
    required this.top,
    required this.bottom,
    required this.highlight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      WizTextures.knurlPaint(elevation)..blendMode = BlendMode.softLight,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: _faceHighlightCentre,
          colors: [
            highlight.withValues(alpha: _faceHighlightAlpha),
            highlight.withValues(alpha: 0),
          ],
          stops: const [0, _faceHighlightStop],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(WizKnobFacePainter old) =>
      old.top != top || old.bottom != bottom || old.highlight != highlight;
}
