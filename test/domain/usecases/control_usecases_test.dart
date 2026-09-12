import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';

class _Net implements NetworkInfo {
  @override
  Future<String?> currentSubnet() async => '192.168.1';
}

Light light(String id, BulbClass cls) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: id,
  ip: '192.168.1.$id',
  mac: id,
  bulbClass: cls,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

void main() {
  late FakeGateway gateway;
  late LiveStateStore store;
  late FakeLightRepository lights;
  late DeviceCommandPipeline pipeline;
  late TargetResolver resolver;

  setUp(() async {
    gateway = FakeGateway();
    store = LiveStateStore();
    lights = FakeLightRepository()
      ..seed([
        light('1', BulbClass.rgb),
        light('2', BulbClass.tw),
        light('3', BulbClass.dw),
        light('4', BulbClass.socket),
      ]);
    var monitor = NetworkMonitor(_Net());
    await monitor.refresh();
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    resolver = TargetResolver(lights);
  });

  test('power reaches everything', () async {
    await SetPower(resolver: resolver, store: store, pipeline: pipeline)(
      const WholeHomeTarget('h'),
      true,
    );
    expect(gateway.sends, hasLength(4));
    expect(gateway.sends.every((s) => s.$2.state == true), isTrue);
    expect(store.of('4').isOn, isTrue);
  });

  test('brightness skips the plug, clamps and turns on', () async {
    await SetBrightness(resolver: resolver, store: store, pipeline: pipeline)(
      const WholeHomeTarget('h'),
      150,
    );
    expect(gateway.sends.map((s) => s.$1), [
      '192.168.1.1',
      '192.168.1.2',
      '192.168.1.3',
    ]);
    expect(gateway.sends.first.$2.dimming, maxBrightness);
    expect(gateway.sends.first.$2.state, isTrue);
    expect(store.of('1').brightness, 100);
    expect(store.of('4').brightness, LiveState.initial.brightness);
  });

  test('kelvin reaches only white-capable bulbs and snaps', () async {
    await SetKelvin(resolver: resolver, store: store, pipeline: pipeline)(
      const RoomTarget('r'),
      2712,
    );
    expect(gateway.sends.map((s) => s.$1), ['192.168.1.1', '192.168.1.2']);
    expect(gateway.sends.first.$2.temperature, 2700);
    expect(store.of('1').active, ActiveChannel.white);
    expect(store.of('1').kelvin, 2700);
  });

  test('speed reaches only lights on a dynamic scene', () async {
    store.put(
      '1',
      LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 1),
    );
    store.put(
      '2',
      LiveState.initial.copyWith(active: ActiveChannel.scene, sceneId: 6),
    );
    await SetSpeed(resolver: resolver, store: store, pipeline: pipeline)(
      const WholeHomeTarget('h'),
      150,
    );
    expect(gateway.sends.map((s) => s.$1), ['192.168.1.1']);
    expect(store.of('1').speed, 150);
  });

  test('colour writes only to RGB and reports the count', () async {
    var n = await ApplyColour(
      resolver: resolver,
      store: store,
      pipeline: pipeline,
    )(const WholeHomeTarget('h'), const Rgb(255, 0, 0));
    expect(n, 1);
    expect(gateway.sends.single.$2.r, 255);
    expect(store.of('1').active, ActiveChannel.colour);
    expect(store.of('1').isOn, isTrue);
    expect(
      await ApplyColour(resolver: resolver, store: store, pipeline: pipeline)(
        const LightTarget('2'),
        const Rgb(1, 1, 1),
      ),
      0,
    );
  });

  test('white writes to RGB and TW; scenes to everything but plugs', () async {
    expect(
      await ApplyWhite(resolver: resolver, store: store, pipeline: pipeline)(
        const WholeHomeTarget('h'),
        4000,
      ),
      2,
    );
    gateway.sends.clear();
    expect(
      await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(
        const WholeHomeTarget('h'),
        1,
        speed: 150,
      ),
      3,
    );
    expect(
      gateway.sends.every(
        (s) => s.$2.sceneId == 1 && s.$2.speed == 150 && s.$2.state == true,
      ),
      isTrue,
    );
    gateway.sends.clear();
    expect(
      await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(
        const LightTarget('1'),
        6,
      ),
      1,
    );
    expect(gateway.sends.single.$2.speed, isNull);
    expect(store.of('1').sceneId, 6);
    expect(store.of('1').active, ActiveChannel.scene);
    expect(
      await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(
        const LightTarget('4'),
        6,
      ),
      0,
    );
  });

  test('a colour outside the channel range is clamped, not thrown', () async {
    var n = await ApplyColour(
      resolver: resolver,
      store: store,
      pipeline: pipeline,
    )(const LightTarget('1'), const Rgb(300, -20, 128));
    expect(n, 1);
    expect(gateway.sends.single.$2.r, 255);
    expect(gateway.sends.single.$2.g, 0);
    expect(gateway.sends.single.$2.b, 128);
    expect(store.of('1').rgb, const Rgb(255, 0, 128));
  });

  test('an unknown scene id sends nothing and reports zero', () async {
    expect(
      await ApplyScene(resolver: resolver, store: store, pipeline: pipeline)(
        const WholeHomeTarget('h'),
        999,
      ),
      0,
    );
    expect(gateway.sends, isEmpty);
    expect(store.of('1').active, isNot(ActiveChannel.scene));
  });
}
