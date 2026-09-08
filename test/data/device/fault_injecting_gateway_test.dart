import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/data/device/fault_injecting_gateway.dart';
import 'package:wizctl_app/data/device/fault_injecting_network_info.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fakes.dart';

void main() {
  test('force timeout waits 1.1 s then fails every read and write', () async {
    var inner = FakeGateway()..states['1.1.1.1'] = const LightState(isOn: true);
    var flags = const DebugFlags(forceTimeout: true);
    var clock = FakeClock();
    var gateway = FaultInjectingGateway(
      inner,
      flags: () => flags,
      clock: clock,
    );
    await expectLater(
      gateway.readState('1.1.1.1'),
      throwsA(isA<DeviceException>()),
    );
    await expectLater(
      gateway.send('1.1.1.1', ControlSignal.on()),
      throwsA(isA<DeviceException>()),
    );
    expect(clock.delays, [
      const Duration(milliseconds: 1100),
      const Duration(milliseconds: 1100),
    ]);
    expect(inner.sends, isEmpty);
  });

  test('find nothing empties broadcast and the sweep; off network reports another subnet', () async {
    var inner = FakeGateway()
      ..broadcastResult = [const DiscoveredLight(ip: '1', mac: 'm')];
    var gateway = FaultInjectingGateway(
      inner,
      flags: () => const DebugFlags(findNothing: true),
      clock: FakeClock(),
    );
    expect(await gateway.broadcast(), isEmpty);
    var events = await gateway.sweep().toList();
    expect(events.whereType<ScanProgress>(), hasLength(4));
    expect((events.last as ScanDone).lights, isEmpty);
    var passthrough = FaultInjectingGateway(
      inner,
      flags: () => DebugFlags.none,
      clock: FakeClock(),
    );
    expect(await passthrough.broadcast(), hasLength(1));
    var net = FaultInjectingNetworkInfo(
      FakeNetworkInfo('192.168.1'),
      flags: () => const DebugFlags(offNetwork: true),
    );
    expect(await net.currentSubnet(), '10.0.0');
  });
}
