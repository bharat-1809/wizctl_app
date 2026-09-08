import 'package:wizctl/wizctl.dart';

import '../entities/live_state.dart';
import '../entities/rgb.dart';

/// Turns a bulb's reported pilot into the app's live state (spec §5.2).
class LiveStateMapper {
  LiveStateMapper._();

  static const int kelvinStep = 50;

  static int snapKelvin(int kelvin) =>
      ((kelvin / kelvinStep).round() * kelvinStep).clamp(typicalMinTemperature, typicalMaxTemperature);

  static LiveState fromLightState(LightState state, {required LiveState previous, required DateTime now}) {
    var brightness = (state.dimming ?? previous.brightness).clamp(minBrightness, maxBrightness);
    var base = previous.copyWith(
      isOn: state.isOn,
      brightness: brightness,
      rssi: state.rssi ?? previous.rssi,
      reachable: true,
      updatedAt: now,
    );
    var sceneId = state.sceneId;
    if (sceneId != null && sceneId > 0) {
      return base.copyWith(
        active: ActiveChannel.scene,
        sceneId: sceneId,
        speed: (state.speed ?? previous.speed).clamp(minSpeed, maxSpeed),
      );
    }
    var temperature = state.temperature;
    if (temperature != null) {
      return base.copyWith(active: ActiveChannel.white, kelvin: snapKelvin(temperature));
    }
    if (state.r != null && state.g != null && state.b != null) {
      return base.copyWith(active: ActiveChannel.colour, rgb: Rgb(state.r!, state.g!, state.b!));
    }
    return base.copyWith(active: ActiveChannel.white);
  }
}
