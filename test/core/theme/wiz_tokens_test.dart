import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_elevation.dart';
import 'package:wizctl_app/core/theme/wiz_motion.dart';
import 'package:wizctl_app/core/theme/wiz_space.dart';

void main() {
  test('spacing scale and hardware sizes', () {
    const s = WizSpace.standard;
    expect(
      [
        s.s1,
        s.s2,
        s.s3,
        s.s4,
        s.s5,
        s.s6,
        s.s7,
        s.s8,
        s.s9,
        s.s10,
        s.s11,
        s.s12,
      ],
      [2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 56, 72],
    );
    expect([s.r1, s.r2, s.r3, s.r4, s.r5, s.r6], [6, 10, 14, 20, 28, 36]);
    expect(s.hitMin, 44);
    expect(s.knobLg, 168);
    expect(s.rail, 264);
    expect(s.inspector, 352);
    expect(s.tabBar, 72);
    expect(s.tabBarFloat, 18);
  });

  test('elevation recipes carry their insets and outer shadows', () {
    const e = WizElevation.standard;
    expect(e.panel.insets, hasLength(1));
    expect(e.panel.outer, hasLength(2));
    expect(e.well.insets.first.blur, 7);
    expect(e.well.insets.first.offsetY, 3);
    expect(e.knob.outer.last.blurRadius, 40);
    expect(e.knob.outer.last.spreadRadius, -14);
    expect(e.glowAmberStrong, hasLength(3));
    expect(e.glowAmber.first.color, const Color(0x33FFB020));
  });

  test('motion durations and curves', () {
    const m = WizMotion.standard;
    expect(m.press, const Duration(milliseconds: 80));
    expect(m.release, const Duration(milliseconds: 140));
    expect(m.panel, const Duration(milliseconds: 260));
    expect(m.light, const Duration(milliseconds: 420));
    expect(m.breathe, const Duration(milliseconds: 5500));
    expect(m.tactile, const Cubic(.2, .8, .2, 1));
    expect(m.settle, const Cubic(.16, 1.02, .3, 1));
    expect(m.pressTravel, 1.5);
  });
}
