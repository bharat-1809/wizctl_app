import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'wiz_colors.dart';
import 'wiz_elevation.dart';

/// Vertical top-to-bottom gradient, the kit's default surface fill.
LinearGradient wizVertical(Color top, Color bottom) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [top, bottom],
);

/// The three textures, spec §11.1: grain (a 0.5 px dot every 3 px so
/// charcoal reads as machined metal), knurl (vertical stripes on grips and
/// knob rims) and the vignette painted by `WizAppBackground`.
class WizTextures {
  WizTextures._();

  static ui.Image? _grain;
  static double _grainScale = 1;

  /// Whether [load] has produced a grain tile yet. Callers that paint grain
  /// before this is true simply paint nothing this frame.
  static bool get hasGrain => _grain != null;

  /// Renders the grain tile once at the device pixel ratio so the dot stays
  /// crisp. Call from bootstrap; widgets paint no grain until it is ready.
  ///
  /// Idempotent: once a tile exists, later calls (including from a test that
  /// never awaits bootstrap) are a no-op rather than re-rendering.
  static Future<void> load({double devicePixelRatio = 1}) async {
    if (_grain != null) return;
    var e = WizElevation.standard;
    var px = (e.grainTile * devicePixelRatio).round();
    var recorder = ui.PictureRecorder();
    var canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio);
    canvas.drawCircle(
      Offset(e.grainTile / 2, e.grainTile / 2),
      e.grainDot,
      Paint()
        ..color = WizColors.standard.highlightBase.withValues(
          alpha: e.grainAlpha,
        ),
    );
    _grain = await recorder.endRecording().toImage(px, px);
    _grainScale = 1 / devicePixelRatio;
  }

  /// The grain shader at [opacity], or `null` before [load] has produced a
  /// tile — callers must treat `null` as "paint nothing" rather than throw.
  static Paint? grainPaint({double opacity = 1}) {
    var image = _grain;
    if (image == null) return null;
    var matrix = Matrix4.diagonal3Values(_grainScale, _grainScale, 1);
    // A shader is already set below, so `opacity` cannot also go through
    // `Paint.color` (the shader would win and the colour would be dead).
    // Instead it is applied as a `dstIn` colour filter: keep the shader's
    // own pixels, scale their alpha by this filter colour's alpha.
    return Paint()
      ..shader = ImageShader(
        image,
        TileMode.repeated,
        TileMode.repeated,
        matrix.storage,
      )
      ..colorFilter = ColorFilter.mode(
        WizColors.standard.highlightBase.withValues(alpha: opacity),
        BlendMode.dstIn,
      );
  }

  /// Repeating stripes: a hairline highlight then a groove, one period per
  /// [WizElevation.grainTile] logical pixels.
  static Paint knurlPaint(WizElevation e, {Offset origin = Offset.zero}) {
    var hi = WizColors.standard.highlightBase.withValues(alpha: e.knurlHiAlpha);
    var lo = WizColors.standard.shadowBase.withValues(alpha: e.knurlLoAlpha);
    return Paint()
      ..shader = ui.Gradient.linear(
        origin,
        origin + Offset(e.grainTile, 0),
        [hi, hi, lo, lo],
        [0, 1 / 3, 1 / 3, 1],
        TileMode.repeated,
      );
  }
}
