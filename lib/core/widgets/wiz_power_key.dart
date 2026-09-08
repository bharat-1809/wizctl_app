import 'package:flutter/material.dart';

import '../feedback/feedback_kind.dart';
import '../icons/wiz_icon.dart';
import '../icons/wiz_icon_data.dart';
import '../theme/wiz_elevation.dart';
import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import 'wiz_glow.dart';
import 'wiz_pressable.dart';
import 'wiz_surface.dart';

enum WizPowerKeySize { md, lg }

/// Hero power control. Off is dead charcoal; on is tungsten glow that ramps
/// in over the light duration, the bulb physically warming.
class WizPowerKey extends StatelessWidget {
  final bool on;
  final ValueChanged<bool>? onChanged;
  final WizPowerKeySize size;
  final bool enabled;

  const WizPowerKey({
    super.key,
    required this.on,
    required this.onChanged,
    this.size = WizPowerKeySize.lg,
    this.enabled = true,
  });

  // Design system PowerKey.jsx: diameters, glyph ratio, press travel.
  static const _diameter = {
    WizPowerKeySize.md: 96.0,
    WizPowerKeySize.lg: 132.0,
  };
  static const double glyphRatio = 0.34;
  static const double travel = 2;

  // PowerKey.jsx on-fill: `radial-gradient(circle at 50% 32%,
  // var(--amber-300),var(--amber-500) 58%,var(--amber-700))`. CSS position
  // percentages map onto Flutter's -1..1 `Alignment` space (0% → -1, 100% →
  // 1), so 50%/32% becomes `Alignment(0, -0.36)`; the un-stopped amber-700
  // lands at the gradient's end, stop `1`.
  static const Alignment _onGradientCentre = Alignment(0, -0.36);
  static const List<double> _onGradientStops = [0, .58, 1];

  // CSS `radial-gradient` with no explicit size is `farthest-corner`: from
  // (0.5, 0.32) of a unit square that is `sqrt(0.5^2 + 0.68^2) ≈ 0.844` of
  // the side, versus Flutter's `RadialGradient.radius` default of 0.5, which
  // would compress the stops into the centre.
  static const double _onGradientRadius = 0.844;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var c = wiz.colors;
    var m = wiz.motion;
    var d = _diameter[size]!;
    var radius = BorderRadius.circular(d / 2);
    var offGradient = wizVertical(c.surfaceKey, c.char900);
    var onGradient = RadialGradient(
      center: _onGradientCentre,
      radius: _onGradientRadius,
      colors: [c.amber300, c.amber500, c.amber700],
      stops: _onGradientStops,
    );
    return WizPressable(
      onTap: onChanged == null ? null : () => onChanged!(!on),
      enabled: enabled && onChanged != null,
      feedback: on ? FeedbackKind.toggleOff : FeedbackKind.power,
      scale: m.pressScale,
      travel: travel,
      semanticsLabel: 'Power',
      // The key is a switch, not a plain button: assistive tech hears
      // whether the light is on.
      toggled: on,
      // The ring traces the circle, not a rounded box around it.
      focusRadius: radius,
      builder: (context, state) => SizedBox(
        width: d,
        height: d,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WizGlow(
              on: on && !state.pressed,
              shadows: wiz.elevation.glowAmberStrong,
              radius: radius,
            ),
            WizSurface(
              spec: state.pressed ? wiz.elevation.pressed : wiz.elevation.knob,
              radius: radius,
              gradient: offGradient,
            ),
            AnimatedOpacity(
              opacity: on ? 1 : 0,
              duration: m.light,
              curve: m.tactile,
              // Insets only: the off surface underneath already draws the
              // outer cast shadow once. Stacking the full knob/pressed spec
              // here too would compound it under the glow when lit.
              child: WizSurface(
                spec: WizShadowSpec(
                  insets:
                      (state.pressed
                              ? wiz.elevation.pressed
                              : wiz.elevation.knob)
                          .insets,
                ),
                radius: radius,
                gradient: onGradient,
              ),
            ),
            Center(
              child: AnimatedDefaultTextStyle(
                duration: m.light,
                curve: m.tactile,
                style: TextStyle(color: on ? c.textOnAccent : c.textTertiary),
                child: WizIcon(WizIcons.power, size: d * glyphRatio),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
