import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Shown rather than imported whole: the library's `LightState` is a bulb's
// reported pilot, and this bloc's `LightState` is the screen's state, so the
// bare import makes the name ambiguous.
import 'package:wizctl/wizctl.dart' show maxSpeed, minSpeed;

import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_slider.dart';
import '../../../domain/entities/entities.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';

/// The Light mode row, the speed rail on a dynamic scene, the note on a
/// static one (spec §10.4).
///
/// Everything here reads `state.summary`, which is the one summary the bloc
/// already computed for this light, rather than the state's own scene
/// getters: two sources for the same sentence is how a row and its note come
/// to disagree.
class LightModesPanel extends StatelessWidget {
  const LightModesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var summary = state.summary;
        return WizPanel(
          variant: WizPanelVariant.inset,
          padding: EdgeInsets.symmetric(
            horizontal: wiz.space.panelPad,
            vertical: wiz.space.panelPadLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModeRow(
                art: modeArtOf(summary.art),
                name: summary.name,
                onTap: () => showModesSheet(
                  context,
                  target: LightTarget(bloc.lightId),
                  blocFor: context.read<ModesBlocFactory>(),
                ),
              ),
              if (summary.isDynamicScene) ...[
                SizedBox(height: wiz.space.s5),
                WizSlider(
                  value: state.live.speed.toDouble(),
                  min: minSpeed.toDouble(),
                  max: maxSpeed.toDouble(),
                  fill: WizSliderFill.speed,
                  label: Strings.speed,
                  readout: '${state.live.speed}',
                  // Both ends: the use case throttles the stream of moves,
                  // and the repeat on release is what makes the value the
                  // finger left behind the one that lands.
                  onChanged: (v) => bloc.add(LightSpeedChanged(v.round())),
                  onChangeEnd: (v) => bloc.add(LightSpeedChanged(v.round())),
                ),
              ] else if (summary.isStaticScene) ...[
                SizedBox(height: wiz.space.s4),
                Text(
                  Strings.staticSceneNote(summary.name),
                  textAlign: TextAlign.center,
                  style: wiz.typography.bodySm.copyWith(
                    color: wiz.colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
