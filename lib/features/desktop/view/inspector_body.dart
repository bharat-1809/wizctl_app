import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../app/shell_deps.dart';
import '../../../app/widgets/dual_dials.dart';
import '../../../app/widgets/mode_art.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/mode_row.dart';
import '../../../core/widgets/wiz_badge.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../../core/widgets/wiz_power_key.dart';
import '../../../core/widgets/wiz_stat_tile.dart';
import '../../../domain/entities/entities.dart';
import '../../lights/bloc/light_bloc.dart';
import '../../lights/bloc/light_event.dart';
import '../../lights/bloc/light_state.dart';
import '../../lights/widgets/forget_light_sheet.dart';
import '../../lights/widgets/light_notice_listener.dart';
import '../../lights/widgets/rename_light_sheet.dart';
import '../../modes/modes_bloc_factory.dart';
import '../../modes/view/modes_sheet.dart';
import '../widgets/inspector_facts.dart';
import '../widgets/inspector_hero.dart';
import 'grid_screen.dart';
import 'inspector_panel.dart';

/// The selected light's controls, over a `LightBloc` of its own (spec §10.9).
/// Shared by the inspector column and the medium-width dialog, so the two
/// readings cannot drift apart.
///
/// The bloc is created here rather than handed in, and the callers key this
/// widget on [lightId]: a new selection is a new element, which closes the old
/// bloc — with its poll scope and its repository watches — and subscribes one
/// for the light now on show.
///
/// When the light goes, the selection goes with it. That covers the forget
/// below, a light removed somewhere else, and an id that names nothing at all —
/// the cubit is cleared only on a home switch (Task 20), so a stale selection
/// is reachable, and clearing it here is what puts the column back to its "No
/// light selected" state instead of leaving it blank.
class InspectorBody extends StatelessWidget {
  final String lightId;

  const InspectorBody({super.key, required this.lightId});

  @override
  Widget build(BuildContext context) {
    var deps = context.read<ShellDeps>();
    return BlocProvider(
      create: (_) => LightBloc(
        lightId: lightId,
        lights: deps.lights,
        rooms: deps.rooms,
        store: deps.store,
        setPower: deps.setPower,
        setBrightness: deps.setBrightness,
        setKelvin: deps.setKelvin,
        setSpeed: deps.setSpeed,
        setFixture: deps.setFixture,
        renameLight: deps.renameLight,
        forgetLight: deps.forgetLight,
        sync: deps.sync,
      )..add(const LightSubscribed()),
      child: BlocListener<LightBloc, LightState>(
        listenWhen: (a, b) =>
            a.status != b.status && b.status == LightStatus.gone,
        listener: (context, _) => context.read<InspectorCubit>().clear(),
        // `navigate: false` (P27): the notice's toast is wanted, its leave is
        // not. There is nothing to pop here, and the location is already the
        // room the light was in — or All lights.
        child: const LightNoticeListener(
          navigate: false,
          child: _InspectorContent(),
        ),
      ),
    );
  }
}

/// The column's body: the name and address, the live badge, the stage, the
/// dials, the power key beside two tiles, the mode row, the device facts and
/// the two keys (`WizCtl_Desktop.dc.html` lines 349-411).
class _InspectorContent extends StatelessWidget {
  const _InspectorContent();

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        // Blank while the first read is in flight. A light that has gone leaves
        // through the listener above, which clears the selection and so takes
        // this whole subtree with it.
        if (light == null) return const SizedBox.shrink();
        var reachable = state.live.reachable;
        var sceneName = state.sceneName;
        // A plug has one fact worth a tile, a light showing a scene has its
        // name, and everything else reads out its brightness.
        var second = state.isSocket
            ? WizStatTile(
                icon: WizIcons.power,
                label: Strings.power,
                value: state.live.isOn ? Strings.on : Strings.off,
              )
            : sceneName != null
            ? WizStatTile(
                icon: WizIcons.sparkles,
                label: Strings.scene,
                value: sceneName,
                accent: state.live.isOn,
              )
            : WizStatTile(
                icon: WizIcons.gauge,
                label: Strings.brightness,
                value: '${state.live.brightness}',
                unit: '%',
                accent: state.live.isOn,
              );
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          light.name,
                          style: wiz.typography.title.copyWith(
                            fontSize: InspectorPanel.nameSize,
                            color: wiz.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          Strings.ipAndClass(light.ip, light.className),
                          style: wiz.typography.mono.copyWith(
                            color: wiz.colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: wiz.space.s5),
                  WizBadge(
                    label: reachable ? Strings.live : Strings.noReply,
                    tone: reachable ? WizBadgeTone.online : WizBadgeTone.danger,
                    dot: true,
                  ),
                ],
              ),
              SizedBox(height: wiz.space.s6),
              const InspectorHero(),
              if (!state.isSocket) ...[
                SizedBox(height: wiz.space.s6),
                DualDials(
                  brightness: state.live.brightness,
                  kelvin: state.canKelvin ? state.live.kelvin : null,
                  onBrightness: (v) => bloc.add(LightBrightnessChanged(v)),
                  onKelvin: (k) => bloc.add(LightKelvinChanged(k)),
                  // The desktop's knobs, the same 140 the grid draws.
                  preferredSize: GridScreen.dialSize,
                  note: state.canKelvin ? null : Strings.dimsNoWhite,
                ),
              ],
              SizedBox(height: wiz.space.s6),
              Row(
                children: [
                  WizPowerKey(
                    on: state.live.isOn,
                    size: WizPowerKeySize.md,
                    onChanged: (on) => bloc.add(LightPowerChanged(on)),
                  ),
                  SizedBox(width: wiz.space.s5),
                  Expanded(
                    child: Column(
                      children: [
                        WizStatTile(
                          icon: WizIcons.lightbulb,
                          label: Strings.classTile,
                          value: light.className,
                        ),
                        SizedBox(height: wiz.space.s4),
                        second,
                      ],
                    ),
                  ),
                ],
              ),
              if (state.isSocket) ...[
                SizedBox(height: wiz.space.s6),
                WizPanel(
                  variant: WizPanelVariant.inset,
                  child: Text(
                    Strings.plugOnlyNote,
                    style: wiz.typography.bodySm.copyWith(
                      color: wiz.colors.textTertiary,
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(height: wiz.space.s6),
                ModeRow(
                  art: modeArtOf(state.summary.art),
                  name: state.summary.name,
                  onTap: () => showModesSheet(
                    context,
                    target: LightTarget(bloc.lightId),
                    blocFor: context.read<ModesBlocFactory>(),
                  ),
                ),
              ],
              SizedBox(height: wiz.space.s6),
              const InspectorFacts(),
              SizedBox(height: wiz.space.s5),
              Row(
                children: [
                  Expanded(
                    child: WizButton(
                      label: Strings.rename,
                      variant: WizButtonVariant.ghost,
                      size: WizButtonSize.sm,
                      icon: WizIcons.pencil,
                      fullWidth: true,
                      onPressed: () async {
                        var name = await showRenameLightSheet(
                          context,
                          name: light.name,
                        );
                        if (name != null) bloc.add(LightRenamed(name));
                      },
                    ),
                  ),
                  SizedBox(width: wiz.space.s4),
                  Expanded(
                    child: WizButton(
                      label: Strings.forget,
                      variant: WizButtonVariant.danger,
                      size: WizButtonSize.sm,
                      icon: WizIcons.trash,
                      fullWidth: true,
                      onPressed: () async {
                        var sure = await showForgetLightSheet(
                          context,
                          name: light.name,
                        );
                        if (sure) bloc.add(const LightForgotten());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
