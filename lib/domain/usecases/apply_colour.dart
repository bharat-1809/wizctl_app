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

  Future<int> call(ModeTarget target, Rgb rgb) {
    // A wheel drag or a restored colour can land outside the wire's channel
    // range; clamp here so ControlSignal never throws mid-dispatch, and use
    // the clamped value for the store too, so the two can't diverge.
    var safe = Rgb(
      rgb.r.clamp(minColorValue, maxColorValue),
      rgb.g.clamp(minColorValue, maxColorValue),
      rgb.b.clamp(minColorValue, maxColorValue),
    );
    return dispatch(
      target,
      eligible: (light, _) => CapabilityRules.colour(light.bulbClass),
      signal: (_, _) =>
          ControlSignal(state: true, r: safe.r, g: safe.g, b: safe.b),
      patch: (s) =>
          s.copyWith(rgb: safe, active: ActiveChannel.colour, isOn: true),
    );
  }
}
