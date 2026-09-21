import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/dual_dials.dart';
import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../domain/entities/entities.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';

/// "WHOLE ROOM": the two dials, the kelvin note and the Light mode row
/// (spec §10.3).
class WholeRoomPanel extends StatelessWidget {
  final double dialSize;
  const WholeRoomPanel({super.key, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<RoomBloc>();
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) => WizPanel(
        variant: WizPanelVariant.inset,
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.panelPad,
          vertical: wiz.space.panelPadLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel(Strings.wholeRoom),
            SizedBox(height: wiz.space.s5),
            DualDials(
              brightness: state.brightness,
              kelvin: state.canKelvin ? state.kelvin : null,
              onBrightness: (v) => bloc.add(RoomBrightnessChanged(v)),
              onKelvin: (k) => bloc.add(RoomKelvinChanged(k)),
              preferredSize: dialSize,
              note: state.kelvinNote,
            ),
            SizedBox(height: wiz.space.s5),
            ModeRow(
              art: modeArtOf(state.summary.art),
              name: state.summary.name,
              onTap: () => showModesSheet(
                context,
                target: RoomTarget(bloc.roomId),
                blocFor: context.read<ModesBlocFactory>(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
