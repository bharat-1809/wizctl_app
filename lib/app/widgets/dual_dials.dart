import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wizctl/wizctl.dart';

import '../../core/copy/strings.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/wiz_dial.dart';
import '../../domain/services/live_state_mapper.dart';

/// Brightness and, when the target has a white channel, colour temperature,
/// side by side: the whole-room panel, the light's dials panel and the
/// desktop inspector all draw this (spec §10.3, §10.4, §10.9). The dials
/// split the width minus the gap and clamp to the kit's range (spec §14);
/// the note, when given, sits centred beneath.
class DualDials extends StatelessWidget {
  final int brightness;
  final int? kelvin;
  final ValueChanged<int> onBrightness;
  final ValueChanged<int>? onKelvin;
  final double preferredSize;
  final String? note;

  const DualDials({
    super.key,
    required this.brightness,
    this.kelvin,
    required this.onBrightness,
    this.onKelvin,
    required this.preferredSize,
    this.note,
  });

  /// The diameter [count] dials get when they share [width] with [gap]
  /// between them: never more than [preferred], never outside the kit's own
  /// range, so a narrow window shrinks the knobs rather than overflowing.
  static double sizeFor({
    required double width,
    required int count,
    required double gap,
    required double preferred,
  }) {
    var available = (width - gap * (count - 1)) / count;
    return math
        .min(preferred, available)
        .clamp(WizDial.minSize, WizDial.maxSize);
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var gap = wiz.space.s5;
    var kelvin = this.kelvin;
    var note = this.note;
    return LayoutBuilder(
      builder: (context, constraints) {
        var size = sizeFor(
          width: constraints.maxWidth,
          count: kelvin == null ? 1 : 2,
          gap: gap,
          preferred: preferredSize,
        );
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WizDial(
                  value: brightness.toDouble(),
                  min: minBrightness.toDouble(),
                  max: maxBrightness.toDouble(),
                  unit: '%',
                  label: Strings.brightness,
                  size: size,
                  // Both ends: the use case throttles the stream of moves,
                  // and the repeat on release is what makes the value the
                  // finger left behind the one that lands.
                  onChanged: (v) => onBrightness(v.round()),
                  onChangeEnd: (v) => onBrightness(v.round()),
                ),
                if (kelvin != null) ...[
                  SizedBox(width: gap),
                  WizDial(
                    value: kelvin.toDouble(),
                    min: typicalMinTemperature.toDouble(),
                    max: typicalMaxTemperature.toDouble(),
                    step: LiveStateMapper.kelvinStep.toDouble(),
                    unit: 'K',
                    label: Strings.colourTemp,
                    size: size,
                    onChanged: (v) => onKelvin?.call(v.round()),
                    onChangeEnd: (v) => onKelvin?.call(v.round()),
                  ),
                ],
              ],
            ),
            if (note != null) ...[
              SizedBox(height: wiz.space.s4),
              Text(
                note,
                textAlign: TextAlign.center,
                style: wiz.typography.bodySm.copyWith(
                  color: wiz.colors.textTertiary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
