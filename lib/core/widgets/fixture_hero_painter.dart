import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import 'fixture_geometry.dart';
import 'fixture_hero.dart';
import 'wiz_surface.dart';

/// Paints the hero: the bloom above, the pool below, and the fixture itself
/// in the middle. Everything is laid out in `FixtureGeometry.box`
/// coordinates and scaled once, so the drawing is the prototype's own
/// numbers at any width.
///
/// No `Paint` here ever carries a shader *and* a colour (the shader wins and
/// the colour is dead): a layer's opacity is premultiplied into the gradient
/// stops, or applied to the shader's alpha through a `dstIn` colour filter.
class FixtureHeroPainter extends CustomPainter {
  final WizFixture fixture;
  final WizEmission emission;

  /// The breathe, `breatheMin`..1, applied to the emission layers only —
  /// the fixture's own body does not pulse.
  final double breath;

  final bool compact;
  final WizColors colors;
  final WizElevation elevation;

  FixtureHeroPainter({
    required this.fixture,
    required this.emission,
    required this.breath,
    required this.compact,
    required this.colors,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var box = compact ? FixtureGeometry.compactBox : FixtureGeometry.box;
    canvas.save();
    canvas.scale(size.width / box.width);
    var cx = box.width / 2;

    // What the glows are measured against: the prototype's `--w`, which for
    // a bulb is the globe (spec §352, "122 globe"; the prototype's own
    // `GEO.bulb.w` of 112 disagrees with the 122 it then renders at
    // Mobile:267).
    var width = fixture == WizFixture.bulb
        ? FixtureGeometry.globe
        : FixtureGeometry.shades[fixture]!.w;
    if (compact) width *= FixtureGeometry.compactScale;

    _paintBloom(canvas, cx, width);
    if (!compact) _paintFloor(canvas, cx, width);

    canvas.save();
    if (compact) {
      // Desktop:359 `transform:scale(.6)`: the fixture is drawn at full size
      // in the tall box's coordinates, then scaled about the short one's
      // centre.
      canvas.translate(cx, box.height / 2);
      canvas.scale(FixtureGeometry.compactScale);
      canvas.translate(-cx, -FixtureGeometry.box.height / 2);
    }
    if (fixture == WizFixture.bulb) {
      _paintBulb(canvas, cx);
    } else {
      // The inspector well is too short to hang a cord in.
      _paintShade(
        canvas,
        cx,
        FixtureGeometry.shades[fixture]!,
        cords: !compact,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  /// A flat colour under a CSS `filter: blur()`. Colour and mask only — no
  /// shader, so the colour is the one that lands.
  Paint _blurred(Color color, double cssBlur) => Paint()
    ..color = color
    ..maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      FixtureGeometry.sigma(cssBlur),
    );

  /// The cast shadows of an elevation recipe, under [shape].
  void _castShadow(Canvas canvas, RRect shape, List<BoxShadow> shadows) {
    for (var shadow in shadows) {
      canvas.drawRRect(
        shape.shift(shadow.offset).inflate(shadow.spreadRadius),
        _blurred(shadow.color, shadow.blurRadius),
      );
    }
  }

  /// Mobile:254: the light thrown up the wall. The prototype's
  /// `opacity:{{ light.bloom }}` on the element is premultiplied into the
  /// stops here, since the element is a gradient.
  void _paintBloom(Canvas canvas, double cx, double width) {
    if (emission.bloom <= 0) return;
    var glow = compact ? FixtureGeometry.compactBloom : FixtureGeometry.bloom;
    var rect = Rect.fromLTWH(
      cx - width * glow.width / 2,
      glow.top,
      width * glow.width,
      glow.height,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.topCenter,
          radius: FixtureGeometry.bloomRadius,
          colors: [
            emission.em(emission.bloom * breath),
            emission.color.withValues(alpha: 0),
          ],
          stops: const [0, FixtureGeometry.bloomFade],
        ).createShader(rect)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          FixtureGeometry.sigma(glow.blur),
        ),
    );
  }

  /// Mobile:255: the pool on the floor, flat `var(--em)` at the bloom's
  /// opacity.
  void _paintFloor(Canvas canvas, double cx, double width) {
    if (emission.bloom <= 0) return;
    var glow = FixtureGeometry.floor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, glow.top + glow.height / 2),
        width: width * glow.width,
        height: glow.height,
      ),
      _blurred(emission.em(emission.bloom * breath), glow.blur),
    );
  }

  /// Mobile:249-251: the pair of cords a dome hangs from, `gap:64px` apart
  /// about the centre.
  void _paintCords(Canvas canvas, double cx) {
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
          colors.highlightBase.withValues(
            alpha: FixtureGeometry.cordBottomAlpha,
          ),
        ],
      ).createShader(box);
    for (var left in [
      cx - FixtureGeometry.cordGap / 2 - FixtureGeometry.cordWidth,
      cx + FixtureGeometry.cordGap / 2,
    ]) {
      canvas.drawRect(box.translate(left, 0), paint);
    }
  }

  /// Mobile:256-260: a shade is a knurled grip over a dark body with the
  /// light leaving by its mouth.
  void _paintShade(
    Canvas canvas,
    double cx,
    WizShade shade, {
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

    if (cords && shade.cord) _paintCords(canvas, cx);

    _castShadow(canvas, shape, elevation.knob.outer);
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
          colors.highlightBase.withValues(
            alpha: FixtureGeometry.knurlBandAlpha,
          ),
          BlendMode.dstIn,
        ),
    );
    _paintMouth(canvas, rect);
    canvas.restore();
    paintInsets(canvas, shape, elevation.knob.insets);
  }

  /// Mobile:259: the mouth. The whole layer carries the filament's opacity
  /// (its dark rim included, or an off fixture would show a solid black
  /// oval); only the two emission stops breathe.
  void _paintMouth(Canvas canvas, Rect shade) {
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

  /// Mobile:264-274: cap, neck and globe stacked and lapped over one
  /// another, the column centred on the stage.
  void _paintBulb(Canvas canvas, double cx) {
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
    _castShadow(canvas, cap, elevation.raised.outer);
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
    _castShadow(canvas, globe, elevation.knob.outer);
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
    _paintFilaments(canvas, cx, globeRect);
    // Specular on the glass, not emission: it does not breathe.
    canvas.drawOval(
      Rect.fromLTWH(
        globeRect.left + globeRect.width * FixtureGeometry.highlightLeft,
        globeRect.top + globeRect.height * FixtureGeometry.highlightTop,
        FixtureGeometry.highlight.width,
        FixtureGeometry.highlight.height,
      ),
      _blurred(
        colors.highlightBase.withValues(alpha: FixtureGeometry.highlightAlpha),
        FixtureGeometry.highlightBlur,
      ),
    );
    canvas.restore();

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
    ]);
  }

  /// Mobile:268-272: two uprights and the loop that joins them.
  void _paintFilaments(Canvas canvas, double cx, Rect globe) {
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

  /// [colors] and [elevation] are not compared: there is exactly one theme
  /// and `WizTheme.lerp` returns `this`, so they never change identity.
  @override
  bool shouldRepaint(FixtureHeroPainter old) =>
      old.fixture != fixture ||
      old.emission != emission ||
      old.breath != breath ||
      old.compact != compact;
}
