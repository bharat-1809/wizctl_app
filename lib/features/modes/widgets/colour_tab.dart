import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/util/color_maths.dart';
import '../../../core/widgets/wiz_color_wheel.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import 'modes_layout.dart';
import 'rgb_of.dart';
import 'swatch_row.dart';

/// The Colour tab: the wheel when the target has a colour bulb, then the
/// hue swatches and the white tiles (spec §10.5).
class ColourTab extends StatelessWidget {
  final ModesLayout layout;
  const ColourTab({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightModesBloc>();
    return BlocBuilder<LightModesBloc, LightModesState>(
      builder: (context, state) {
        var wheelRgb = state.wheelRgb;
        var hs = colorToHs(
          Color.fromARGB(255, wheelRgb.r, wheelRgb.g, wheelRgb.b),
        );
        var whites = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(Strings.whites),
            SizedBox(height: wiz.space.s3),
            Wrap(
              spacing: wiz.space.s3,
              runSpacing: wiz.space.s3,
              children: [
                for (var entry in wiz.colors.kelvinStops.entries)
                  WhiteTile(
                    kelvin: entry.key,
                    color: entry.value,
                    width: layout.whiteWidth,
                    height: layout.whiteHeight,
                    selected: ModeSummarizer.whiteSelected(
                      state.lights,
                      entry.key,
                    ),
                    onTap: () => bloc.add(WhitePicked(entry.key)),
                  ),
              ],
            ),
          ],
        );
        var swatches = SwatchRow(
          layout: layout,
          isSelected: (rgb) => ModeSummarizer.colourSelected(state.lights, rgb),
          onPick: (rgb) => bloc.add(ColourPicked(rgb)),
        );
        var wheel = state.hasWheel
            ? LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: WizColorWheel(
                    hue: hs.hue,
                    saturation: hs.saturation,
                    size: math.min(layout.wheel, constraints.maxWidth),
                    onChanged: (hsv) => bloc.add(
                      ColourPicked(rgbOf(hsvToColor(hsv.hue, hsv.saturation))),
                    ),
                    onChangeEnd: (hsv) => bloc.add(
                      ColourPicked(rgbOf(hsvToColor(hsv.hue, hsv.saturation))),
                    ),
                  ),
                ),
              )
            : null;
        if (layout == ModesLayout.desktopTab && wheel != null) {
          // Two columns on a desktop: the wheel left, the swatches right.
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: layout.wheel, child: wheel),
              SizedBox(width: wiz.space.s9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    swatches,
                    SizedBox(height: wiz.space.s6),
                    whites,
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wheel != null) ...[wheel, SizedBox(height: wiz.space.s6)],
            swatches,
            SizedBox(height: wiz.space.s6),
            whites,
          ],
        );
      },
    );
  }
}
