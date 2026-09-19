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
import 'package:wizctl_app/features/home/bloc/home_screen_bloc.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_event.dart';
import 'package:wizctl_app/features/home/bloc/home_screen_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late SyncCoordinator sync;

  HomeScreenBloc build() => HomeScreenBloc(
    homes: seed.homes,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    settings: seed.settings,
    setPower: SetPower(
      resolver: TargetResolver(seed.lights),
      store: seed.store,
      pipeline: pipeline,
    ),
    sync: sync,
  );

  /// A coordinator over the seeded lights. [pollInterval] is the knob the
  /// tests need: short enough to see a tick, or long enough that nothing
  /// can read a bulb except the code under test.
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

  blocTest<HomeScreenBloc, HomeScreenState>(
    'subscribing projects the active home: rooms, counts, the unreachable',
    build: build,
    act: (bloc) => bloc.add(const HomeScreenSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, HomeScreenStatus.ready);
      expect(s.home?.name, 'Kaverappa House');
      expect(s.rooms.map((r) => r.room.name), [
        'Living Room',
        'Bedroom',
        'Kitchen',
      ]);
      expect(s.rooms.map((r) => r.lightCount), [3, 2, 1]);
      expect(s.rooms.map((r) => r.onCount), [2, 0, 1]);
      expect(s.lightCount, 6);
      expect(s.onCount, 3);
      expect(s.unreachableCount, 1);
      expect(s.anyOn, isTrue);
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'no active home is its own status',
    build: () {
      seed = SeedHome(active: false);
      addTearDown(seed.dispose);
      return build();
    },
    act: (bloc) => bloc.add(const HomeScreenSubscribed()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.status, HomeScreenStatus.noHome),
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'switching the active home re-projects onto the new one',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      await seed.settings.save(const AppSettings(activeHomeId: 'h2'));
    },
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, HomeScreenStatus.ready);
      expect(s.home?.id, 'h2');
      expect(s.home?.name, 'Studio');
      expect(s.rooms.map((r) => r.room.name), ['Desk']);
      expect(s.lights.map((l) => l.light.id), ['task']);
      expect(s.lightCount, 1);
      expect(s.onCount, 1);
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'all power off reaches every light of the home',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const AllPowerToggled(false));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, hasLength(6));
      expect(gateway.sends.every((s) => s.$2.state == false), isTrue);
      expect(bloc.state.onCount, 0);
      expect(
        gateway.sends.map((s) => s.$1),
        isNot(contains('10.0.0.42')),
        reason: 'the Studio is another home',
      );
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'room power reaches that room only',
    build: build,
    act: (bloc) async {
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const HomeRoomPowerToggled('bedroom', true));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends.map((s) => s.$1), [
        '192.168.1.115',
        '192.168.1.118',
      ]);
      expect(bloc.state.rooms[1].onCount, 2);
    },
  );

  blocTest<HomeScreenBloc, HomeScreenState>(
    'a refresh request reads every light now',
    // A coordinator whose tick cannot fire inside this test: every read it
    // records is one the event asked for, so the assertions below fail if
    // `HomeRefreshRequested` reaches nothing.
    build: () {
      sync.dispose();
      sync = coordinator(const Duration(minutes: 1));
      return build();
    },
    act: (bloc) async {
      sync.activateHome('h1');
      bloc.add(const HomeScreenSubscribed());
      await Future<void>.delayed(wait);
      expect(gateway.reads, isEmpty, reason: 'nothing polls in this test');
      bloc.add(const HomeRefreshRequested());
    },
    wait: wait,
    verify: (bloc) {
      var h1 = seed.all.where((l) => l.homeId == 'h1').map((l) => l.ip);
      expect(gateway.reads, hasLength(h1.length));
      expect(gateway.reads.toSet(), h1.toSet());
      expect(
        bloc.state.unreachableCount,
        0,
        reason: 'the Hallway answered this time',
      );
    },
  );

  test('a refresh completes the done signal it was handed', () async {
    // Long enough that only the event can be reading, and slow enough that
    // the signal cannot be mistaken for one completed before the read.
    sync.dispose();
    sync = coordinator(const Duration(minutes: 1));
    gateway.readLatency = const Duration(milliseconds: 20);
    sync.activateHome('h1');
    var bloc = build();
    addTearDown(bloc.close);
    var done = Completer<void>();
    bloc.add(HomeRefreshRequested(done: done));
    // Hangs the test rather than failing it if the signal is never completed.
    await done.future;
    expect(gateway.reads, hasLength(6));
  });

  test(
    'the home\'s lights are polled while subscribed and not after',
    () async {
      sync.activateHome('h1');
      var bloc = build()..add(const HomeScreenSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(
        gateway.reads,
        containsAll(['192.168.1.104', '192.168.1.118', '192.168.1.121']),
      );
      await bloc.close();
      gateway.reads.clear();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads, isEmpty, reason: 'the scope went with the bloc');
    },
  );

  test(
    'a home deleted under the bloc takes its lights out of the poll',
    () async {
      sync.activateHome('h1');
      var bloc = build()..add(const HomeScreenSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads, isNotEmpty, reason: 'the home was being polled');
      await seed.homes.delete('h1');
      await Future<void>.delayed(wait);
      expect(bloc.state.status, HomeScreenStatus.noHome);
      gateway.reads.clear();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(gateway.reads, isEmpty, reason: 'nothing is on show to poll');
      await bloc.close();
    },
  );
}
