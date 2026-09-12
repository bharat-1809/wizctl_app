import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import 'fixture_geometry.dart';

/// The painting the hero's three paint paths share. Top-level rather than
/// private helpers on the painter, because the shade and the bulb are drawn
/// from their own libraries.

/// A flat colour under a CSS `filter: blur()`. Colour and mask only — never
/// a shader beside them, so the colour is the one that lands (C10).
Paint blurredPaint(Color color, double cssBlur) => Paint()
  ..color = color
  ..maskFilter = MaskFilter.blur(
    BlurStyle.normal,
    FixtureGeometry.sigma(cssBlur),
  );

/// The cast shadows of an elevation recipe, under [shape].
void castShadow(Canvas canvas, RRect shape, List<BoxShadow> shadows) {
  for (var shadow in shadows) {
    canvas.drawRRect(
      shape.shift(shadow.offset).inflate(shadow.spreadRadius),
      blurredPaint(shadow.color, shadow.blurRadius),
    );
  }
}

/// The machined grain over a fixture's body, `background-image:var(--grain)`
/// at [opacity].
///
/// [WizTextures.grainPaint] caches one `Paint` per opacity and already folds
/// that opacity into the shader's alpha, so this draws with what it returns
/// and never mutates it — and, like `WizGrain`, paints nothing at all until
/// [WizTextures.load] has produced a tile.
void paintGrain(Canvas canvas, Rect area, double opacity) {
  var paint = WizTextures.grainPaint(opacity: opacity);
  if (paint == null) return;
  canvas.drawRect(area, paint);
}
