import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

class SetSpeed extends TargetCommand {
  const SetSpeed({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<void> call(ModeTarget target, int speed) {
    var v = speed.clamp(minSpeed, maxSpeed);
    return dispatch(
      target,
      eligible: (_, state) => CapabilityRules.speed(state),
      signal: (_, _) => ControlSignal(speed: v),
      patch: (s) => s.copyWith(speed: v),
      throttleKey: 'speed:${target.key}',
    );
  }
}
