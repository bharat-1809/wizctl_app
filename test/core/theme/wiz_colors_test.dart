import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
import 'package:wizctl_app/core/theme/wiz_type.dart';

void main() {
  const c = WizColors.standard;

  test('the accent is tungsten amber and ink is warm off-white', () {
    expect(c.amber500, const Color(0xFFFFB020));
    expect(c.ink1000, const Color(0xFFF6F3ED));
    expect(c.textPrimary, c.ink1000);
    expect(c.accent, c.amber500);
  });

  test('semantic surfaces alias the charcoal ramp', () {
    expect(c.surfaceApp, c.char950);
    expect(c.surfacePanel, c.char850);
    expect(c.surfaceRaised, c.char800);
    expect(c.surfaceKey, c.char750);
    expect(c.surfaceWell, c.char1000);
  });

  test('the twelve hues and six kelvin stops are present', () {
    expect(c.hues, hasLength(12));
    expect(c.hues.first, const Color(0xFFFF4A3D));
    expect(c.kelvinStops.keys, [2200, 2700, 3500, 4500, 5500, 6500]);
    expect(c.kelvinStops[6500], const Color(0xFFDCE9FF));
  });

  test('disabled controls use the spec-defined opacity token', () {
    expect(WizColors.disabledAlpha, 0.42);
  });

  test('type styles carry the design faces and sizes', () {
    const t = WizType.standard;
    expect(t.hero.fontFamily, WizType.familyDisplay);
    expect(t.hero.fontSize, 64);
    expect(t.hero.fontWeight, FontWeight.w800);
    expect(t.body.fontFamily, WizType.familyUi);
    expect(t.body.fontSize, 15);
    expect(t.code.fontFamily, WizType.familyMono);
    expect(t.label.letterSpacing, closeTo(11 * 0.10, 0.001));
    expect(
      t.readout.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  test('the three tracking scalars used across the kit are defined in em', () {
    expect(WizType.labelTracking, 0.10);
    expect(WizType.segmentTracking, 0.08);
    expect(WizType.sceneLabelTracking, 0.02);
  });
}
