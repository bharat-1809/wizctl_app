import 'package:flutter/material.dart';

import '../theme/wiz_textures.dart';
import '../theme/wiz_theme.dart';
import '../theme/wiz_type.dart';
import 'wiz_slider.dart';
import 'wiz_surface.dart';

/// Which brightness control a `LightCard` carries under its header: the
/// draggable rail (a phone, and a room's list), a read-only meter (the
/// desktop grid, where the rail belongs to the inspector instead), or
/// neither — a plug switches power only, so there is nothing to dim.
enum WizBrightnessControl { rail, meter, none }

/// A `LightCard`'s second row when the light is lit and dims: either the
/// draggable rail or the read-only meter. Internal to the card, which
/// decides whether there is a control to show at all — [control] is never
/// [WizBrightnessControl.none] here.
class LightCardBrightness extends StatelessWidget {
  final WizBrightnessControl control;

  /// What the bulb reported, on the rail's own scale.
  final double brightness;

  /// The same value as the whole percentage both faces show, computed by
  /// the card so the rail's readout and the meter cannot disagree.
  final int pct;

  final ValueChanged<double>? onBrightness;
  final ValueChanged<double>? onBrightnessEnd;

  const LightCardBrightness({
    super.key,
    required this.control,
    required this.brightness,
    required this.pct,
    this.onBrightness,
    this.onBrightnessEnd,
  }) : assert(control != WizBrightnessControl.none);

  /// What a bulb dims between (spec §5, `brightness /*10–100*/`; LightCard.jsx
  /// `min: 10, max: 100`, `design/reference/_ds_bundle.js:1936`). Stated here
  /// rather than read from the `wizctl` package: the kit knows no protocol.
  static const double brightnessMin = 10;
  static const double brightnessMax = 100;

  /// The read-only meter: LightCard.jsx `height: 6` (`:1950`); spec §11.2,
  /// "6 px meter with amber 700 → 300 fill".
  static const double meterThickness = 6;

  /// Its readout: LightCard.jsx `fontSize: 18, fontWeight: 800` (`:1969`,
  /// `:1970`) — the size `readoutSm` already carries, stated so the tracking
  /// beside it reads as the em value it is — and the unit's `fontSize: 10.5`
  /// (`:1977`). Spec §11.2, "an 18 display readout".
  static const double meterReadoutSize = 18;
  static const FontWeight meterReadoutWeight = FontWeight.w800;
  static const double meterUnitSize = 10.5;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return control == WizBrightnessControl.rail ? _rail() : _meter(wiz);
  }

  /// The draggable rail: LightCard.jsx `:1934`–`:1940`.
  Widget _rail() {
    return WizSlider(
      value: brightness,
      min: brightnessMin,
      max: brightnessMax,
      // A card given no handler has nothing to report a drag to, so the
      // rail is shown but inert rather than live and silently dropping the
      // write: a null handler is what makes it inert.
      onChanged: onBrightness,
      onChangeEnd: onBrightnessEnd,
      label: 'Brightness',
      readout: '$pct%',
    );
  }

  /// The read-only meter: a recessed rail with an amber fill and the
  /// percentage beside it. Shown where the drag belongs to something else —
  /// the desktop grid, whose inspector owns the rail.
  Widget _meter(WizTheme wiz) {
    var c = wiz.colors;
    var m = wiz.motion;
    var pill = BorderRadius.circular(wiz.space.pill);
    return Row(
      // LightCard.jsx `gap: 12` (`:1945`).
      spacing: wiz.space.s5,
      children: [
        Expanded(
          child: WizSurface(
            spec: wiz.elevation.well,
            radius: pill,
            gradient: wizVertical(c.char1000, c.char900),
            height: meterThickness,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: m.light,
                curve: m.tactile,
                widthFactor: pct / 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: pill,
                    // LightCard.jsx
                    // `linear-gradient(90deg,var(--amber-700),var(--amber-300))`
                    // (`:1962`), which is what a `LinearGradient` left to its
                    // own `centerLeft` → `centerRight` already draws.
                    gradient: LinearGradient(colors: [c.amber700, c.amber300]),
                  ),
                  child: const SizedBox(height: meterThickness),
                ),
              ),
            ),
          ),
        ),
        Text.rich(
          TextSpan(
            text: '$pct',
            children: [
              TextSpan(
                text: '%',
                style: TextStyle(
                  fontSize: meterUnitSize,
                  color: c.textTertiary,
                ),
              ),
            ],
          ),
          style: wiz.typography.readoutSm.copyWith(
            fontSize: meterReadoutSize,
            fontWeight: meterReadoutWeight,
            letterSpacing: meterReadoutSize * WizType.meterReadoutTracking,
            color: c.amber400,
          ),
        ),
      ],
    );
  }
}
