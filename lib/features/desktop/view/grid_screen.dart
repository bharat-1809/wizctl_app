import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/homes_bloc.dart';
import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/field_label.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../app/widgets/unreachable_banner.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/util/plural.dart';
import '../../../core/widgets/toast_controller.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_toggle.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/usecases/usecases.dart';
import '../../home/bloc/home_screen_bloc.dart';
import '../../home/bloc/home_screen_event.dart';
import '../../home/bloc/home_screen_state.dart';
import '../../rooms/bloc/room_bloc.dart';
import '../../rooms/bloc/room_event.dart';
import '../../rooms/bloc/room_state.dart';
import '../../rooms/widgets/add_room_sheet.dart';
import '../widgets/grid_room_panel.dart';
import '../widgets/grid_stats.dart';
import '../widgets/light_grid.dart';

/// The desktop's grid (spec §10.9): every light of the home over the
/// `HomeScreenBloc` the `/home` route provides, or one room's over its
/// `RoomBloc`.
///
/// Two readings of one layout — bar, banners, instrument tiles, cards — so
/// they share this file rather than diverging into two screens that have to be
/// kept in step. Both banners sit inside this scroll, where the design puts
/// them and where the phone's screens put theirs; the shell mounts none
/// (P79).
class GridScreen extends StatelessWidget {
  /// True for [GridScreen.room]. Private because the two constructors are the
  /// API: a caller picks a reading, it does not pass a flag.
  final bool _room;

  const GridScreen.allLights({super.key}) : _room = false;
  const GridScreen.room({super.key}) : _room = true;

  /// `WizCtl_Desktop.dc.html` `dialSize=140`; the phone draws the same two
  /// knobs at `RoomScreen.dialSize` = 132.
  static const double dialSize = 140;

  /// Opens the Add room sheet and toasts the empty room it made.
  ///
  /// Every lookup happens before the first await, so nothing reads the context
  /// across one.
  Future<void> _addRoom(BuildContext context) async {
    var homeId = context.read<HomesBloc>().state.activeHomeId;
    if (homeId == null) return;
    var addRoom = context.read<AddRoom>();
    var toasts = context.read<ToastController>();
    var result = await showRoomSheet(
      context,
      title: Strings.addARoom,
      primaryLabel: Strings.saveRoom,
      showNote: true,
    );
    if (result == null) return;
    // Guarded: this key writes straight through the use case with no bloc to
    // catch for it, so an `Object` — a closed database, a channel that went
    // away — would otherwise reach the framework as an unhandled error and the
    // user would see the sheet close and nothing happen.
    try {
      var room = await addRoom(homeId, result.name, result.glyph);
      toasts.push(
        tone: WizToastTone.success,
        title: Strings.roomSaved,
        body: Strings.roomIsEmpty(room.name),
      );
    } catch (_) {
      toasts.push(tone: WizToastTone.error, title: Strings.roomSaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    // The bar's trailing key on both readings: a desktop window has the room
    // for it where the phone's Home has the discovery key instead.
    var addRoom = WizButton(
      label: Strings.addRoom,
      variant: WizButtonVariant.ghost,
      size: WizButtonSize.sm,
      icon: WizIcons.housePlus,
      onPressed: () => _addRoom(context),
    );
    return _room
        ? _RoomGrid(addRoom: addRoom, offNetwork: offNetwork)
        : _AllLightsGrid(addRoom: addRoom, offNetwork: offNetwork);
  }
}

/// "All lights": the whole home, over the route's `HomeScreenBloc`.
class _AllLightsGrid extends StatelessWidget {
  final Widget addRoom;
  final bool offNetwork;

  const _AllLightsGrid({required this.addRoom, required this.offNetwork});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<HomeScreenBloc, HomeScreenState>(
      builder: (context, state) {
        var bloc = context.read<HomeScreenBloc>();
        return ScreenScroll(
          gap: wiz.space.s7,
          children: [
            WizTopBar(
              title: Strings.allLights,
              subtitle: Strings.lightsOn(state.lightCount, state.onCount),
              trailing: addRoom,
            ),
            if (offNetwork) const OffNetworkBanner(),
            GridStats(
              onCount: state.onCount,
              total: state.lightCount,
              unreachable: state.unreachableCount,
            ),
            if (state.unreachableCount > 0) const UnreachableBanner(),
            const FieldLabel(Strings.lights),
            LightGrid(
              lights: state.lights,
              onToggle: (id, on) => bloc.add(HomeLightPowerToggled(id, on)),
            ),
          ],
        );
      },
    );
  }
}

/// One room, over the route's `RoomBloc`.
class _RoomGrid extends StatelessWidget {
  final Widget addRoom;
  final bool offNetwork;

  const _RoomGrid({required this.addRoom, required this.offNetwork});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<RoomBloc, RoomState>(
      builder: (context, state) {
        var bloc = context.read<RoomBloc>();
        var room = state.room;
        if (room == null) {
          // A room deleted under the window, or an id that never named one.
          // The phone leaves for the rooms list (P63); here the rail is still
          // on screen, so the grid offers the way on instead. Blank while the
          // first read is in flight, or every room would flash "No room" on
          // its way in.
          return ScreenScroll(
            children: [
              if (state.status != RoomStatus.loading)
                WizTopBar(
                  title: Strings.noRoom,
                  subtitle: Strings.createRoomToGroup,
                  trailing: addRoom,
                ),
            ],
          );
        }
        var unreachable = state.aggregates?.unreachableCount ?? 0;
        return ScreenScroll(
          gap: wiz.space.s7,
          children: [
            WizTopBar(
              title: room.name,
              subtitle: plural(state.lights.length, 'light'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  addRoom,
                  SizedBox(width: wiz.space.s4),
                  WizToggle(
                    value: state.anyOn,
                    onChanged: (on) => bloc.add(RoomPowerToggled(on)),
                    semanticsLabel: Strings.roomPower(room.name),
                  ),
                ],
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            GridStats(
              onCount: state.aggregates?.onCount ?? 0,
              total: state.lights.length,
              unreachable: unreachable,
            ),
            // Narrowed to this room's lights (P80), so the count and the
            // name the banner reads out are its own and never another room's.
            // The gate stays even though the aggregate and the filtered list
            // agree: a banner that renders nothing still leaves
            // `ScreenScroll`'s separator behind it.
            if (unreachable > 0)
              UnreachableBanner(
                lightIds: {for (var live in state.lights) live.light.id},
              ),
            if (state.isEmpty)
              WizEmptyState(
                icon: WizIcons.lightbulb,
                title: Strings.noLightsInRoom,
                body: Strings.discoverThenSave,
                action: WizButton(
                  label: Strings.discoverLights,
                  variant: WizButtonVariant.primary,
                  onPressed: () => context.go(AppRoutes.discover),
                ),
              )
            else ...[
              const GridRoomPanel(dialSize: GridScreen.dialSize),
              const FieldLabel(Strings.lights),
              LightGrid(
                lights: state.lights,
                onToggle: (id, on) => bloc.add(RoomLightPowerToggled(id, on)),
              ),
            ],
          ],
        );
      },
    );
  }
}
