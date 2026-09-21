import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_list_row.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/rooms_list_bloc.dart';
import '../bloc/rooms_list_event.dart';
import '../bloc/rooms_list_state.dart';
import '../widgets/add_room_sheet.dart';
import '../widgets/room_actions_sheet.dart';

/// The Rooms tab (spec §10.6).
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  /// The chevron at the end of a row (`WizCtl_Mobile.dc.html` line 416).
  static const double chevron = 18;

  Future<void> _add(BuildContext context) async {
    var bloc = context.read<RoomsListBloc>();
    var result = await showRoomSheet(
      context,
      title: Strings.addARoom,
      primaryLabel: Strings.saveRoom,
      showNote: true,
    );
    if (result != null) bloc.add(RoomAdded(result.name, result.glyph));
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<RoomsListBloc, RoomsListState>(
      builder: (context, state) => ScreenScroll(
        gap: wiz.space.s5,
        children: [
          WizTopBar(
            title: Strings.rooms,
            subtitle: Strings.roomsAndLights(
              state.rooms.length,
              state.lightCount,
            ),
            trailing: WizIconKey(
              icon: WizIcons.plus,
              semanticsLabel: Strings.addRoom,
              onPressed: () => _add(context),
            ),
          ),
          for (var (i, row) in state.rooms.indexed)
            RiseIn(
              index: i,
              child: WizListRow(
                icon: WizIcons.byName(row.room.glyph.iconName)!,
                title: row.room.name,
                meta: Strings.lightsOn(row.lightCount, row.onCount),
                trailing: WizIcon(
                  WizIcons.chevronRight,
                  size: chevron,
                  color: wiz.colors.textTertiary,
                ),
                onTap: () => context.go(AppRoutes.room(row.room.id)),
                onLongPress: () => showRoomActionsSheet(context, row: row),
              ),
            ),
          WizButton(
            label: Strings.addRoom,
            variant: WizButtonVariant.ghost,
            icon: WizIcons.housePlus,
            fullWidth: true,
            onPressed: () => _add(context),
          ),
          WizPanel(
            variant: WizPanelVariant.inset,
            child: Text(
              Strings.roomsStored,
              style: wiz.typography.bodySm.copyWith(
                color: wiz.colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
