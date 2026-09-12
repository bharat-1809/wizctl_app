import 'package:flutter/material.dart';

import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_theme.dart';
import 'wiz_surface.dart';

/// A `LightCard`'s icon well. Lit it is a hot amber lens; dark it is the
/// recessed charcoal well every other glyph in the kit sits in. Internal to
/// the card — it takes the two things it draws from and owns no gesture,
/// focus or semantics of its own.
class LightCardWell extends StatelessWidget {
  final WizIconData icon;
  final bool lit;

  const LightCardWell({super.key, required this.icon, required this.lit});

  /// The well and its glyph: LightCard.jsx `width: 46, height: 46`
  /// (`design/reference/_ds_bundle.js:1887`) and `size: 22` (`:1900`).
  /// Spec §11.2, "46 icon well".
  static const double size = 46;
  static const double glyph = 22;

  /// The lit well's fill: LightCard.jsx
  /// `radial-gradient(circle at 50% 30%,var(--amber-400),var(--amber-700))`
  /// (`:1893`). 30 % down the well is -0.4 in [Alignment]'s -1..1 space, and
  /// a CSS radial gradient given no size is `farthest-corner`, which from
  /// there reaches sqrt(0.5² + 0.7²) of a square well's side — Flutter
  /// defaults to 0.5, which would compress amber 700 into the middle.
  static const Alignment gradientCentre = Alignment(0, -0.4);
  static const double gradientRadius = 0.86;

  /// The lit well's rim and emission: LightCard.jsx
  /// `inset 0 1px 0 rgba(255,255,255,.35),0 0 20px -4px rgba(255,176,32,.7)`
  /// (`:1894`). Unlit it is the plain `--elev-well` of every other well.
  static const double rimOffsetY = 1;
  static const double rimAlpha = 0.35;
  static const double glowBlur = 20;
  static const double glowSpread = -4;
  static const double glowAlpha = 0.7;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var m = wiz.motion;
    return AnimatedSwitcher(
      // The gradient and the shadows both change with the state and neither
      // interpolates, so the two wells cross-fade — the recipe `WizToggle`
      // uses for its track.
      duration: m.light,
      switchInCurve: m.tactile,
      switchOutCurve: m.tactile,
      child: _face(wiz),
    );
  }

  Widget _face(WizTheme wiz) {
    var c = wiz.colors;
    return WizSurface(
      // Identity, so the switcher cross-fades on the state rather than
      // rebuilding one surface whose paint would jump.
      key: ValueKey(lit),
      spec: lit
          ? WizShadowSpec(
              insets: [
                WizInset(
                  offsetY: rimOffsetY,
                  blur: 0,
                  color: c.highlightBase.withValues(alpha: rimAlpha),
                ),
              ],
              outer: [
                BoxShadow(
                  color: c.amber500.withValues(alpha: glowAlpha),
                  blurRadius: glowBlur,
                  spreadRadius: glowSpread,
                ),
              ],
            )
          : wiz.elevation.well,
      radius: BorderRadius.circular(wiz.space.r2),
      gradient: lit
          ? RadialGradient(
              center: gradientCentre,
              radius: gradientRadius,
              colors: [c.amber400, c.amber700],
            )
          : null,
      color: lit ? null : c.char1000,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: WizIcon(
        icon,
        size: glyph,
        color: lit ? c.textOnAccent : c.textTertiary,
      ),
    );
  }
}
