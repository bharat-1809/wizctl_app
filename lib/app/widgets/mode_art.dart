import 'package:flutter/material.dart';

import '../../core/widgets/mode_row.dart';
import '../../domain/entities/entities.dart';

/// The domain's mode art in the kit's terms: a scene keeps its id, a solid
/// becomes a colour, flat stays flat.
WizModeArt modeArtOf(ModeArt art) => switch (art) {
  SceneArt(:var sceneId) => SceneModeArt(sceneId),
  SolidArt(:var rgb) => SolidModeArt(Color.fromARGB(255, rgb.r, rgb.g, rgb.b)),
  FlatArt() => const FlatModeArt(),
};
