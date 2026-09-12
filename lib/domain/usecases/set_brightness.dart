import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

class SetBrightness extends TargetCommand {
  const SetBrightness({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<void> call(ModeTarget target, int value) {
    var v = value.clamp(minBrightness, maxBrightness);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.brightness(light.bulbClass),
      signal: (_, _) => ControlSignal(state: true, dimming: v),
      patch: (s) => s.copyWith(brightness: v, isOn: true),
      throttleKey: 'brightness:${target.key}',
    );
  }
}
