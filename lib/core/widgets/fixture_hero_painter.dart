import 'package:flutter/material.dart';

import '../theme/wiz_colors.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_space.dart';
import 'fixture_bulb_painter.dart';
import 'fixture_geometry.dart';
import 'fixture_hero.dart';
import 'fixture_paints.dart';
import 'fixture_shade_painter.dart';

/// Paints the hero: the stage's rounded clip, the bloom above, the pool
/// below, and then the fixture itself — the bulb from
/// `fixture_bulb_painter.dart`, every other kind from
/// `fixture_shade_painter.dart`. Everything is laid out in
/// `FixtureGeometry.box` coordinates and scaled once, so the drawing is the
/// prototype's own numbers at any width.
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

  /// Only for the stage's corner radius, `--radius-4` = [WizSpace.r4].
  final WizSpace space;

  FixtureHeroPainter({
    required this.fixture,
    required this.emission,
    required this.breath,
    required this.compact,
    required this.colors,
    required this.elevation,
    required this.space,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var box = compact ? FixtureGeometry.compactBox : FixtureGeometry.box;
    canvas.save();
    // Both stages are `overflow:hidden;border-radius:var(--radius-4)`
    // (Mobile:247, Desktop:357), and they mean it: the bloom is drawn wider
    // than the box it lives in and, on a compact one, past its bottom edge.
    // The radius is applied to the painted size rather than the design box,
    // because a CSS corner radius does not scale with the box it rounds.
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(space.r4)),
    );
    canvas.scale(size.width / box.width);
    var cx = box.width / 2;

    // What the glows are measured against: the prototype's `--w`, which for
    // a bulb is the globe (spec §352, "122 globe"; the prototype's own
    // `GEO.bulb.w` of 112 disagrees with the 122 it then renders at
    // Mobile:267). It stays the fixture's *unscaled* width when compact,
    // where `calc(var(--w) * 1.1)` (Desktop:358) reads the same `--w` as
    // everywhere else — only the fixture itself is scaled (Desktop:359).
    var width = fixture == WizFixture.bulb
        ? FixtureGeometry.globe
        : FixtureGeometry.shades[fixture]!.w;

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
      paintBulb(
        canvas,
        cx,
        colors: colors,
        elevation: elevation,
        emission: emission,
        breath: breath,
      );
    } else {
      paintShade(
        canvas,
        cx,
        FixtureGeometry.shades[fixture]!,
        colors: colors,
        elevation: elevation,
        emission: emission,
        breath: breath,
        // The inspector well is too short to hang a cord in.
        cords: !compact,
      );
    }
    canvas.restore();
    canvas.restore();
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
      blurredPaint(emission.em(emission.bloom * breath), glow.blur),
    );
  }

  /// [colors], [elevation] and [space] are not compared: there is exactly
  /// one theme and `WizTheme.lerp` returns `this`, so they never change
  /// identity.
  @override
  bool shouldRepaint(FixtureHeroPainter old) =>
      old.fixture != fixture ||
      old.emission != emission ||
      old.breath != breath ||
      old.compact != compact;
}
