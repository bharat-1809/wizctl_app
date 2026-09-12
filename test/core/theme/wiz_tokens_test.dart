import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/core/theme/wiz_colors.dart';
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
    final e = WizElevation.standard;
    final colors = WizColors.standard;

    expect(e.panel.insets, hasLength(1));
    expect(e.panel.outer, hasLength(2));
    expect(e.well.insets.first.blur, 7);
    expect(e.well.insets.first.offsetY, 3);
    expect(e.knob.outer.last.blurRadius, 40);
    expect(e.knob.outer.last.spreadRadius, -14);
    expect(e.glowAmberStrong, hasLength(3));

    // Panel: alpha from highlightBase (0.075) and shadowBase (0.30 and 0.60)
    expect(e.panel.insets.first.color.a, closeTo(0.075, 0.002));
    expect(e.panel.outer.first.color.a, closeTo(0.30, 0.002));
    expect(e.panel.outer.last.color.a, closeTo(0.60, 0.002));
    expect(
      e.panel.insets.first.color,
      colors.highlightBase.withValues(alpha: 0.075),
    );
    expect(e.panel.outer.last.color, colors.shadowBase.withValues(alpha: 0.60));

    // Raised: alpha from highlightBase (0.13) and shadowBase (0.35 and 0.60)
    expect(e.raised.insets.first.color.a, closeTo(0.13, 0.002));
    expect(e.raised.insets.last.color.a, closeTo(0.40, 0.002));
    expect(e.raised.outer.first.color.a, closeTo(0.35, 0.002));
    expect(e.raised.outer.last.color.a, closeTo(0.60, 0.002));
    expect(
      e.raised.insets.first.color,
      colors.highlightBase.withValues(alpha: 0.13),
    );
    expect(
      e.raised.outer.last.color,
      colors.shadowBase.withValues(alpha: 0.60),
    );

    // Key: alpha from highlightBase (0.13) and shadowBase (0.42 and 0.60)
    expect(e.key.insets.first.color.a, closeTo(0.13, 0.002));
    expect(e.key.insets.last.color.a, closeTo(0.45, 0.002));
    expect(e.key.outer.first.color.a, closeTo(0.42, 0.002));
    expect(e.key.outer.last.color.a, closeTo(0.60, 0.002));
    expect(
      e.key.insets.first.color,
      colors.highlightBase.withValues(alpha: 0.13),
    );
    expect(e.key.outer.last.color, colors.shadowBase.withValues(alpha: 0.60));

    // Knob: alpha from highlightBase (0.13) and shadowBase (0.45 and 0.60)
    expect(e.knob.insets.first.color.a, closeTo(0.13, 0.002));
    expect(e.knob.insets.last.color.a, closeTo(0.50, 0.002));
    expect(e.knob.outer.first.color.a, closeTo(0.45, 0.002));
    expect(e.knob.outer.last.color.a, closeTo(0.60, 0.002));
    expect(
      e.knob.insets.first.color,
      colors.highlightBase.withValues(alpha: 0.13),
    );
    expect(e.knob.outer.last.color, colors.shadowBase.withValues(alpha: 0.60));

    // Pressed: alpha from shadowBase (0.62) and highlightBase (0.075)
    expect(e.pressed.insets.first.color.a, closeTo(0.62, 0.002));
    expect(e.pressed.insets.last.color.a, closeTo(0.075, 0.002));
    expect(
      e.pressed.insets.first.color,
      colors.shadowBase.withValues(alpha: 0.62),
    );
    expect(
      e.pressed.insets.last.color,
      colors.highlightBase.withValues(alpha: 0.075),
    );

    // Well: alpha from shadowBase (0.66) and highlightBase (0.075)
    expect(e.well.insets.first.color.a, closeTo(0.66, 0.002));
    expect(e.well.insets.last.color.a, closeTo(0.075, 0.002));
    expect(
      e.well.insets.first.color,
      colors.shadowBase.withValues(alpha: 0.66),
    );
    expect(
      e.well.insets.last.color,
      colors.highlightBase.withValues(alpha: 0.075),
    );

    // Well-deep: alpha from shadowBase (0.72) and highlightBase (0.075)
    expect(e.wellDeep.insets.first.color.a, closeTo(0.72, 0.002));
    expect(e.wellDeep.insets.last.color.a, closeTo(0.075, 0.002));
    expect(
      e.wellDeep.insets.first.color,
      colors.shadowBase.withValues(alpha: 0.72),
    );
    expect(
      e.wellDeep.insets.last.color,
      colors.highlightBase.withValues(alpha: 0.075),
    );

    // Overlay: alpha from shadowBase (0.85)
    expect(e.overlay.outer.first.color.a, closeTo(0.85, 0.002));
    expect(
      e.overlay.outer.first.color,
      colors.shadowBase.withValues(alpha: 0.85),
    );

    // Glow amber: RGB should match amber500
    expect(
      (e.glowAmber.first.color.r * 255).round(),
      (colors.amber500.r * 255).round(),
    );
    expect(
      (e.glowAmber.first.color.g * 255).round(),
      (colors.amber500.g * 255).round(),
    );
    expect(
      (e.glowAmber.first.color.b * 255).round(),
      (colors.amber500.b * 255).round(),
    );
    expect(e.glowAmber.first.color.a, closeTo(0.20, 0.002));

    expect(
      (e.glowAmber.last.color.r * 255).round(),
      (colors.amber500.r * 255).round(),
    );
    expect(
      (e.glowAmber.last.color.g * 255).round(),
      (colors.amber500.g * 255).round(),
    );
    expect(
      (e.glowAmber.last.color.b * 255).round(),
      (colors.amber500.b * 255).round(),
    );
    expect(e.glowAmber.last.color.a, closeTo(0.26, 0.002));

    // Glow amber strong: RGB should match amber500
    expect(
      (e.glowAmberStrong[0].color.r * 255).round(),
      (colors.amber500.r * 255).round(),
    );
    expect(
      (e.glowAmberStrong[0].color.g * 255).round(),
      (colors.amber500.g * 255).round(),
    );
    expect(
      (e.glowAmberStrong[0].color.b * 255).round(),
      (colors.amber500.b * 255).round(),
    );
    expect(e.glowAmberStrong[0].color.a, closeTo(0.28, 0.002));

    expect(
      (e.glowAmberStrong[1].color.r * 255).round(),
      (colors.amber500.r * 255).round(),
    );
    expect(
      (e.glowAmberStrong[1].color.g * 255).round(),
      (colors.amber500.g * 255).round(),
    );
    expect(
      (e.glowAmberStrong[1].color.b * 255).round(),
      (colors.amber500.b * 255).round(),
    );
    expect(e.glowAmberStrong[1].color.a, closeTo(0.30, 0.002));

    expect(
      (e.glowAmberStrong[2].color.r * 255).round(),
      (colors.amber500.r * 255).round(),
    );
    expect(
      (e.glowAmberStrong[2].color.g * 255).round(),
      (colors.amber500.g * 255).round(),
    );
    expect(
      (e.glowAmberStrong[2].color.b * 255).round(),
      (colors.amber500.b * 255).round(),
    );
    expect(e.glowAmberStrong[2].color.a, closeTo(0.10, 0.002));
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
