import 'package:flutter/material.dart';

import '../theme/wiz_colors.dart';

/// The fill gradient differs per purpose (Slider.jsx SLIDER_FILLS), plus a
/// live-colour fill for brightness in colour mode (handoff proposal).
class WizSliderFill {
  final List<Color> Function(WizColors c) colors;

  /// Brightness and kelvin fills carry the amber glow.
  final bool glows;

  const WizSliderFill._(this.colors, this.glows);

  static final WizSliderFill brightness = WizSliderFill._(
    (c) => [c.railDark, c.amber300],
    true,
  );
  static final WizSliderFill kelvin = WizSliderFill._(
    (c) => [
      c.kelvinStops[2200]!,
      c.kelvinStops[3500]!,
      c.kelvinStops[4500]!,
      c.kelvinStops[6500]!,
    ],
    true,
  );
  static final WizSliderFill speed = WizSliderFill._(
    (c) => [c.railDark, c.hueCyan],
    false,
  );
  static final WizSliderFill neutral = WizSliderFill._(
    (c) => [c.railDark, c.railMid],
    false,
  );

  /// A fill in the light's own colour, for brightness while a hue is set.
  factory WizSliderFill.colour(Color color) =>
      WizSliderFill._((_) => [color, color], false);
}
