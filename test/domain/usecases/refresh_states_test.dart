import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/usecases/refresh_states.dart';

import '../../support/fakes.dart';

Light light(String id) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: id,
  ip: '192.168.1.$id',
  mac: id,
  bulbClass: BulbClass.rgb,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

void main() {
  test(
    'reads every light, maps the state, and marks unreachable after two misses',
    () async {
      var gateway = FakeGateway();
      var store = LiveStateStore();
      var lights = FakeLightRepository()..seed([light('1'), light('2')]);
      gateway.states['192.168.1.1'] = const LightState(
        isOn: true,
        dimming: 80,
        temperature: 4000,
        rssi: -60,
      );
      gateway.failing['192.168.1.2'] = const TimeoutFailure('192.168.1.2', 2);
      store.put('2', LiveState.initial.copyWith(reachable: true));
      var refresh = RefreshStates(
        gateway: gateway,
        store: store,
        lights: lights,
        clock: FakeClock(),
      );

      await refresh.forHome('h');
      expect(store.of('1').isOn, isTrue);
      expect(store.of('1').kelvin, 4000);
      expect(store.of('1').reachable, isTrue);
      expect(store.of('1').rssi, -60);
      expect(
        store.of('2').reachable,
        isTrue,
        reason: 'one miss is not unreachable',
      );

      await refresh(['2']);
      expect(store.of('2').reachable, isFalse);

      gateway.failing.clear();
      gateway.states['192.168.1.2'] = const LightState(isOn: false);
      await refresh(['2']);
      expect(store.of('2').reachable, isTrue);
      expect(gateway.reads.where((ip) => ip == '192.168.1.2').length, 3);
    },
  );

  test('ignores ids that no longer exist', () async {
    var refresh = RefreshStates(
      gateway: FakeGateway(),
      store: LiveStateStore(),
      lights: FakeLightRepository(),
      clock: FakeClock(),
    );
    await refresh(['ghost']);
  });
}
