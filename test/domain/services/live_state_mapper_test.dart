import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_mapper.dart';

void main() {
  final now = DateTime(2026, 9, 8, 12);

  test('a scene wins, keeping other channels from before', () {
    var prev = LiveState.initial.copyWith(
      rgb: const Rgb(1, 2, 3),
      kelvin: 4000,
    );
    var s = LiveStateMapper.fromLightState(
      const LightState(
        isOn: true,
        dimming: 80,
        sceneId: 5,
        speed: 150,
        rssi: -52,
        r: 255,
        g: 0,
        b: 0,
        temperature: 2700,
      ),
      previous: prev,
      now: now,
    );
    expect(s.active, ActiveChannel.scene);
    expect(s.sceneId, 5);
    expect(s.speed, 150);
    expect(s.brightness, 80);
    expect(s.isOn, isTrue);
    expect(s.rgb, const Rgb(1, 2, 3));
    expect(s.kelvin, 4000);
    expect(s.rssi, -52);
    expect(s.reachable, isTrue);
    expect(s.updatedAt, now);
  });

  test('temperature maps to white, snapped to 50 and clamped', () {
    var s = LiveStateMapper.fromLightState(
      const LightState(isOn: true, temperature: 2712),
      previous: LiveState.initial,
      now: now,
    );
    expect(s.active, ActiveChannel.white);
    expect(s.kelvin, 2700);
    expect(LiveStateMapper.snapKelvin(7000), 6500);
    expect(LiveStateMapper.snapKelvin(1000), 2200);
    expect(LiveStateMapper.snapKelvin(3524), 3500);
    expect(LiveStateMapper.snapKelvin(3526), 3550);
  });

  test('rgb maps to colour; missing dimming keeps the previous brightness', () {
    var prev = LiveState.initial.copyWith(brightness: 45);
    var s = LiveStateMapper.fromLightState(
      const LightState(isOn: false, r: 255, g: 120, b: 60),
      previous: prev,
      now: now,
    );
    expect(s.active, ActiveChannel.colour);
    expect(s.rgb, const Rgb(255, 120, 60));
    expect(s.brightness, 45);
    expect(s.isOn, isFalse);
  });

  test(
    'scene id 0 is not a scene; white channels only keep the previous kelvin',
    () {
      var s = LiveStateMapper.fromLightState(
        const LightState(isOn: true, sceneId: 0, warmWhite: 200, dimming: 200),
        previous: LiveState.initial,
        now: now,
      );
      expect(s.active, ActiveChannel.white);
      expect(s.kelvin, LiveState.initial.kelvin);
      expect(s.brightness, 100);
    },
  );
}
