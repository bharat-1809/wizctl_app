import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wizctl_app/core/theme/wiz_colors.dart';

/// The kelvin stops, in ascending order, sourced from `WizColors.kelvinStops`
/// (the single definition of the ramp).
final List<MapEntry<int, Color>> _kelvinEntries = WizColors
    .standard
    .kelvinStops
    .entries
    .toList();

/// The kelvin ramp, spec §5.5. Linear interpolation between the stops in
/// `WizColors.kelvinStops`; clamped outside them.
Color kelvinToColor(int kelvin) {
  if (kelvin <= _kelvinEntries.first.key) return _kelvinEntries.first.value;
  for (var i = 1; i < _kelvinEntries.length; i++) {
    var stop = _kelvinEntries[i];
    if (kelvin <= stop.key) {
      var previous = _kelvinEntries[i - 1];
      var t = (kelvin - previous.key) / (stop.key - previous.key);
      return Color.lerp(previous.value, stop.value, t)!;
    }
  }
  return _kelvinEntries.last.value;
}

/// HSV with V = 1, the colour wheel's model (design system `hsvToRgb`).
Color hsvToColor(double hue, double saturation) {
  int channel(int n) {
    var k = (n + hue / 60) % 6;
    var v = 1 - saturation * math.max(0, math.min(k, math.min(4 - k, 1)));
    return (255 * v).round().clamp(0, 255);
  }

  return Color.fromARGB(255, channel(5), channel(3), channel(1));
}

/// Hue in degrees and saturation in [0, 1] of a colour (design system `rgbHs`).
({double hue, double saturation}) colorToHs(Color color) {
  var r = color.r, g = color.g, b = color.b;
  var max = math.max(r, math.max(g, b));
  var min = math.min(r, math.min(g, b));
  var d = max - min;
  var h = 0.0;
  if (d != 0) {
    if (max == r) {
      h = ((g - b) / d) % 6;
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h = (h * 60 + 360) % 360;
  }
  return (hue: h, saturation: max == 0 ? 0 : d / max);
}
