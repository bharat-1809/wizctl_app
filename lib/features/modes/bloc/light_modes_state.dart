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
///
/// A view names the whole home by switching on [target] being a
/// `WholeHomeTarget`, not on a null [targetName]: a room or light deleted
/// under the sheet yields a null name too.
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

  /// Whether any target light has a tunable white — the capability, for a view
  /// that chooses to gate on it. The modes body does not: it draws all three
  /// segments and answers a tap that reaches nothing with [NoWhiteNotice], so
  /// the tiles never move under the finger (Task 9).
  bool get hasWhite =>
      lights.any((l) => CapabilityRules.kelvin(l.light.bulbClass));

  /// Whether any target light takes scenes (a plug does not) — the capability,
  /// read the same way as [hasWhite]: the scene tabs are always there and an
  /// ineligible tap becomes [NoSceneNotice].
  bool get hasScenes =>
      lights.any((l) => CapabilityRules.scenes(l.light.bulbClass));

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
  /// which is what a bulb that has never been told a speed is running at. A
  /// plug is skipped: `SetSpeed` never writes to one, so the speed it happens
  /// to hold would be a value no bulb in the target is actually running at.
  int get speed {
    var reachable = ModeSummarizer.sceneable(lights);
    return reachable.isEmpty ? defaultSpeed : reachable.first.state.speed;
  }

  /// The scene every scene-capable target light is on, or null. A plug is
  /// skipped for the reason [speedVisible] skips it: `ApplyScene` never writes
  /// to one, so it would veto the selection of every room that has one.
  int? get currentScene {
    var reachable = ModeSummarizer.sceneable(lights);
    if (reachable.isEmpty) return null;
    var first = reachable.first.state;
    if (first.active != ActiveChannel.scene) return null;
    return ModeSummarizer.sceneSelected(reachable, first.sceneId)
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
