import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/blink_light.dart';

import '../../support/fakes.dart';

void main() {
  test('reads, drives amber, holds two seconds, restores', () async {
    var gateway = FakeGateway();
    var clock = FakeClock();
    gateway.states['192.168.1.5'] = const LightState(
      isOn: true,
      dimming: 40,
      sceneId: 6,
      speed: 100,
    );
    await BlinkLight(gateway: gateway, clock: clock)(
      '192.168.1.5',
      bulbClass: BulbClass.rgb,
    );
    expect(gateway.reads, ['192.168.1.5']);
    expect(gateway.sends, hasLength(2));
    var blink = gateway.sends.first.$2;
    expect(
      (blink.r, blink.g, blink.b, blink.dimming, blink.state),
      (255, 176, 32, 100, true),
    );
    expect(clock.delays, [const Duration(seconds: 2)]);
    var restore = gateway.sends.last.$2;
    expect(restore.sceneId, 6);
    expect(restore.dimming, 40);
    expect(restore.state, isTrue);
  });

  test('blink signals per class', () {
    const on = LightState(isOn: true, dimming: 50);
    const off = LightState(isOn: false, dimming: 50);
    expect(BlinkLight.blinkSignal(BulbClass.tw, on).temperature, 2700);
    expect(BlinkLight.blinkSignal(BulbClass.tw, on).dimming, 100);
    expect(BlinkLight.blinkSignal(BulbClass.dw, on).state, isFalse);
    expect(BlinkLight.blinkSignal(BulbClass.dw, off).state, isTrue);
    expect(BlinkLight.blinkSignal(BulbClass.dw, off).dimming, 100);
    expect(BlinkLight.blinkSignal(BulbClass.fanDim, on).state, isFalse);
    expect(BlinkLight.blinkSignal(BulbClass.socket, on).state, isFalse);
    expect(BlinkLight.blinkSignal(BulbClass.socket, off).state, isTrue);
    expect(BlinkLight.blinkSignal(BulbClass.socket, off).dimming, isNull);
    expect(BlinkLight.blinkSignal(null, on).r, 255);
  });

  test('a failed read means no blink', () async {
    var gateway = FakeGateway();
    gateway.failing['192.168.1.5'] = const TimeoutFailure('192.168.1.5', 2);
    await expectLater(
      BlinkLight(gateway: gateway, clock: FakeClock())('192.168.1.5'),
      throwsA(isA<DeviceException>()),
    );
    expect(gateway.sends, isEmpty);
  });
}
