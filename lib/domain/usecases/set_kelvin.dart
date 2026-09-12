import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import '../services/live_state_mapper.dart';
import 'target_command.dart';

class SetKelvin extends TargetCommand {
  const SetKelvin({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<void> call(ModeTarget target, int kelvin) {
    var k = LiveStateMapper.snapKelvin(kelvin);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.kelvin(light.bulbClass),
      signal: (_, _) => ControlSignal(temperature: k),
      patch: (s) => s.copyWith(kelvin: k, active: ActiveChannel.white),
      throttleKey: 'kelvin:${target.key}',
    );
  }
}
