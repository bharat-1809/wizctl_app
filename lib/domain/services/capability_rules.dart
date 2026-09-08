import 'package:wizctl/wizctl.dart';

import '../entities/live_state.dart';

/// Which controls a bulb class gets (spec §5.1). An unknown class is
/// treated as fully capable, matching the library's own defaults, so a
/// bulb the app cannot classify is never left without controls.
class CapabilityRules {
  CapabilityRules._();

  static bool brightness(BulbClass? c) => c?.supportsBrightness ?? true;

  static bool kelvin(BulbClass? c) => c?.supportsTemperature ?? true;

  static bool colour(BulbClass? c) => c?.supportsColor ?? true;

  static bool scenes(BulbClass? c) => c != BulbClass.socket;

  static bool isDynamicScene(int sceneId) => WizScene.fromId(sceneId)?.isDynamic ?? false;

  /// The speed rail exists only while the bulb is on a dynamic scene.
  static bool speed(LiveState state) => state.active == ActiveChannel.scene && isDynamicScene(state.sceneId);
}
