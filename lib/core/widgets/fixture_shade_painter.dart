import 'package:flutter/material.dart';

import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import 'fixture_geometry.dart';
import 'fixture_hero.dart';
import 'fixture_paints.dart';
import 'wiz_surface.dart';

/// Mobile:256-260: a shade is a knurled grip over a dark body, with the
/// light leaving by its mouth. Dome, desk, strip and socket are the same
/// drawing at the four sizes and radii in [FixtureGeometry.shades].
void paintShade(
  Canvas canvas,
  double cx,
  WizShade shade, {
  required WizColors colors,
  required WizElevation elevation,
  required WizEmission emission,
  required double breath,
  required bool cords,
}) {
  var rect = Rect.fromCenter(
    center: Offset(cx, FixtureGeometry.box.height / 2 + shade.offset),
    width: shade.w,
    height: shade.h,
  );
  var shape = RRect.fromRectAndCorners(
    rect,
    topLeft: shade.top,
    topRight: shade.top,
    bottomLeft: shade.bottom,
    bottomRight: shade.bottom,
  );

  if (cords && shade.cord) _paintCords(canvas, cx, colors);

  castShadow(canvas, shape, elevation.knob.outer);
  canvas.drawRRect(
    shape,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors.railDark, colors.shadeBottom],
        stops: const [0, FixtureGeometry.shadeStop],
      ).createShader(rect),
  );

  canvas.save();
  canvas.clipRRect(shape);
  // The knurl already carries a shader, so the band's `opacity:.5` is
  // applied the way `WizTextures.grainPaint` applies its own: a `dstIn`
  // filter scaling the shader's alpha.
  canvas.drawRect(
    Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height * FixtureGeometry.knurlBand,
    ),
    WizTextures.knurlPaint(elevation, origin: rect.topLeft)
      ..colorFilter = ColorFilter.mode(
        colors.highlightBase.withValues(alpha: FixtureGeometry.knurlBandAlpha),
        BlendMode.dstIn,
      ),
  );
  _paintMouth(canvas, rect, colors, emission, breath);
  // Mobile:260: the grain, inside the shade's own `overflow:hidden`.
  paintGrain(canvas, rect, FixtureGeometry.shadeGrain);
  canvas.restore();
  paintInsets(canvas, shape, elevation.knob.insets);
}

/// Mobile:249-251: the pair of cords a dome hangs from, `gap:64px` apart
/// about the centre.
void _paintCords(Canvas canvas, double cx, WizColors colors) {
  var box = Rect.fromLTWH(
    0,
    0,
    FixtureGeometry.cordWidth,
    FixtureGeometry.cordHeight,
  );
  var paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.highlightBase.withValues(alpha: FixtureGeometry.cordTopAlpha),
        colors.highlightBase.withValues(alpha: FixtureGeometry.cordBottomAlpha),
      ],
    ).createShader(box);
  for (var left in [
    cx - FixtureGeometry.cordGap / 2 - FixtureGeometry.cordWidth,
    cx + FixtureGeometry.cordGap / 2,
  ]) {
    canvas.drawRect(box.translate(left, 0), paint);
  }
}

/// Mobile:259: the mouth. The whole layer carries the filament's opacity
/// (its dark rim included, or an off fixture would show a solid black oval);
/// only the two emission stops breathe.
void _paintMouth(
  Canvas canvas,
  Rect shade,
  WizColors colors,
  WizEmission emission,
  double breath,
) {
  var lit = emission.filament * breath;
  var mouth = Rect.fromLTWH(
    shade.left + shade.width * FixtureGeometry.mouthInset,
    shade.bottom -
        shade.height *
            (FixtureGeometry.mouthHeight - FixtureGeometry.mouthDrop),
    shade.width * FixtureGeometry.mouthWidth,
    shade.height * FixtureGeometry.mouthHeight,
  );
  canvas.drawOval(
    mouth,
    Paint()
      ..shader = RadialGradient(
        center: Alignment.bottomCenter,
        radius: FixtureGeometry.mouthRadius,
        transform: _MouthEllipse(
          FixtureGeometry.mouthEllipseX * mouth.width / mouth.height,
        ),
        colors: [
          emission.em(lit),
          emission.emSoft(lit),
          colors.shadowBase.withValues(
            alpha: FixtureGeometry.mouthEdgeAlpha * emission.filament,
          ),
        ],
        stops: const [0, FixtureGeometry.mouthSoftStop, 1],
      ).createShader(mouth),
  );
}

/// Stretches a radial gradient sideways about the vertical axis its origin
/// sits on, so that a CSS elliptical ending shape survives the trip into
/// Flutter, whose radius is a single number against the box's shortest side.
///
/// Every mouth here is wider than it is tall, so that shortest side is the
/// height: [FixtureGeometry.mouthRadius] gives the ending shape's vertical
/// 100 % and this gives its horizontal 60 % (Mobile:259).
@immutable
class _MouthEllipse extends GradientTransform {
  final double scaleX;

  const _MouthEllipse(this.scaleX);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // x' = scaleX·x + centre·(1 − scaleX): a horizontal scale that leaves
    // the gradient's own centre where it is. Written as matrix entries
    // rather than `Matrix4.translate`/`scale`, which are deprecated.
    var centre = bounds.center.dx;
    return Matrix4.identity()
      ..setEntry(0, 0, scaleX)
      ..setEntry(0, 3, centre * (1 - scaleX));
  }

  @override
  bool operator ==(Object other) =>
      other is _MouthEllipse && other.scaleX == scaleX;

  @override
  int get hashCode => scaleX.hashCode;
}
