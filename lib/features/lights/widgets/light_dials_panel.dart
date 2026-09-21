import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/widgets/dual_dials.dart';
import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_panel.dart';
import '../bloc/light_bloc.dart';
import '../bloc/light_event.dart';
import '../bloc/light_state.dart';

/// Brightness and, when the bulb has a white channel, colour temp; the
/// "dims but has no white channel" note when it does not (spec §10.4).
class LightDialsPanel extends StatelessWidget {
  final double dialSize;
  const LightDialsPanel({super.key, required this.dialSize});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightBloc>();
    return BlocBuilder<LightBloc, LightState>(
      builder: (context, state) => WizPanel(
        variant: WizPanelVariant.inset,
        padding: EdgeInsets.symmetric(
          horizontal: wiz.space.panelPad,
          vertical: wiz.space.panelPadLg,
        ),
        child: DualDials(
          brightness: state.live.brightness,
          kelvin: state.canKelvin ? state.live.kelvin : null,
          onBrightness: (v) => bloc.add(LightBrightnessChanged(v)),
          onKelvin: (k) => bloc.add(LightKelvinChanged(k)),
          preferredSize: dialSize,
          note: state.canKelvin ? null : Strings.dimsNoWhite,
        ),
      ),
    );
  }
}
