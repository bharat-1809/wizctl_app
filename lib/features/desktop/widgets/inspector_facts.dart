import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/field_label.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../../lights/bloc/light_bloc.dart';
import '../../lights/bloc/light_state.dart';

/// The flat device panel (spec §10.9): DEVICE, the MAC, "udp 38899 · fw".
///
/// Fewer facts than the phone's `DevicePanel`: the address and the class are
/// already in the inspector's own header and its CLASS tile, and the column has
/// no room to say either twice.
class InspectorFacts extends StatelessWidget {
  const InspectorFacts({super.key});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) {
        var light = state.light;
        if (light == null) return const SizedBox.shrink();
        var mono = wiz.typography.mono.copyWith(color: wiz.colors.textTertiary);
        return WizPanel(
          variant: WizPanelVariant.flat,
          // `WizCtl_Desktop.dc.html` line 401, `padding: 12px 14px`.
          padding: EdgeInsets.symmetric(
            horizontal: wiz.space.s5 + wiz.space.s1,
            vertical: wiz.space.s5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel(Strings.device),
              SizedBox(height: wiz.space.s3),
              Text(light.mac, style: mono),
              Text(Strings.fw(light.fwVersion), style: mono),
            ],
          ),
        );
      },
    );
  }
}
