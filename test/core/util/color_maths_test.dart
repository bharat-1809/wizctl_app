import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/util/color_maths.dart';

void main() {
  test('kelvin stops map exactly and interpolate between', () {
    expect(kelvinToColor(2200), const Color(0xFFFFB25C));
    expect(kelvinToColor(6500), const Color(0xFFDCE9FF));
    var mid = kelvinToColor(2450);
    expect((mid.g * 255).round(), closeTo((178 + 201) ~/ 2, 1));
    expect(kelvinToColor(1000), kelvinToColor(2200));
    expect(kelvinToColor(9000), kelvinToColor(6500));
  });

  test('hsv to colour matches the wheel maths', () {
    expect(hsvToColor(0, 1), const Color(0xFFFF0000));
    expect(hsvToColor(120, 1), const Color(0xFF00FF00));
    expect(hsvToColor(30, 0), const Color(0xFFFFFFFF));
  });

  test('colour to hue and saturation round-trips', () {
    var hs = colorToHs(const Color(0xFFFF8A2B));
    // The brief asserts closeTo(28, 1); the maths correctly yields 26.887 for
    // this colour, so the tolerance is tightened around the true value
    // instead of the maths being bent to fit a rounder number.
    expect(hs.hue, closeTo(26.9, 0.2));
    expect(hs.saturation, closeTo(0.83, 0.01));
  });
}
