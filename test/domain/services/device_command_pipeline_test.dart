import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

import '../../support/fakes.dart';

class _Net implements NetworkInfo {
  String? subnet = '192.168.1';
  @override
  Future<String?> currentSubnet() async => subnet;
}

Light light(String id, {String? name}) => Light(
  id: id,
  homeId: 'h',
  roomId: 'r',
  name: name ?? id,
  ip: '192.168.1.$id',
  mac: id,
  bulbClass: BulbClass.rgb,
  fixture: Fixture.bulb,
  addedAt: DateTime(2026),
);

void main() {
  late FakeGateway gateway;
  late LiveStateStore store;
  late _Net net;
  late NetworkMonitor monitor;
  late FakeClock clock;
  late DeviceCommandPipeline pipeline;
  late List<CommandReport> reports;

  setUp(() async {
    gateway = FakeGateway();
    store = LiveStateStore();
    net = _Net();
    monitor = NetworkMonitor(net);
    await monitor.refresh();
    clock = FakeClock();
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: clock,
      ids: SequenceIds(),
    );
    reports = [];
    pipeline.reports.listen(reports.add);
  });

  CommandBatch batch(List<Light> lights, int brightness, {String? key}) =>
      CommandBatch(
        items: [
          for (var l in lights)
            CommandItem(
              light: l,
              signal: ControlSignal(dimming: brightness),
              patch: (s) => s.copyWith(brightness: brightness),
            ),
        ],
        throttleKey: key,
      );

  test(
    'applies optimistically, sends, and reports pending then succeeded',
    () async {
      await pipeline.run(batch([light('1', name: 'Hallway')], 70));
      await Future<void>.delayed(Duration.zero);
      expect(store.of('1').brightness, 70);
      expect(store.of('1').reachable, isTrue);
      expect(gateway.sends.single.$1, '192.168.1.1');
      expect(gateway.sends.single.$2.dimming, 70);
      expect(reports, [
        const CommandPending('id1', ['1'], 'Sending to Hallway'),
        const CommandSucceeded('id1'),
      ]);
    },
  );

  test(
    'a failing light reverts, goes unreachable and can be retried',
    () async {
      store.put(
        '1',
        LiveState.initial.copyWith(brightness: 30, reachable: true),
      );
      gateway.failing['192.168.1.1'] = const TimeoutFailure('192.168.1.1', 3);
      await pipeline.run(batch([light('1'), light('2')], 70));
      await Future<void>.delayed(Duration.zero);
      expect(store.of('1').brightness, 30);
      expect(store.of('1').reachable, isFalse);
      expect(store.of('2').brightness, 70);
      expect(reports.whereType<CommandFailed>().single.lightId, '1');
      expect(reports.whereType<CommandSucceeded>(), isEmpty);
      expect(reports.first, isA<CommandPending>());
      expect(
        (reports.first as CommandPending).description,
        'Sending to 2 lights',
      );

      gateway.failing.clear();
      await pipeline.retry('id1');
      await Future<void>.delayed(Duration.zero);
      expect(store.of('1').brightness, 70);
      expect(store.of('1').reachable, isTrue);
      expect(reports.last, const CommandSucceeded('id1'));

      gateway.failing['192.168.1.1'] = const TimeoutFailure('192.168.1.1', 3);
      await pipeline.run(batch([light('1')], 80));
      await pipeline.retry('id2');
      await Future<void>.delayed(Duration.zero);
      expect(reports.last, isA<CommandRetryFailed>());
      expect(store.of('1').brightness, 70);
    },
  );

  test('every failed light in a batch gets its own report and retry resends all of them', () async {
    gateway.failing['192.168.1.1'] = const TimeoutFailure('192.168.1.1', 3);
    gateway.failing['192.168.1.2'] = const TimeoutFailure('192.168.1.2', 3);
    await pipeline.run(batch([light('1'), light('2'), light('3')], 70));
    await Future<void>.delayed(Duration.zero);

    var failures = reports.whereType<CommandFailed>().toList();
    expect(failures.map((f) => f.lightId).toSet(), {'1', '2'});
    expect(failures.map((f) => f.id).toSet(), {'id1'});
    expect(store.of('1').reachable, isFalse);
    expect(store.of('2').reachable, isFalse);
    expect(store.of('3').brightness, 70);
    expect(store.of('3').reachable, isTrue);
    expect(reports.whereType<CommandSucceeded>(), isEmpty);

    gateway.failing.clear();
    await pipeline.retry('id1');
    await Future<void>.delayed(Duration.zero);

    expect(store.of('1').brightness, 70);
    expect(store.of('1').reachable, isTrue);
    expect(store.of('2').brightness, 70);
    expect(store.of('2').reachable, isTrue);
    expect(reports.last, const CommandSucceeded('id1'));
    expect(gateway.sends.where((s) => s.$1 == '192.168.1.1').length, 2);
    expect(gateway.sends.where((s) => s.$1 == '192.168.1.2').length, 2);

    // The entry is cleared after one retry: retrying again is a no-op.
    await Future<void>.delayed(Duration.zero);
    reports.clear();
    await pipeline.retry('id1');
    await Future<void>.delayed(Duration.zero);
    expect(reports, isEmpty);
  });

  test('off network fails fast without sending or patching', () async {
    net.subnet = '10.0.0';
    await monitor.refresh();
    await pipeline.run(batch([light('1')], 70));
    await Future<void>.delayed(Duration.zero);
    expect(gateway.sends, isEmpty);
    expect(store.of('1').brightness, LiveState.initial.brightness);
    expect(reports.single, isA<CommandFailed>());
    expect((reports.single as CommandFailed).failure, isA<OffNetworkFailure>());
  });

  test('batches with one throttle key coalesce to first and last', () {
    fakeAsync((async) {
      gateway.sendLatency = const Duration(milliseconds: 50);
      unawaited(pipeline.run(batch([light('1')], 20, key: 'b')));
      unawaited(pipeline.run(batch([light('1')], 40, key: 'b')));
      unawaited(pipeline.run(batch([light('1')], 65, key: 'b')));
      async.flushMicrotasks();
      expect(store.of('1').brightness, 65);
      async.elapse(const Duration(milliseconds: 500));
      expect(gateway.sends.map((s) => s.$2.dimming), [20, 65]);
      expect(store.of('1').brightness, 65);
      // The 120 ms throttle is what was *requested* of the clock, not real
      // elapsed time: FakeClock.delay completes immediately (spec §5.11).
      expect(clock.delays, [const Duration(milliseconds: 120)]);
    });
  });
}
