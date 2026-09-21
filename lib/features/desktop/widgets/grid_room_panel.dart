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
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../../rooms/bloc/room_state.dart';

/// "WHOLE ROOM" on a desktop (spec §10.9): the dials in the left column, the
/// Light mode row and the colour-temperature note in the right one.
///
/// The phone stacks the same three (`WholeRoomPanel`); a window this wide has
/// the room for them side by side, and the note reads as a caption under the
/// mode row rather than centred under the knobs.
class GridRoomPanel extends StatelessWidget {
  final double dialSize;

  const GridRoomPanel({super.key, required this.dialSize});

  /// `WizCtl_Desktop.dc.html` line 195: `gap:28px` between the two columns.
  static const double columnGap = 28;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<RoomBloc>();
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) => WizPanel(
        variant: WizPanelVariant.inset,
        padding: EdgeInsets.all(wiz.space.panelPadLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: columnGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModeRow(
                    art: modeArtOf(state.summary.art),
                    name: state.summary.name,
                    onTap: () => showModesSheet(
                      context,
                      target: RoomTarget(bloc.roomId),
                      blocFor: context.read<ModesBlocFactory>(),
                    ),
                  ),
                  if (state.kelvinNote case var note?) ...[
                    SizedBox(height: wiz.space.s4),
                    Text(
                      note,
                      style: wiz.typography.bodySm.copyWith(
                        color: wiz.colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
