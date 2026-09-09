import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

/// Scenes reach everything but plugs. Speed travels with dynamic scenes only.
///
/// An id the library has no scene for sends nothing and returns 0 — the same
/// "nothing was eligible" signal the caller already handles — rather than
/// letting ControlSignal throw once dispatch is under way.
class ApplyScene extends TargetCommand {
  const ApplyScene({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<int> call(ModeTarget target, int sceneId, {int? speed}) {
    if (WizScene.fromId(sceneId) == null) return Future.value(0);
    var isDynamic = CapabilityRules.isDynamicScene(sceneId);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.scenes(light.bulbClass),
      signal: (_, state) => ControlSignal(
        state: true,
        sceneId: sceneId,
        speed: isDynamic
            ? (speed ?? state.speed).clamp(minSpeed, maxSpeed)
            : null,
      ),
      patch: (s) => s.copyWith(
        sceneId: sceneId,
        active: ActiveChannel.scene,
        isOn: true,
        speed: isDynamic
            ? (speed ?? s.speed).clamp(minSpeed, maxSpeed)
            : s.speed,
      ),
    );
  }
}
