import 'package:equatable/equatable.dart';

import 'rgb.dart';

sealed class ModeArt extends Equatable {
  const ModeArt();
}

final class SceneArt extends ModeArt {
  final int sceneId;
  const SceneArt(this.sceneId);

  @override
  List<Object?> get props => [sceneId];
}

final class SolidArt extends ModeArt {
  final Rgb rgb;
  const SolidArt(this.rgb);

  @override
  List<Object?> get props => [rgb];
}

final class FlatArt extends ModeArt {
  const FlatArt();

  @override
  List<Object?> get props => const [];
}

/// What the Light mode row reads for a light, a room or the home.
class ModeSummary extends Equatable {
  final String name;
  final ModeArt art;
  final bool isDynamicScene;
  final bool isStaticScene;
  final int? sceneId;

  const ModeSummary({
    required this.name,
    required this.art,
    this.isDynamicScene = false,
    this.isStaticScene = false,
    this.sceneId,
  });

  static const ModeSummary nothingSet = ModeSummary(
    name: 'Nothing set',
    art: FlatArt(),
  );
  static const ModeSummary mixed = ModeSummary(name: 'Mixed', art: FlatArt());

  @override
  List<Object?> get props => [
    name,
    art,
    isDynamicScene,
    isStaticScene,
    sceneId,
  ];
}
