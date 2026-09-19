import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wizctl/wizctl.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/navigation.dart';
import '../../../app/routes.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/util/plural.dart';
import '../../../core/widgets/light_card.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_empty_state.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_toggle.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';
import '../bloc/room_state.dart';
import '../widgets/whole_room_panel.dart';

/// A room on a phone (spec §10.3).
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  /// `WizCtl_Mobile.dc.html` `roomDialSize=132`.
  static const double dialSize = 132;

  @override
  Widget build(BuildContext context) {
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return BlocListener<RoomBloc, RoomState>(
      // A room deleted while its screen is open — or an id from a deep link
      // that no longer names one — leaves nothing to draw, and the blank body
      // below carries no bar and so no Back. The screen leaves instead of
      // stranding the reader in it. `gone` is one-shot, but the guard keeps
      // the listener from firing twice if that ever changes.
      listenWhen: (prev, cur) =>
          prev.status != RoomStatus.gone && cur.status == RoomStatus.gone,
      listener: (context, state) => popOr(context, AppRoutes.rooms),
      child: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          var bloc = context.read<RoomBloc>();
          var room = state.room;
          // Blank while the first read is in flight; `gone` is on its way out
          // through the listener above and shows this for the one frame it
          // takes.
          if (state.status != RoomStatus.ready || room == null) {
            return const ScreenScroll(children: []);
          }
          return ScreenScroll(
            // Awaited, not fired and forgotten: the filament has to stay up for
            // as long as the read takes, and an event added to a bloc is over
            // on the next microtask.
            onRefresh: () {
              var done = Completer<void>();
              bloc.add(RoomRefreshRequested(done: done));
              return done.future;
            },
            children: [
              WizTopBar(
                title: room.name,
                subtitle: plural(state.lights.length, 'light'),
                leading: WizIconKey(
                  icon: WizIcons.chevronLeft,
                  semanticsLabel: Strings.back,
                  onPressed: () => popOr(context, AppRoutes.rooms),
                ),
                trailing: WizToggle(
                  value: state.anyOn,
                  onChanged: (on) => bloc.add(RoomPowerToggled(on)),
                  semanticsLabel: Strings.roomPower(room.name),
                ),
              ),
              if (offNetwork) const OffNetworkBanner(),
              if (state.isEmpty)
                WizEmptyState(
                  icon: WizIcons.lightbulb,
                  title: Strings.noLightsInRoom,
                  body: Strings.discoverThenPlace,
                  action: WizButton(
                    label: Strings.discoverLights,
                    variant: WizButtonVariant.primary,
                    onPressed: () => context.go(AppRoutes.discover),
                  ),
                )
              else
                const WholeRoomPanel(dialSize: dialSize),
              for (var (i, live) in state.lights.indexed)
                RiseIn(
                  index: i,
                  child: LightCard(
                    name: live.light.name,
                    meta: live.state.reachable
                        ? ModeSummarizer.summarize([live]).name
                        : live.light.ip,
                    icon: WizIcons.byName(live.light.fixture.iconName)!,
                    on: live.state.isOn,
                    unreachable: !live.state.reachable,
                    brightness: live.state.brightness.toDouble(),
                    // Spec §10.3: a plug shows no rail, and
                    // `WizBrightnessControl.none` draws neither rail nor meter.
                    control: live.light.bulbClass == BulbClass.socket
                        ? WizBrightnessControl.none
                        : WizBrightnessControl.rail,
                    onToggle: (on) =>
                        bloc.add(RoomLightPowerToggled(live.light.id, on)),
                    onBrightness: (v) => bloc.add(
                      RoomLightBrightnessChanged(live.light.id, v.round()),
                    ),
                    onBrightnessEnd: (v) => bloc.add(
                      RoomLightBrightnessChanged(live.light.id, v.round()),
                    ),
                    onTap: () => context.push(AppRoutes.light(live.light.id)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
