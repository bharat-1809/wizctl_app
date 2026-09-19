import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/rooms/bloc/room_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/room_event.dart';
import 'package:wizctl_app/features/rooms/bloc/room_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late SyncCoordinator sync;
  late TargetResolver resolver;

  RoomBloc build(String roomId) => RoomBloc(
    roomId: roomId,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    setPower: SetPower(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    setBrightness: SetBrightness(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    setKelvin: SetKelvin(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    sync: sync,
  );

  /// A coordinator over the seeded lights. [pollInterval] is the knob the
  /// tests need: short enough to see a tick, or long enough that nothing can
  /// read a bulb except the code under test.
  SyncCoordinator coordinator(Duration pollInterval) => SyncCoordinator(
    refresh: RefreshStates(
      gateway: gateway,
      store: seed.store,
      lights: seed.lights,
      clock: FakeClock(),
    ),
    lights: seed.lights,
    settings: seed.settings,
    pollInterval: pollInterval,
  );

  setUp(() async {
    seed = SeedHome();
    addTearDown(seed.dispose);
    gateway = FakeGateway();
    for (var l in seed.all) {
      gateway.states[l.ip] = LightState(isOn: seed.store.of(l.id).isOn);
    }
    monitor = NetworkMonitor(FakeNetworkInfo('192.168.1'));
    await monitor.refresh();
    resolver = TargetResolver(seed.lights);
    pipeline = DeviceCommandPipeline(
      gateway: gateway,
      store: seed.store,
      network: monitor,
      homeSubnet: () async => '192.168.1',
      clock: FakeClock(),
      ids: SequenceIds(),
    );
    sync = coordinator(const Duration(milliseconds: 20));
  });

  tearDown(() {
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<RoomBloc, RoomState>(
    'the living room: aggregates, capability, summary',
    build: () => build('living'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, RoomStatus.ready);
      expect(s.room?.name, 'Living Room');
      expect(s.lights.map((l) => l.light.id), ['dome', 'floor', 'strip']);
      expect(s.brightness, 58, reason: 'mean of 70, 45, 60');
      expect(
        s.kelvin,
        3050,
        reason: 'mean of 2450, 2700, 4000 to the nearest 50',
      );
      expect(s.canKelvin, isTrue);
      expect(s.kelvinNote, isNull);
      expect(s.summary, ModeSummary.mixed);
      expect(s.anyOn, isTrue);
      expect(s.isEmpty, isFalse);
    },
  );

  blocTest<RoomBloc, RoomState>(
    'the bedroom: a dimmer beside an RGB bulb gets the reach note',
    build: () => build('bedroom'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.kelvinNote, 'Colour temp reaches 1 of 2 bulbs.');
      expect(bloc.state.canKelvin, isTrue);
      expect(bloc.state.anyOn, isFalse);
    },
  );

  blocTest<RoomBloc, RoomState>(
    'the kitchen: one white light is its own summary',
    build: () => build('kitchen'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.summary.name, '5000K white'),
  );

  blocTest<RoomBloc, RoomState>(
    'a room that is not there is gone',
    build: () => build('nope'),
    act: (bloc) => bloc.add(const RoomSubscribed()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.status, RoomStatus.gone),
  );

  blocTest<RoomBloc, RoomState>(
    'the whole-room dials write to every eligible light',
    build: () => build('living'),
    act: (bloc) async {
      bloc.add(const RoomSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomBrightnessChanged(40));
      await Future<void>.delayed(wait);
      bloc.add(const RoomKelvinChanged(3000));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends.where((s) => s.$2.dimming == 40), hasLength(3));
      expect(
        gateway.sends.where((s) => s.$2.temperature == 3000),
        hasLength(3),
      );
      expect(bloc.state.brightness, 40);
      expect(bloc.state.kelvin, 3000);
    },
  );

  blocTest<RoomBloc, RoomState>(
    'the room switch, a light switch and a light rail',
    build: () => build('living'),
    act: (bloc) async {
      bloc.add(const RoomSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomPowerToggled(false));
      await Future<void>.delayed(wait);
      bloc.add(const RoomLightPowerToggled('strip', true));
      await Future<void>.delayed(wait);
      bloc.add(const RoomLightBrightnessChanged('floor', 80));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends.take(3).every((s) => s.$2.state == false), isTrue);
      expect(gateway.sends[3].$1, '192.168.1.111');
      expect(gateway.sends[3].$2.state, isTrue);
      expect(gateway.sends[4].$1, '192.168.1.107');
      expect(gateway.sends[4].$2.dimming, 80);
      expect(bloc.state.lights[1].state.brightness, 80);
    },
  );

  test(
    'the room\'s lights are polled while subscribed and not after',
    () async {
      sync.activateHome('h1');
      var bloc = build('bedroom')..add(const RoomSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads.toSet(), {'192.168.1.115', '192.168.1.118'});
      await bloc.close();
      gateway.reads.clear();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads, isEmpty, reason: 'the scope went with the bloc');
    },
  );

  test(
    'a room deleted under the bloc takes its lights out of the poll',
    () async {
      sync.activateHome('h1');
      var bloc = build('living')..add(const RoomSubscribed());
      addTearDown(bloc.close);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads, isNotEmpty, reason: 'the room was being polled');
      await seed.rooms.delete('living');
      await Future<void>.delayed(wait);
      expect(bloc.state.status, RoomStatus.gone);
      expect(bloc.state.isEmpty, isTrue);
      gateway.reads.clear();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads, isEmpty, reason: 'nothing is on show to poll');
    },
  );

  test(
    'a refresh reads every light of the home and says when it is done',
    () async {
      // A coordinator whose tick cannot fire inside this test, and a read slow
      // enough that the signal cannot be mistaken for one completed before it:
      // every read recorded below is one the event asked for.
      sync.dispose();
      sync = coordinator(const Duration(minutes: 1));
      gateway.readLatency = const Duration(milliseconds: 20);
      sync.activateHome('h1');
      var bloc = build('living')..add(const RoomSubscribed());
      addTearDown(bloc.close);
      await Future<void>.delayed(wait);
      expect(gateway.reads, isEmpty, reason: 'nothing polls in this test');
      var done = Completer<void>();
      bloc.add(RoomRefreshRequested(done: done));
      // Hangs the test rather than failing it if the signal is never completed.
      await done.future;
      var h1 = seed.all.where((l) => l.homeId == 'h1').map((l) => l.ip);
      expect(gateway.reads.toSet(), h1.toSet());
    },
  );
}
