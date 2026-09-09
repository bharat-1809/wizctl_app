import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import 'fixture_geometry.dart';
import 'fixture_hero.dart';
import 'fixture_paints.dart';
import 'wiz_surface.dart';

/// Mobile:264-274: cap, neck and globe stacked and lapped over one another,
/// the column centred on the stage.
void paintBulb(
  Canvas canvas,
  double cx, {
  required WizColors colors,
  required WizElevation elevation,
  required WizEmission emission,
  required double breath,
}) {
  var total =
      FixtureGeometry.cap.height +
      FixtureGeometry.neck.height -
      FixtureGeometry.neckOverlap +
      FixtureGeometry.globe -
      FixtureGeometry.globeOverlap;
  var top =
      FixtureGeometry.box.height / 2 + FixtureGeometry.bulbOffset - total / 2;

  var capRect = Rect.fromCenter(
    center: Offset(cx, top + FixtureGeometry.cap.height / 2),
    width: FixtureGeometry.cap.width,
    height: FixtureGeometry.cap.height,
  );
  var cap = RRect.fromRectAndCorners(
    capRect,
    topLeft: FixtureGeometry.capTop,
    topRight: FixtureGeometry.capTop,
    bottomLeft: FixtureGeometry.capBottom,
    bottomRight: FixtureGeometry.capBottom,
  );
  castShadow(canvas, cap, elevation.raised.outer);
  canvas.drawRRect(cap, Paint()..color = colors.railDark);
  canvas.save();
  canvas.clipRRect(cap);
  canvas.drawRect(
    capRect,
    WizTextures.knurlPaint(elevation, origin: capRect.topLeft),
  );
  canvas.restore();

  var neck = Rect.fromLTWH(
    cx - FixtureGeometry.neck.width / 2,
    top + FixtureGeometry.cap.height - FixtureGeometry.neckOverlap,
    FixtureGeometry.neck.width,
    FixtureGeometry.neck.height,
  );
  canvas.drawPath(
    Path()
      ..moveTo(neck.left + neck.width * FixtureGeometry.neckLeft, neck.top)
      ..lineTo(neck.left + neck.width * FixtureGeometry.neckRight, neck.top)
      ..lineTo(neck.right, neck.bottom)
      ..lineTo(neck.left, neck.bottom)
      ..close(),
    Paint()
      ..shader = wizVertical(
        colors.neckTop,
        colors.neckBottom,
      ).createShader(neck),
  );

  var globeRect = Rect.fromLTWH(
    cx - FixtureGeometry.globe / 2,
    neck.bottom - FixtureGeometry.globeOverlap,
    FixtureGeometry.globe,
    FixtureGeometry.globe,
  );
  var globe = RRect.fromRectAndRadius(
    globeRect,
    Radius.circular(FixtureGeometry.globe / 2),
  );
  castShadow(canvas, globe, elevation.knob.outer);
  // The glass itself is the fixture's body: it holds still while the two
  // emission stops breathe.
  canvas.drawOval(
    globeRect,
    Paint()
      ..shader = RadialGradient(
        center: FixtureGeometry.globeCentre,
        radius: FixtureGeometry.globeRadius,
        colors: [emission.em(breath), emission.emSoft(breath), colors.glass],
        stops: const [0, FixtureGeometry.globeSoftStop, 1],
      ).createShader(globeRect),
  );

  canvas.save();
  canvas.clipRRect(globe);
  _paintFilaments(canvas, cx, globeRect, emission, breath);
  // Specular on the glass, not emission: it does not breathe.
  canvas.drawOval(
    Rect.fromLTWH(
      globeRect.left + globeRect.width * FixtureGeometry.highlightLeft,
      globeRect.top + globeRect.height * FixtureGeometry.highlightTop,
      FixtureGeometry.highlight.width,
      FixtureGeometry.highlight.height,
    ),
    blurredPaint(
      colors.highlightBase.withValues(alpha: FixtureGeometry.highlightAlpha),
      FixtureGeometry.highlightBlur,
    ),
  );
  // Mobile:274: the grain, inside the globe's own `overflow:hidden`.
  paintGrain(canvas, globeRect, FixtureGeometry.globeGrain);
  canvas.restore();

  // Mobile:267 is `inset 0 -10px 20px …, inset 0 3px 0 …, var(--elev-knob)`,
  // and the knob recipe carries inner shadows of its own; CSS draws the
  // earlier shadow over the later, so the knob's land on top.
  paintInsets(canvas, globe, [
    WizInset(
      offsetY: FixtureGeometry.globeGrooveOffset,
      blur: FixtureGeometry.globeGrooveBlur,
      color: colors.shadowBase.withValues(
        alpha: FixtureGeometry.globeGrooveAlpha,
      ),
    ),
    WizInset(
      offsetY: FixtureGeometry.globeRimOffset,
      blur: 0,
      color: colors.highlightBase.withValues(
        alpha: FixtureGeometry.globeRimAlpha,
      ),
    ),
    ...elevation.knob.insets,
  ]);
}

/// Mobile:268-272: two uprights and the loop that joins them.
void _paintFilaments(
  Canvas canvas,
  double cx,
  Rect globe,
  WizEmission emission,
  double breath,
) {
  var paint = Paint()
    ..color = emission.em(emission.filament * breath)
    ..style = PaintingStyle.stroke
    ..strokeWidth = FixtureGeometry.filamentStroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      FixtureGeometry.sigma(FixtureGeometry.filamentBlur),
    );
  var top = globe.top + globe.height * FixtureGeometry.filamentTop;
  // A stroke straddles its line, so each upright stands half a stroke
  // outside the gap between them.
  var dx = (FixtureGeometry.filamentGap + FixtureGeometry.filamentStroke) / 2;
  for (var x in [cx - dx, cx + dx]) {
    canvas.drawLine(
      Offset(x, top),
      Offset(x, top + FixtureGeometry.filamentHeight),
      paint,
    );
  }
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(cx, top + FixtureGeometry.loopTop),
      width: FixtureGeometry.loop.width,
      height: FixtureGeometry.loop.height,
    ),
    0,
    math.pi,
    false,
    paint,
  );
}
