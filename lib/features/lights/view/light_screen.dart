import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/navigation.dart';
import '../../../app/widgets/leave_when_gone.dart';
import '../../../app/widgets/off_network_banner.dart';
import '../../../app/widgets/screen_scroll.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_icon_key.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_power_key.dart';
import '../../../core/widgets/wiz_status_banner.dart';
import '../../../core/widgets/wiz_top_bar.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';
import '../widgets/device_panel.dart';
import '../widgets/light_dials_panel.dart';
import '../widgets/light_hero.dart';
import '../widgets/light_modes_panel.dart';
import '../widgets/light_stat_tiles.dart';

/// A light on a phone (spec §10.4).
class LightScreen extends StatelessWidget {
  const LightScreen({super.key});

  /// Same dials as the room (`WizCtl_Mobile.dc.html` line 302).
  static const double dialSize = 132;

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var offNetwork = context.select<NetworkCubit, bool>(
      (c) => c.state.offNetwork,
    );
    return LeaveWhenGone<LightBloc, LightState>(
      isGone: (state) => state.status == LightStatus.gone,
      parent: (state) => lightParent(state.light?.roomId),
      // A forget announces itself with a `LightForgottenNotice` on the very
      // state that carries `gone`, and `LightNoticeListener` is the one that
      // toasts and leaves for it (P83).
      standDown: (state) => state.notice is LightForgottenNotice,
      child: BlocBuilder<LightBloc, LightState>(
        builder: (context, state) {
          var bloc = context.read<LightBloc>();
          var light = state.light;
          // Blank while the first read is in flight; `gone` is on its way out
          // through [LeaveWhenGone] above and shows this for the one frame
          // it takes.
          if (state.status != LightStatus.ready || light == null) {
            return const ScreenScroll(children: []);
          }
          var reachable = state.live.reachable;
          return ScreenScroll(
            children: [
              WizTopBar(
                title: light.name,
                subtitle: Strings.roomAndClass(
                  state.room?.name ?? '',
                  light.className,
                ),
                leading: WizIconKey(
                  icon: WizIcons.chevronLeft,
                  semanticsLabel: Strings.back,
                  onPressed: () => popOr(context, lightParent(light.roomId)),
                ),
                trailing: WizBadge(
                  label: reachable ? Strings.live : Strings.noReply,
                  tone: reachable ? WizBadgeTone.online : WizBadgeTone.danger,
                  dot: true,
                ),
              ),
              if (offNetwork) const OffNetworkBanner(),
              const LightHero(),
              Center(
                child: WizPowerKey(
                  on: state.live.isOn,
                  onChanged: (on) => bloc.add(LightPowerChanged(on)),
                ),
              ),
              if (!reachable)
                WizStatusBanner(
                  status: WizStatus.error,
                  title: Strings.noReplyFromLight,
                  body: Strings.mayBeOffAtWall,
                  action: WizButton(
                    label: Strings.retry,
                    variant: WizButtonVariant.ghost,
                    size: WizButtonSize.sm,
                    onPressed: () => bloc.add(const LightRetryRequested()),
                  ),
                ),
              const LightStatTiles(),
              if (state.isSocket)
                WizPanel(
                  variant: WizPanelVariant.inset,
                  child: Text(
                    Strings.plugOnlyNote,
                    style: wiz.typography.bodySm.copyWith(
                      color: wiz.colors.textTertiary,
                    ),
                  ),
                )
              else ...[
                const LightDialsPanel(dialSize: dialSize),
                const LightModesPanel(),
              ],
              const DevicePanel(),
            ],
          );
        },
      ),
    );
  }
}
