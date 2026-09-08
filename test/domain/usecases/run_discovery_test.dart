import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/usecases/run_discovery.dart';

import '../../support/fakes.dart';

void main() {
  late FakeGateway gateway;
  late FakeLightRepository lights;
  late LiveStateStore store;
  late RunDiscovery run;

  setUp(() {
    gateway = FakeGateway();
    lights = FakeLightRepository()
      ..seed([
        Light(
          id: 'known',
          homeId: 'h',
          roomId: 'r',
          name: 'Hallway',
          ip: '192.168.1.118',
          mac: 'knownmac',
          bulbClass: BulbClass.dw,
          fixture: Fixture.bulb,
          addedAt: DateTime(2026),
        ),
      ]);
    store = LiveStateStore();
    run = RunDiscovery(
      gateway: gateway,
      lights: lights,
      store: store,
      network: FakeNetworkInfo('192.168.1'),
      clock: FakeClock(),
    );
  });

  test(
    'quick mode probes known lights, then broadcasts, enriching new devices',
    () async {
      gateway.probeEvents = [
        const ScanProgress(addressesProbed: 1, addressCount: 1, fraction: 1),
        const ScanFound(
          DiscoveredLight(
            ip: '192.168.1.118',
            mac: 'knownmac',
            moduleName: 'ESP01_SHDW1C_31',
          ),
        ),
        const ScanDone([
          DiscoveredLight(
            ip: '192.168.1.118',
            mac: 'knownmac',
            moduleName: 'ESP01_SHDW1C_31',
          ),
        ]),
      ];
      gateway.states['192.168.1.118'] = const LightState(
        isOn: true,
        dimming: 50,
      );
      gateway.broadcastResult = [
        const DiscoveredLight(ip: '192.168.1.126', mac: 'newmac'),
      ];
      gateway.configs['192.168.1.126'] = const BulbConfig(
        moduleName: 'ESP01_SHRGB1C_31',
        fwVersion: '1.25.0',
      );
      gateway.states['192.168.1.126'] = const LightState(
        isOn: false,
        dimming: 70,
        temperature: 3000,
      );

      var updates = await run(homeId: 'h', mode: DiscoveryMode.quick).toList();

      var phases = updates
          .whereType<PhaseChanged>()
          .map((p) => p.progress.phase)
          .toList();
      expect(phases.first, DiscoveryPhase.probingKnown);
      expect(phases, contains(DiscoveryPhase.broadcasting));
      expect(gateway.probeCalls, [
        ['192.168.1.118'],
      ]);
      var found = updates.whereType<DeviceFound>().toList();
      expect(found.map((f) => f.device.mac), ['knownmac', 'newmac']);
      expect(found.first.device.alreadySaved, isTrue);
      expect(
        store.of('known').isOn,
        isTrue,
        reason: 'known lights get their state refreshed',
      );
      expect(found.last.device.bulbClass, BulbClass.rgb);
      expect(found.last.device.fwVersion, '1.25.0');
      expect(found.last.initial!.kelvin, 3000);
      var done = updates.last as DiscoveryFinished;
      expect(done.devices, hasLength(2));
      expect(done.subnet, '192.168.1');
      expect(done.failedRanges, isEmpty);
    },
  );

  test('sweep mode maps progress and richer replies', () async {
    gateway.sweepEvents = [
      const ScanProgress(
        addressesProbed: 16,
        addressCount: 254,
        fraction: 0.03,
        subnet: '192.168.1',
      ),
      const ScanFound(DiscoveredLight(ip: '192.168.1.131', mac: 'm1')),
      const ScanUpdated(
        DiscoveredLight(
          ip: '192.168.1.131',
          mac: 'm1',
          moduleName: 'ESP01_SHTW1C_31',
        ),
      ),
      const ScanFailed(
        addressRange: '192.168.1.200-192.168.1.254',
        error: 'socket closed',
      ),
      const ScanProgress(
        addressesProbed: 254,
        addressCount: 254,
        fraction: 1,
        subnet: '192.168.1',
      ),
      const ScanDone([
        DiscoveredLight(
          ip: '192.168.1.131',
          mac: 'm1',
          moduleName: 'ESP01_SHTW1C_31',
        ),
      ]),
    ];
    var updates = await run(homeId: 'h', mode: DiscoveryMode.sweep).toList();
    var progress = updates
        .whereType<PhaseChanged>()
        .map((p) => p.progress)
        .toList();
    expect(progress.first.phase, DiscoveryPhase.sweeping);
    expect(progress.last.probed, 254);
    expect(progress.last.subnet, '192.168.1');
    expect(updates.whereType<DeviceFound>(), hasLength(1));
    expect(
      updates.whereType<DeviceUpdated>().single.device.bulbClass,
      BulbClass.tw,
    );
    expect(
      (updates.last as DiscoveryFinished).devices.single.bulbClass,
      BulbClass.tw,
    );
    expect((updates.last as DiscoveryFinished).failedRanges, [
      '192.168.1.200-192.168.1.254',
    ]);
  });

  test('a gateway failure surfaces as DiscoveryFailed', () async {
    gateway.failing['broadcast'] = const UnreachableFailure(
      '255.255.255.255',
      'no route',
    );
    var updates = await run(
      homeId: 'h',
      mode: DiscoveryMode.quick,
      probeKnown: false,
    ).toList();
    expect(updates.last, isA<DiscoveryFailed>());
    expect(gateway.probeCalls, isEmpty);
  });
}
