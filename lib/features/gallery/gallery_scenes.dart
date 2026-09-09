import 'package:flutter/material.dart';

import '../../core/copy/strings.dart';
import '../../core/layout/wiz_grid.dart';
import '../../core/theme/wiz_theme.dart';
import '../../core/widgets/mode_row.dart';
import '../../core/widgets/scene_gradients.dart';
import '../../core/widgets/wiz_button.dart';
import '../../core/widgets/wiz_scene_tile.dart';
import '../../core/widgets/wiz_segmented_control.dart';
import '../../core/widgets/wiz_sheet.dart';
import 'gallery_section.dart';

/// Which family of scenes the grid is showing.
enum GallerySceneTab { colour, static, dynamic }

/// The scene picker: segmented control, the procedural scene art in a grid,
/// and the light-mode row that opens the kit's one modal surface.
class GalleryScenes extends StatefulWidget {
  const GalleryScenes({super.key});

  /// Tile geometry from the phone scene grid
  /// (`design/reference/WizCtl_Mobile.dc.html`, spec §11.2 "20 tab" label).
  static const double tileMinWidth = 100;
  static const double tileHeight = 82;
  static const double tileLabelSize = 14;

  /// How many tiles the gallery shows: enough to fill two rows on a phone
  /// without turning the section into the whole screen.
  static const int tileCount = 6;

  /// Cozy — the warm static scene the prototype opens on.
  static const int initialScene = 6;

  @override
  State<GalleryScenes> createState() => _GalleryScenesState();
}

class _GalleryScenesState extends State<GalleryScenes> {
  GallerySceneTab _tab = GallerySceneTab.colour;
  int _scene = GalleryScenes.initialScene;

  List<SceneGradient> get _scenes =>
      _tab == GallerySceneTab.dynamic ? dynamicScenes : staticScenes;

  void _openSheet() {
    var wiz = context.wiz;
    showWizSheet<void>(
      context,
      title: '${Strings.lightMode} · Living Room',
      builder: (_) => Text(
        Strings.dynamicPip,
        style: wiz.typography.body.copyWith(color: wiz.colors.textTertiary),
      ),
      footer: [
        Builder(
          builder: (sheetContext) => WizButton(
            label: Strings.close,
            variant: WizButtonVariant.ghost,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var wiz = context.wiz;
    var space = wiz.space;
    return GallerySection(
      title: 'Scenes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WizSegmentedControl<GallerySceneTab>(
            segments: const [
              WizSegment(value: GallerySceneTab.colour, label: Strings.colour),
              WizSegment(value: GallerySceneTab.static, label: 'Static'),
              WizSegment(value: GallerySceneTab.dynamic, label: 'Dynamic'),
            ],
            value: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
          SizedBox(height: space.s5),
          WizGrid(
            minTile: GalleryScenes.tileMinWidth,
            // The prototype's scene grid gaps by 9: one step past `s4`.
            gap: space.s4 + space.s1 / 2,
            children: [
              for (var s in _scenes.take(GalleryScenes.tileCount))
                WizSceneTile(
                  sceneId: s.id,
                  selected: s.id == _scene,
                  height: GalleryScenes.tileHeight,
                  radius: space.r3,
                  labelSize: GalleryScenes.tileLabelSize,
                  onTap: () => setState(() => _scene = s.id),
                ),
            ],
          ),
          SizedBox(height: space.s5),
          ModeRow(
            art: SceneModeArt(_scene),
            name: sceneGradients[_scene]!.name,
            onTap: _openSheet,
          ),
        ],
      ),
    );
  }
}
