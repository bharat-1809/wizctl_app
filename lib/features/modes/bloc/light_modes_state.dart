import 'package:equatable/equatable.dart';
import 'package:wizctl/wizctl.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/capability_rules.dart';
import '../../../domain/services/mode_summarizer.dart';

enum ModesStatus { loading, ready }

/// The segmented control (spec §10.5).
enum ModesTab { colour, staticScenes, dynamicScenes }

sealed class ModesNotice extends Equatable {
  const ModesNotice();
  @override
  List<Object?> get props => const [];
}

/// "`<Scene>` applied" / "to the whole home" · "to `<room>`" · "to `<light>`".
final class SceneAppliedNotice extends ModesNotice {
  final String sceneName;
  final ModeTarget target;
  final String? targetName;
  const SceneAppliedNotice(this.sceneName, this.target, this.targetName);
  @override
  List<Object?> get props => [sceneName, target, targetName];
}

final class NoColourNotice extends ModesNotice {
  const NoColourNotice();
}

final class NoWhiteNotice extends ModesNotice {
  const NoWhiteNotice();
}

final class NoSceneNotice extends ModesNotice {
  const NoSceneNotice();
}

class LightModesState extends Equatable {
  final ModesStatus status;
  final ModeTarget target;

  /// The room's or light's name; null for the whole home, which the view
  /// names itself.
  final String? targetName;
  final ModesTab tab;
  final List<LiveLight> lights;
  final ModesNotice? notice;

  const LightModesState({
    required this.status,
    required this.target,
    required this.targetName,
    required this.tab,
    required this.lights,
    this.notice,
  });

  /// The wheel shows only when the target holds a colour bulb (spec §10.5).
  bool get hasWheel =>
      lights.any((l) => CapabilityRules.colour(l.light.bulbClass));

  /// Where the puck sits: the first colour bulb's last colour.
  Rgb get wheelRgb {
    for (var l in lights) {
      if (CapabilityRules.colour(l.light.bulbClass)) return l.state.rgb;
    }
    return Rgb.warm;
  }

  /// The speed rail shows only when the whole target is on one dynamic
  /// scene (spec §5.3).
  bool get speedVisible => ModeSummarizer.allOnOneDynamicScene(lights);

  /// Before any light is known the rail reads the library's own default,
  /// which is what a bulb that has never been told a speed is running at.
  int get speed => lights.isEmpty ? defaultSpeed : lights.first.state.speed;

  /// The scene every target light is on, or null.
  int? get currentScene {
    if (lights.isEmpty) return null;
    var first = lights.first.state;
    if (first.active != ActiveChannel.scene) return null;
    return ModeSummarizer.sceneSelected(lights, first.sceneId)
        ? first.sceneId
        : null;
  }

  bool get isEmpty => lights.isEmpty;

  LightModesState copyWith({
    ModesStatus? status,
    ModeTarget? target,
    String? targetName,
    bool clearTargetName = false,
    ModesTab? tab,
    List<LiveLight>? lights,
    ModesNotice? notice,
    bool clearNotice = false,
  }) => LightModesState(
    status: status ?? this.status,
    target: target ?? this.target,
    targetName: clearTargetName ? null : targetName ?? this.targetName,
    tab: tab ?? this.tab,
    lights: lights ?? this.lights,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, target, targetName, tab, lights, notice];
}
