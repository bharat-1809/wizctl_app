import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/room_card.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/home_screen_bloc.dart';
import '../bloc/home_screen_event.dart';
import '../bloc/home_screen_state.dart';
import '../widgets/all_lights_panel.dart';
import '../widgets/homes_sheet.dart';
import '../widgets/unreachable_line.dart';

/// Home on a phone (spec §10.2): the home's name and counts, the wrong-
/// network banner when it applies, the All lights panel, the not-answering
/// line, and the room grid rising in.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Two room cards across a phone (spec §10.2, "min tile 150").
  static const double roomTileMin = 150;

  @override
  Widget build(BuildContext context) {
    var space = context.wiz.space;
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return BlocBuilder<HomeScreenBloc, HomeScreenState>(
      builder: (context, state) {
        var home = state.home;
        var bloc = context.read<HomeScreenBloc>();
        // The two conditions are split deliberately (P97). `loading` stays
        // blank, so nothing flashes on the way in; but a home that exists with
        // none active — what a `FinishOnboarding` that failed between the home
        // insert and the `activeHomeId` write leaves — must still reach the
        // Homes sheet, because on a phone this key and the desktop rail are
        // the only two `showHomesSheet` call sites.
        if (state.status == HomeScreenStatus.loading) {
          return const ScreenScroll(children: []);
        }
        if (home == null) {
          return ScreenScroll(
            children: [
              WizTopBar(
                title: Strings.noHomeSelected,
                subtitle: Strings.openHomesToPick,
                leading: WizIconKey(
                  icon: WizIcons.house,
                  semanticsLabel: Strings.homes,
                  onPressed: () => showHomesSheet(context),
                ),
              ),
            ],
          );
        }
        return ScreenScroll(
          // Awaited, not fired and forgotten: the filament has to stay up for
          // as long as the read takes, and an event added to a bloc is over
          // on the next microtask.
          onRefresh: () {
            var done = Completer<void>();
            bloc.add(HomeRefreshRequested(done: done));
            return done.future;
          },
          children: [
            WizTopBar(
              title: home.name,
              subtitle: Strings.roomsAndLights(
                state.rooms.length,
                state.lightCount,
              ),
              leading: WizIconKey(
                icon: WizIcons.house,
                semanticsLabel: Strings.homes,
                onPressed: () => showHomesSheet(context),
              ),
              trailing: WizIconKey(
                icon: WizIcons.radio,
                semanticsLabel: Strings.discoverLights,
                onPressed: () => context.go(AppRoutes.discover),
              ),
            ),
            if (offNetwork) const OffNetworkBanner(),
            AllLightsPanel(
              onCount: state.onCount,
              total: state.lightCount,
              onToggle: (on) => bloc.add(AllPowerToggled(on)),
            ),
            if (state.unreachableCount > 0)
              UnreachableLine(count: state.unreachableCount),
            WizGrid(
              minTile: roomTileMin,
              gap: space.s6,
              children: [
                for (var (i, tile) in state.rooms.indexed)
                  RiseIn(
                    index: i,
                    child: RoomCard(
                      name: tile.room.name,
                      icon: WizIcons.byName(tile.room.glyph.iconName)!,
                      lightCount: tile.lightCount,
                      onCount: tile.onCount,
                      on: tile.anyOn,
                      onToggle: (on) =>
                          bloc.add(HomeRoomPowerToggled(tile.room.id, on)),
                      onTap: () => context.go(AppRoutes.room(tile.room.id)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
