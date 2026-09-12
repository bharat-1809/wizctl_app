import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import '../services/live_state_mapper.dart';
import 'target_command.dart';

/// Whites write only to bulbs with a white channel. Zero means "No white
/// channel here".
class ApplyWhite extends TargetCommand {
  const ApplyWhite({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<int> call(ModeTarget target, int kelvin) {
    var k = LiveStateMapper.snapKelvin(kelvin);
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.kelvin(light.bulbClass),
      signal: (_, _) => ControlSignal(state: true, temperature: k),
      patch: (s) =>
          s.copyWith(kelvin: k, active: ActiveChannel.white, isOn: true),
    );
  }
}
