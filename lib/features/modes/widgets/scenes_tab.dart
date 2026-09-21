import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wizctl/wizctl.dart';

import '../../../core/copy/strings.dart';
import '../../../core/layout/wiz_grid.dart';
import '../../../core/theme/wiz_theme.dart';
import '../../../core/widgets/scene_gradients.dart';
import '../../../core/widgets/wiz_scene_tile.dart';
import '../../../core/widgets/wiz_slider.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../bloc/light_modes_bloc.dart';
import '../bloc/light_modes_event.dart';
import '../bloc/light_modes_state.dart';
import 'modes_layout.dart';

/// The Static and Dynamic tabs: the speed rail when the whole target is on
/// one dynamic scene, the scene grid, the note (spec §10.5).
class ScenesTab extends StatelessWidget {
  final ModesLayout layout;
  final bool dynamic;
  const ScenesTab({super.key, required this.layout, required this.dynamic});

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var bloc = context.read<LightModesBloc>();
    var scenes = dynamic ? dynamicScenes : staticScenes;
    return BlocBuilder<LightModesBloc, LightModesState>(
      builder: (context, state) {
        var current = state.currentScene;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dynamic && state.speedVisible && current != null) ...[
              WizSlider(
                value: state.speed.toDouble(),
                min: minSpeed.toDouble(),
                max: maxSpeed.toDouble(),
                fill: WizSliderFill.speed,
                label: Strings.speedFor(ModeSummarizer.sceneName(current)),
                readout: '${state.speed}',
                onChanged: (v) => bloc.add(SpeedChanged(v.round())),
                onChangeEnd: (v) => bloc.add(SpeedChanged(v.round())),
              ),
              SizedBox(height: wiz.space.s6),
            ],
            WizGrid(
              minTile: layout.sceneMinTile,
              gap: wiz.space.s5,
              mainAxisExtent: layout.sceneHeight,
              childAspectRatio: layout.sceneHeight == null ? 1 : null,
              children: [
                for (var scene in scenes)
                  WizSceneTile(
                    sceneId: scene.id,
                    selected: ModeSummarizer.sceneSelected(
                      state.lights,
                      scene.id,
                    ),
                    variant: layout.tileVariant,
                    labelSize: layout.labelSize,
                    height: layout.sceneHeight,
                    onTap: () => bloc.add(ScenePicked(scene.id)),
                  ),
              ],
            ),
            SizedBox(height: wiz.space.s5),
            Text(
              dynamic ? Strings.dynamicNote : Strings.staticNote,
              style: wiz.typography.bodySm.copyWith(
                color: wiz.colors.textTertiary,
              ),
            ),
          ],
        );
      },
    );
  }
}
