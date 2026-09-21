import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_button.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';
import 'fixture_sheet.dart';
import 'forget_light_sheet.dart';
import 'rename_light_sheet.dart';

/// "DEVICE": address, MAC, class, signal; then Show it as, Rename and
/// Forget (spec §10.4).
///
/// The panel draws nothing at all without a light, which is what keeps Forget
/// out of reach until the bloc is ready: a forget before the first read has
/// no name to put in its notice, and the bloc treats it as a no-op (P64).
class DevicePanel extends StatelessWidget {
  const DevicePanel({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var rssi = state.live.rssi;
        var facts = <(String, String)>[
          (Strings.address, Strings.udpAddress(light.ip)),
          (Strings.mac, light.mac),
          (Strings.classTile, light.className),
          (
            Strings.signal,
            state.live.reachable && rssi != null
                ? Strings.dbm(rssi)
                : Strings.noReplyLower,
          ),
        ];
        return WizPanel(
          variant: WizPanelVariant.flat,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(Strings.device),
              SizedBox(height: wiz.space.s4),
              for (var (label, value) in facts)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: wiz.space.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: wiz.typography.bodySm.copyWith(
                            color: wiz.colors.textTertiary,
                          ),
                        ),
                      ),
                      Text(
                        value,
                        style: wiz.typography.mono.copyWith(
                          color: wiz.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: wiz.space.s5),
              WizButton(
                label: Strings.showItAs,
                fullWidth: true,
                onPressed: () async {
                  var picked = await showFixtureSheet(
                    context,
                    current: light.fixture,
                  );
                  if (picked != null) bloc.add(LightFixtureChanged(picked));
                },
              ),
              SizedBox(height: wiz.space.s4),
              Row(
                children: [
                  Expanded(
                    child: WizButton(
                      label: Strings.rename,
                      variant: WizButtonVariant.ghost,
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
