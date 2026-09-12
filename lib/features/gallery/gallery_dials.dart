import 'package:flutter/material.dart';

import '../../core/copy/strings.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_dial.dart';
import '../../core/widgets/wiz_panel.dart';
import '../../core/widgets/wiz_readout.dart';
import '../../core/widgets/wiz_slider.dart';
import 'gallery_section.dart';

/// The two continuous controls and the instrument readout they feed.
class GalleryDials extends StatefulWidget {
  /// Brightness and colour temperature are shared with the hero, so that
  /// dragging a dial visibly changes what the fixture emits.
  final double brightness;
  final double kelvin;
  final ValueChanged<double> onBrightness;
  final ValueChanged<double> onKelvin;

  const GalleryDials({
    super.key,
    required this.brightness,
    required this.kelvin,
    required this.onBrightness,
    required this.onKelvin,
  });

  /// Brightness is a percentage and never goes fully dark (spec §5.6).
  static const double minBrightness = 10, maxBrightness = 100;

  /// The kelvin range the lights accept, and the step the dial detents on.
  static const double minKelvin = 2200, maxKelvin = 6500, kelvinStep = 50;

  /// Dynamic scenes accept a speed from 10 to 200 (`Strings.dynamicPip`);
  /// the demo opens a little above the middle of that range.
  static const double minSpeed = 10, maxSpeed = 200, initialSpeed = 120;

  @override
  State<GalleryDials> createState() => _GalleryDialsState();
}

class _GalleryDialsState extends State<GalleryDials> {
  double _speed = GalleryDials.initialSpeed;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var space = wiz.space;
    var kelvin = widget.kelvin.round();
    return GallerySection(
      title: 'Dials and rails',
      child: WizPanel(
        variant: WizPanelVariant.inset,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                // Two dials side by side, each no smaller and no larger than
                // the knob tokens allow.
                var size = ((box.maxWidth - space.s5) / 2).clamp(
                  space.knobSm,
                  space.knobLg,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WizDial(
                      value: widget.brightness,
                      min: GalleryDials.minBrightness,
                      max: GalleryDials.maxBrightness,
                      size: size,
                      label: 'Brightness',
                      onChanged: widget.onBrightness,
                    ),
                    SizedBox(width: space.s5),
                    WizDial(
                      value: widget.kelvin,
                      min: GalleryDials.minKelvin,
                      max: GalleryDials.maxKelvin,
                      step: GalleryDials.kelvinStep,
                      size: size,
                      label: 'Colour temp.',
                      unit: 'K',
                      onChanged: widget.onKelvin,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: space.s6),
            WizSlider(
              value: widget.brightness,
              min: GalleryDials.minBrightness,
              max: GalleryDials.maxBrightness,
              fill: WizSliderFill.brightness,
              label: 'Brightness',
              readout: '${widget.brightness.round()}%',
              onChanged: widget.onBrightness,
            ),
            SizedBox(height: space.s5),
            WizSlider(
              value: _speed,
              min: GalleryDials.minSpeed,
              max: GalleryDials.maxSpeed,
              fill: WizSliderFill.speed,
              label: 'Speed',
              readout: '${_speed.round()}',
              onChanged: (v) => setState(() => _speed = v),
            ),
            SizedBox(height: space.s5),
            WizSlider(
              value: widget.kelvin,
              min: GalleryDials.minKelvin,
              max: GalleryDials.maxKelvin,
              step: GalleryDials.kelvinStep,
              fill: WizSliderFill.kelvin,
              label: 'Colour temp.',
              readout: '${kelvin}K',
              onChanged: widget.onKelvin,
            ),
            SizedBox(height: space.s6),
            // Wrapped, not a row: three readouts at their design sizes are
            // wider than a phone column once the text scale grows.
            Wrap(
              spacing: space.s7,
              runSpacing: space.s6,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                WizReadout(
                  value: '${widget.brightness.round()}',
                  unit: '%',
                  label: 'Brightness',
                  size: WizReadoutSize.lg,
                  tone: WizReadoutTone.accent,
                ),
                WizReadout(
                  value: '$kelvin',
                  unit: 'K',
                  label: Strings.warmWhite,
                ),
                WizReadout(
                  value: '${_speed.round()}',
                  label: 'Speed',
                  size: WizReadoutSize.sm,
                  tone: WizReadoutTone.muted,
                  mono: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
