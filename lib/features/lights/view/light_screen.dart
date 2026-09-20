import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/network_cubit.dart';
import '../../../app/navigation.dart';
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
    return _LeaveWhenGone(
      child: BlocBuilder<LightBloc, LightState>(
        builder: (context, state) {
          var bloc = context.read<LightBloc>();
          var light = state.light;
          // Blank while the first read is in flight; `gone` is on its way out
          // through [_LeaveWhenGone] above and shows this for the one frame
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

/// Leaves the screen when its light has gone (P63), exactly once.
///
/// A `BlocListener` on its own is not enough. A stale route, or a deep link to
/// an id that no longer names a light, reaches [LightStatus.gone] before this
/// widget is mounted, and a listener never fires for the state a bloc is
/// already in — the reader would be stranded in the blank body, which has no
/// bar and so no Back. The state on hand is therefore checked once after the
/// first frame, which is the earliest point a route may be replaced.
///
/// A forget announces itself with a [LightForgottenNotice] on the very state
/// that carries `gone`, and `LightNoticeListener` is the one that toasts and
/// leaves for it. This widget stands down for that state — but still takes
/// [_LeaveWhenGoneState._left], so that between the two of them a forget
/// navigates once even if another `gone` were ever to follow.
class _LeaveWhenGone extends StatefulWidget {
  final Widget child;
  const _LeaveWhenGone({required this.child});

  @override
  State<_LeaveWhenGone> createState() => _LeaveWhenGoneState();
}

class _LeaveWhenGoneState extends State<_LeaveWhenGone> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onState(context.read<LightBloc>().state);
    });
  }

  void _onState(LightState state) {
    if (_left || state.status != LightStatus.gone) return;
    _left = true;
    if (state.notice is LightForgottenNotice) return;
    popOr(context, lightParent(state.light?.roomId));
  }

  @override
  Widget build(BuildContext context) => BlocListener<LightBloc, LightState>(
    listener: (context, state) => _onState(state),
    child: widget.child,
  );
}
