import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/blocs/inspector_cubit.dart';
import '../../../core/icons/wiz_icon_data.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/motion/rise_in.dart';
import '../../../core/widgets/light_card.dart';
import '../../../domain/services/mode_summarizer.dart';

/// The desktop grid's cards (spec §10.9): as many columns of at least
/// [cardMin] as the window affords, brightness as a read-only meter rather
/// than a rail, and a click that selects the light into the inspector and
/// rings its card.
///
/// A click selects; the card's own switch writes. Both are live at once
/// because the switch is its own hit target inside the card, so selecting a
/// light never changes it.
class LightGrid extends StatelessWidget {
  final List<LiveLight> lights;

  /// One card's switch: the light and the position it was moved to.
  final void Function(String lightId, bool on) onToggle;

  const LightGrid({super.key, required this.lights, required this.onToggle});

  /// `WizCtl_Desktop.dc.html` line 214: `minmax(340px,1fr)` and `gap:14px`.
  static const double cardMin = 340;
  static const double gap = 14;

  @override
  Widget build(BuildContext context) {
    var selected = context.watch<InspectorCubit>().state;
    var inspector = context.read<InspectorCubit>();
    return WizGrid(
      minTile: cardMin,
      gap: gap,
      children: [
        for (var (i, live) in lights.indexed)
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
              control: WizBrightnessControl.meter,
              selected: live.light.id == selected,
              onToggle: (on) => onToggle(live.light.id, on),
              onTap: () => inspector.select(live.light.id),
            ),
          ),
      ],
    );
  }
}
