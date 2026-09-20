import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_stat_tile.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_state.dart';

/// Two tiles (spec §10.4): colour temp or class on the left, intensity or
/// power on the right. A bulb with no white channel has no temperature to
/// report, and a plug has no brightness, so each side falls back to the one
/// fact that bulb does have.
class LightStatTiles extends StatelessWidget {
  const LightStatTiles({super.key});

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var left = state.canKelvin
            ? WizStatTile(
                icon: WizIcons.thermometer,
                label: Strings.colourTempTile,
                value: '${state.live.kelvin}',
                unit: 'K',
              )
            : WizStatTile(
                icon: WizIcons.lightbulb,
                label: Strings.classTile,
                value: light.className,
              );
        var right = state.isSocket
            ? WizStatTile(
                icon: WizIcons.power,
                label: Strings.power,
                value: state.live.isOn ? Strings.on : Strings.off,
              )
            : WizStatTile(
                icon: WizIcons.gauge,
                label: Strings.intensity,
                value: '${state.live.brightness}',
                unit: '%',
                accent: state.live.isOn,
              );
        return Row(
          children: [
            Expanded(child: left),
            SizedBox(width: space.s5),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
