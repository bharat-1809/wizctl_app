import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import '../services/capability_rules.dart';
import 'target_command.dart';

/// Colour writes only to RGB bulbs. Returns how many took it; zero means
/// "No colour bulb here".
class ApplyColour extends TargetCommand {
  const ApplyColour({
    required super.resolver,
    required super.store,
    required super.pipeline,
  });

  Future<int> call(ModeTarget target, Rgb rgb) => dispatch(
    target,
    eligible: (light, _) => CapabilityRules.colour(light.bulbClass),
    signal: (_, _) => ControlSignal(state: true, r: rgb.r, g: rgb.g, b: rgb.b),
    patch: (s) =>
        s.copyWith(rgb: rgb, active: ActiveChannel.colour, isOn: true),
  );
}
