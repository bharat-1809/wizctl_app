import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_sheet.dart';
import '../bloc/rooms_list_bloc.dart';
import '../bloc/rooms_list_event.dart';
import '../bloc/rooms_list_state.dart';
import 'add_room_sheet.dart';

/// Long-press on a room row (spec §10.6): Rename room, and Delete room,
/// which is inert with "Move its lights first" while the room holds any.
Future<void> showRoomActionsSheet(
  BuildContext context, {
  required RoomRow row,
}) {
  var bloc = context.read<RoomsListBloc>();
  var navigator = Navigator.of(context, rootNavigator: true);
  var hasLights = row.lightCount > 0;
  return showWizSheet<void>(
    context,
    title: row.room.name,
    builder: (sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WizListRow(
          icon: WizIcons.pencil,
          title: Strings.renameRoom,
          onTap: () async {
            navigator.pop();
            // The screen's context, not this sheet's: that one is on its way
            // out, and `showRoomSheet` reads the root navigator from what it
            // is handed.
            var result = await showRoomSheet(
              context,
              title: Strings.renameRoom,
              primaryLabel: Strings.saveRoom,
              initialName: row.room.name,
              initialGlyph: null,
            );
            if (result != null) {
              bloc.add(RoomRenamed(row.room.id, result.name));
            }
          },
        ),
        SizedBox(height: sheetContext.wiz.space.s3),
        WizListRow(
          icon: WizIcons.trash,
          title: Strings.deleteRoom,
          meta: hasLights ? Strings.moveLightsFirst : null,
          onTap: hasLights
              ? null
              : () {
                  bloc.add(RoomDeleted(row.room.id));
                  navigator.pop();
                },
        ),
      ],
    ),
  );
}
