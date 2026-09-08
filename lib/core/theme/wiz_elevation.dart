import 'package:flutter/material.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';

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
  WizElevation._();

  static final WizElevation standard = WizElevation._();

  // Neumorphic alphas from elevation.css
  static const double _nmHi = 0.075; // --nm-hi
  static const double _nmHiStrong = 0.13; // --nm-hi-strong
  static const double _nmLo = 0.60; // --nm-lo

  // Per-spec alphas
  static const double _panelOuter1 = 0.30; // panel outer 1
  static const double _raisedOuter1 = 0.35; // raised outer 1
  static const double _raisedInset2 = 0.40; // raised inset 2
  static const double _keyInset2 = 0.45; // key inset 2
  static const double _knobOuter1 = 0.45; // knob outer 1
  static const double _keyOuter1 = 0.42; // key outer 1
  static const double _knobInset2 = 0.50; // knob inset 2
  static const double _pressedInset1 = 0.62; // pressed inset 1
  static const double _wellInset1 = 0.66; // well inset 1
  static const double _wellDeepInset1 = 0.72; // well-deep inset 1
  static const double _overlayOuter1 = 0.85; // overlay outer 1

  // Glow amber alphas
  static const double _glowAmber1 = 0.20; // glow-amber 1
  static const double _glowAmber2 = 0.26; // glow-amber 2
  static const double _glowAmberStrong1 = 0.28; // glow-amber-strong 1
  static const double _glowAmberStrong2 = 0.30; // glow-amber-strong 2
  static const double _glowAmberStrong3 = 0.10; // glow-amber-strong 3

  late final WizShadowSpec flat = WizShadowSpec(
    outer: <BoxShadow>[
      BoxShadow(color: WizColors.standard.edgeHairline, spreadRadius: 1),
    ],
  );

  late final WizShadowSpec panel = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 1,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHi),
      ),
    ],
    outer: <BoxShadow>[
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _panelOuter1),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _nmLo),
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -12,
      ),
    ],
  );

  late final WizShadowSpec raised = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 1,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHiStrong),
      ),
      WizInset(
        offsetY: -1,
        blur: 0,
        color: WizColors.standard.shadowBase.withValues(alpha: _raisedInset2),
      ),
    ],
    outer: <BoxShadow>[
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _raisedOuter1),
        offset: const Offset(0, 2),
        blurRadius: 3,
      ),
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _nmLo),
        offset: const Offset(0, 10),
        blurRadius: 20,
        spreadRadius: -8,
      ),
    ],
  );

  late final WizShadowSpec key = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 1.5,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHiStrong),
      ),
      WizInset(
        offsetY: -2,
        blur: 2,
        color: WizColors.standard.shadowBase.withValues(alpha: _keyInset2),
      ),
    ],
    outer: <BoxShadow>[
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _keyOuter1),
        offset: const Offset(0, 3),
        blurRadius: 5,
      ),
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _nmLo),
        offset: const Offset(0, 14),
        blurRadius: 26,
        spreadRadius: -10,
      ),
    ],
  );

  late final WizShadowSpec knob = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 2,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHiStrong),
      ),
      WizInset(
        offsetY: -3,
        blur: 4,
        color: WizColors.standard.shadowBase.withValues(alpha: _knobInset2),
      ),
    ],
    outer: <BoxShadow>[
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _knobOuter1),
        offset: const Offset(0, 6),
        blurRadius: 10,
      ),
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _nmLo),
        offset: const Offset(0, 22),
        blurRadius: 40,
        spreadRadius: -14,
      ),
    ],
  );

  late final WizShadowSpec pressed = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 3,
        blur: 6,
        color: WizColors.standard.shadowBase.withValues(alpha: _pressedInset1),
      ),
      WizInset(
        offsetY: -1,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHi),
      ),
    ],
    outer: <BoxShadow>[
      BoxShadow(
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHi),
        offset: const Offset(0, 1),
      ),
    ],
  );

  late final WizShadowSpec well = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 3,
        blur: 7,
        color: WizColors.standard.shadowBase.withValues(alpha: _wellInset1),
      ),
      WizInset(
        offsetY: -1,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHi),
      ),
    ],
  );

  late final WizShadowSpec wellDeep = WizShadowSpec(
    insets: <WizInset>[
      WizInset(
        offsetY: 5,
        blur: 12,
        color: WizColors.standard.shadowBase.withValues(alpha: _wellDeepInset1),
      ),
      WizInset(
        offsetY: -1.5,
        blur: 0,
        color: WizColors.standard.highlightBase.withValues(alpha: _nmHi),
      ),
    ],
  );

  late final WizShadowSpec overlay = WizShadowSpec(
    outer: <BoxShadow>[
      BoxShadow(
        color: WizColors.standard.shadowBase.withValues(alpha: _overlayOuter1),
        offset: const Offset(0, 30),
        blurRadius: 70,
        spreadRadius: -20,
      ),
      BoxShadow(color: WizColors.standard.edgeHairline, spreadRadius: 1),
    ],
  );

  /// Emission: used only where a light is actually on. Softened values from
  /// the handoff README so adjacent lit cards do not bleed into each other.
  late final List<BoxShadow> glowAmber = <BoxShadow>[
    BoxShadow(
      color: WizColors.standard.amber500.withValues(alpha: _glowAmber1),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: WizColors.standard.amber500.withValues(alpha: _glowAmber2),
      blurRadius: 14,
      spreadRadius: -6,
    ),
  ];

  late final List<BoxShadow> glowAmberStrong = <BoxShadow>[
    BoxShadow(
      color: WizColors.standard.amber500.withValues(alpha: _glowAmberStrong1),
      spreadRadius: 1,
    ),
    BoxShadow(
      color: WizColors.standard.amber500.withValues(alpha: _glowAmberStrong2),
      blurRadius: 18,
      spreadRadius: -6,
    ),
    BoxShadow(
      color: WizColors.standard.amber500.withValues(alpha: _glowAmberStrong3),
      blurRadius: 40,
      spreadRadius: -14,
    ),
  ];

  // Textures
  final double grainAlpha = 0.035;
  final double grainDot = 0.5;
  final double grainTile = 3;
  final double vignetteAlpha = 0.055;
  final double knurlHiAlpha = 0.07;
  final double knurlLoAlpha = 0.34;
}
