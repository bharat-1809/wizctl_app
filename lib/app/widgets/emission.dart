import 'package:flutter/material.dart';
import 'package:wizctl/wizctl.dart';

import '../../core/util/color_maths.dart';
import '../../core/widgets/fixture_hero.dart';
import '../../core/widgets/scene_gradients.dart';
import '../../domain/entities/entities.dart';

/// What a light emits (spec §5.6): nothing when off or unreachable; its
/// colour on an RGB bulb showing a colour, the scene's `from` colour on a
/// scene, the kelvin colour otherwise, all scaled by brightness.
///
/// A null [bulbClass] is a bulb the app could not classify, which
/// `CapabilityRules` treats as fully capable; the colour channel is taken at
/// its word here for the same reason.
WizEmission emissionOf(LiveState live, BulbClass? bulbClass) {
  if (!live.isOn || !live.reachable) return WizEmission.off;
  var color = switch (live.active) {
    ActiveChannel.colour when bulbClass == BulbClass.rgb || bulbClass == null =>
      Color.fromARGB(255, live.rgb.r, live.rgb.g, live.rgb.b),
    ActiveChannel.scene =>
      sceneGradients[live.sceneId]?.from ?? kelvinToColor(live.kelvin),
    _ => kelvinToColor(live.kelvin),
  };
  return WizEmission.lit(color: color, brightness: live.brightness);
}
