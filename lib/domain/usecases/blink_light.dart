import 'package:wizctl/wizctl.dart';

import '../entities/live_state.dart';
import '../entities/rgb.dart';
import '../services/clock.dart';
import '../services/device_gateway.dart';

/// Blink to identify: read state, drive the bulb, wait, write the captured
/// state back. Not an animation; a real write and restore.
class BlinkLight {
  final DeviceGateway _gateway;
  final Clock _clock;

  /// How long the bulb holds the attention state (spec §5.10).
  final Duration hold;

  BlinkLight({
    required DeviceGateway gateway,
    required Clock clock,
    this.hold = const Duration(seconds: 2),
  }) : _gateway = gateway, // ignore: prefer_initializing_formals
       _clock = clock; // ignore: prefer_initializing_formals

  /// What "blink" means per class (spec §5.10): RGB goes amber at full,
  /// tunable white goes to the default kelvin at full, dimmable and fan
  /// flip between off and full, a plug flips power. Unknown classes are
  /// treated as RGB.
  static ControlSignal blinkSignal(BulbClass? bulbClass, LightState captured) =>
      switch (bulbClass) {
        BulbClass.rgb || null => ControlSignal(
          state: true,
          r: Rgb.amber.r,
          g: Rgb.amber.g,
          b: Rgb.amber.b,
          dimming: maxBrightness,
        ),
        BulbClass.tw => ControlSignal(
          state: true,
          temperature: LiveState.defaultKelvin,
          dimming: maxBrightness,
        ),
        BulbClass.dw || BulbClass.fanDim =>
          captured.isOn
              ? ControlSignal(state: false)
              : ControlSignal(state: true, dimming: maxBrightness),
        BulbClass.socket => ControlSignal(state: !captured.isOn),
      };

  Future<void> call(String ip, {BulbClass? bulbClass}) async {
    var captured = await _gateway.readState(ip);
    await _gateway.send(ip, blinkSignal(bulbClass, captured));
    await _clock.delay(hold);
    await _gateway.send(ip, ControlSignal.fromState(captured));
  }
}
