import 'package:flutter/material.dart';

/// The ticks engraved along the filament's wire, so a filament standing
/// still still reads as a machined part rather than a bare bar.
///
/// The geometry lives here rather than on `WizFilamentBar` so the bar can
/// import the painter without the painter importing the bar back.
class WizFilamentTicks extends CustomPainter {
  final Color color;

  const WizFilamentTicks(this.color);

  /// FilamentBar.jsx `repeating-linear-gradient(90deg,
  /// rgba(255,255,255,.05) 0 1px, transparent 1px 4px)` (spec §11.2,
  /// "4 px ticks"): a hairline stripe every 4 px.
  static const double spacing = 4;
  static const double width = 1;
  static const double alpha = .05;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(WizFilamentTicks old) => old.color != color;
}
