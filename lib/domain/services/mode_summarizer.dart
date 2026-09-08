import 'package:wizctl/wizctl.dart';

import '../entities/entities.dart';
import 'capability_rules.dart';

typedef LiveLight = ({Light light, LiveState state});

/// What the Light mode row says for a set of lights (spec §5.3), and the
/// selection rules the modes sheet uses.
class ModeSummarizer {
  ModeSummarizer._();

  /// The dimmable-white swatch colour (kelvin 2700 stop).
  static const Rgb dimmableWarm = Rgb(255, 201, 141);

  static String sceneName(int id) =>
      WizScene.fromId(id)?.displayName ?? 'Scene $id';

  static List<LiveLight> _dropSockets(List<LiveLight> lights) {
    if (lights.length > 1 &&
        lights.any((l) => l.light.bulbClass != BulbClass.socket)) {
      return lights
          .where((l) => l.light.bulbClass != BulbClass.socket)
          .toList();
    }
    return lights;
  }

  static ModeSummary summarize(List<LiveLight> input) {
    if (input.isEmpty) return ModeSummary.nothingSet;
    var lights = _dropSockets(input);
    var first = lights.first.state;
    var same = lights.every(
      (l) =>
          l.state.active == first.active &&
          l.state.sceneId == first.sceneId &&
          l.state.rgb == first.rgb &&
          l.state.kelvin == first.kelvin,
    );
    if (!same) return ModeSummary.mixed;

    if (first.active == ActiveChannel.scene) {
      var dynamic = CapabilityRules.isDynamicScene(first.sceneId);
      return ModeSummary(
        name: sceneName(first.sceneId),
        art: SceneArt(first.sceneId),
        isDynamicScene: dynamic,
        isStaticScene: !dynamic,
        sceneId: first.sceneId,
      );
    }
    if (first.active == ActiveChannel.colour) {
      return ModeSummary(name: 'Colour', art: SolidArt(first.rgb));
    }
    if (lights.every((l) => l.light.bulbClass == BulbClass.socket)) {
      return ModeSummary(
        name: first.isOn ? 'Power on' : 'Power off',
        art: const FlatArt(),
      );
    }
    if (lights.every((l) => l.light.bulbClass == BulbClass.dw)) {
      return const ModeSummary(name: 'Warm white', art: SolidArt(dimmableWarm));
    }
    return ModeSummary(
      name: '${first.kelvin}K white',
      art: SolidArt(kelvinRgb(first.kelvin)),
    );
  }

  static bool sceneSelected(List<LiveLight> lights, int sceneId) =>
      lights.isNotEmpty &&
      lights.every(
        (l) =>
            l.state.active == ActiveChannel.scene && l.state.sceneId == sceneId,
      );

  static bool colourSelected(List<LiveLight> lights, Rgb rgb) =>
      lights.isNotEmpty &&
      lights.every(
        (l) => l.state.active == ActiveChannel.colour && l.state.rgb == rgb,
      );

  static bool whiteSelected(List<LiveLight> lights, int kelvin) =>
      lights.isNotEmpty &&
      lights.every(
        (l) =>
            l.state.active == ActiveChannel.white && l.state.kelvin == kelvin,
      );

  static bool allOnOneDynamicScene(List<LiveLight> lights) {
    if (lights.isEmpty) return false;
    var id = lights.first.state.sceneId;
    return CapabilityRules.isDynamicScene(id) && sceneSelected(lights, id);
  }

  /// The kelvin ramp (spec §5.5) in the domain's integer form.
  static Rgb kelvinRgb(int kelvin) {
    const stops = [
      (2200, Rgb(255, 178, 92)),
      (2700, Rgb(255, 201, 141)),
      (3500, Rgb(255, 224, 188)),
      (4500, Rgb(255, 244, 230)),
      (5500, Rgb(242, 246, 255)),
      (6500, Rgb(220, 233, 255)),
    ];
    if (kelvin <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      var (k1, c1) = stops[i];
      if (kelvin <= k1) {
        var (k0, c0) = stops[i - 1];
        var t = (kelvin - k0) / (k1 - k0);
        int mix(int a, int b) => (a + (b - a) * t).round();
        return Rgb(mix(c0.r, c1.r), mix(c0.g, c1.g), mix(c0.b, c1.b));
      }
    }
    return stops.last.$2;
  }
}
