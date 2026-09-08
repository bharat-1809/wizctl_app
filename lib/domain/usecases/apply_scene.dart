import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

/// Scenes reach everything but plugs. Speed travels with dynamic scenes only.
class ApplyScene extends TargetCommand {
  const ApplyScene({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<int> call(ModeTarget target, int sceneId, {int? speed}) {
    var dynamic = CapabilityRules.isDynamicScene(sceneId);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.scenes(light.bulbClass),
      signal: (_, state) => ControlSignal(
        state: true,
        sceneId: sceneId,
        speed: dynamic
            ? (speed ?? state.speed).clamp(minSpeed, maxSpeed)
            : null,
      ),
      patch: (s) => s.copyWith(
        sceneId: sceneId,
        active: ActiveChannel.scene,
        isOn: true,
        speed: dynamic ? (speed ?? s.speed).clamp(minSpeed, maxSpeed) : s.speed,
      ),
    );
  }
}
