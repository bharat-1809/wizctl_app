import 'package:flutter/material.dart';

/// An inset (inner) shadow: CSS `inset 0 <offsetY> <blur> <color>`. A blur of
/// 0 with a 1px offset is the hard highlight or groove line.
@immutable
class WizInset {
  final double offsetY;
  final double blur;
  final Color color;
  const WizInset({
    required this.offsetY,
    required this.blur,
    required this.color,
  });
}

/// One elevation recipe: outer cast shadows plus inner highlight/groove.
@immutable
class WizShadowSpec {
  final List<BoxShadow> outer;
  final List<WizInset> insets;
  const WizShadowSpec({this.outer = const [], this.insets = const []});
}

/// Elevation and texture tokens from `tokens/elevation.css`.
///
/// One light source, low and top-left. Raised parts get a top highlight, a
/// bottom groove and a cast shadow; recessed parts invert it. Never mix the
/// two on one element, and never nest raised directly inside raised.
@immutable
class WizElevation {
  const WizElevation._();

  static const WizElevation standard = WizElevation._();

  static const Color _hi = Color(
    0x13FFFFFF,
  ); // white highlight, rgba(255,255,255,.075)
  static const Color _hiStrong = Color(
    0x21FFFFFF,
  ); // white highlight strong, .13
  static const Color _lo = Color(0x99000000); // black shadow, rgba(0,0,0,.60)
  static const Color _hairline = Color(0x0EFFFFFF); // .055

  final WizShadowSpec flat = const WizShadowSpec(
    outer: [BoxShadow(color: _hairline, spreadRadius: 1)],
  );
  final WizShadowSpec panel = const WizShadowSpec(
    insets: [WizInset(offsetY: 1, blur: 0, color: _hi)],
    outer: [
      BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
        color: _lo,
        offset: Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -12,
      ),
    ],
  );
  final WizShadowSpec raised = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 1, blur: 0, color: _hiStrong),
      WizInset(offsetY: -1, blur: 0, color: Color(0x66000000)),
    ],
    outer: [
      BoxShadow(color: Color(0x59000000), offset: Offset(0, 2), blurRadius: 3),
      BoxShadow(
        color: _lo,
        offset: Offset(0, 10),
        blurRadius: 20,
        spreadRadius: -8,
      ),
    ],
  );
  final WizShadowSpec key = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 1.5, blur: 0, color: _hiStrong),
      WizInset(offsetY: -2, blur: 2, color: Color(0x73000000)),
    ],
    outer: [
      BoxShadow(color: Color(0x6B000000), offset: Offset(0, 3), blurRadius: 5),
      BoxShadow(
        color: _lo,
        offset: Offset(0, 14),
        blurRadius: 26,
        spreadRadius: -10,
      ),
    ],
  );
  final WizShadowSpec knob = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 2, blur: 0, color: _hiStrong),
      WizInset(offsetY: -3, blur: 4, color: Color(0x80000000)),
    ],
    outer: [
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 6), blurRadius: 10),
      BoxShadow(
        color: _lo,
        offset: Offset(0, 22),
        blurRadius: 40,
        spreadRadius: -14,
      ),
    ],
  );
  final WizShadowSpec pressed = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 3, blur: 6, color: Color(0x9E000000)),
      WizInset(offsetY: -1, blur: 0, color: _hi),
    ],
    outer: [BoxShadow(color: _hi, offset: Offset(0, 1))],
  );
  final WizShadowSpec well = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 3, blur: 7, color: Color(0xA8000000)),
      WizInset(offsetY: -1, blur: 0, color: _hi),
    ],
  );
  final WizShadowSpec wellDeep = const WizShadowSpec(
    insets: [
      WizInset(offsetY: 5, blur: 12, color: Color(0xB8000000)),
      WizInset(offsetY: -1.5, blur: 0, color: _hi),
    ],
  );
  final WizShadowSpec overlay = const WizShadowSpec(
    outer: [
      BoxShadow(
        color: Color(0xD9000000),
        offset: Offset(0, 30),
        blurRadius: 70,
        spreadRadius: -20,
      ),
      BoxShadow(color: _hairline, spreadRadius: 1),
    ],
  );

  /// Emission: used only where a light is actually on. Softened values from
  /// the handoff README so adjacent lit cards do not bleed into each other.
  final List<BoxShadow> glowAmber = const [
    BoxShadow(color: Color(0x33FFB020), spreadRadius: 1),
    BoxShadow(color: Color(0x42FFB020), blurRadius: 14, spreadRadius: -6),
  ];
  final List<BoxShadow> glowAmberStrong = const [
    BoxShadow(color: Color(0x47FFB020), spreadRadius: 1),
    BoxShadow(color: Color(0x4DFFB020), blurRadius: 18, spreadRadius: -6),
    BoxShadow(color: Color(0x1AFFB020), blurRadius: 40, spreadRadius: -14),
  ];

  // Textures
  final double grainAlpha = 0.035;
  final double grainDot = 0.5;
  final double grainTile = 3;
  final double vignetteAlpha = 0.055;
  final double knurlHiAlpha = 0.07;
  final double knurlLoAlpha = 0.34;
}
