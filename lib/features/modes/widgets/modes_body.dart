import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/copy/strings.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/wiz_segmented_control.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import 'colour_tab.dart';
import 'modes_layout.dart';
import 'scenes_tab.dart';

/// Segmented control Colour / Static / Dynamic over the matching tab; the
/// same body inside the sheet, the dialog and the Scenes tab (spec §10.5).
class ModesBody extends StatelessWidget {
  final ModesLayout layout;
  const ModesBody({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightModesBloc>();
    var tab = context.select<LightModesBloc, ModesTab>((b) => b.state.tab);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        WizSegmentedControl<ModesTab>(
          segments: const [
            WizSegment(value: ModesTab.colour, label: Strings.colour),
            WizSegment(value: ModesTab.staticScenes, label: Strings.staticTab),
            WizSegment(
              value: ModesTab.dynamicScenes,
              label: Strings.dynamicTab,
            ),
          ],
          value: tab,
          onChanged: (t) => bloc.add(ModesTabChanged(t)),
        ),
        SizedBox(height: wiz.space.s6),
        switch (tab) {
          ModesTab.colour => ColourTab(layout: layout),
          ModesTab.staticScenes => ScenesTab(layout: layout, dynamic: false),
          ModesTab.dynamicScenes => ScenesTab(layout: layout, dynamic: true),
        },
      ],
    );
  }
}
