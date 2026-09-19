import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
// Prefixed: the library's `LightState` is a bulb's reported pilot, and this
// bloc's `LightState` is the screen's state. Both are named here.
import 'package:wizctl/wizctl.dart' as wiz;
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/lights/bloc/light_bloc.dart';
import 'package:wizctl_app/features/lights/bloc/light_event.dart';
import 'package:wizctl_app/features/lights/bloc/light_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late SyncCoordinator sync;
  late TargetResolver resolver;

  /// The signal strength every scripted bulb answers with. It differs from
  /// every value the fixture seeded, so a test can tell that a read landed.
  const int reportedRssi = -50;

  LightBloc build(String id) => LightBloc(
    lightId: id,
    lights: seed.lights,
    rooms: seed.rooms,
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
    setSpeed: SetSpeed(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    setFixture: SetFixture(lights: seed.lights),
    renameLight: RenameLight(lights: seed.lights),
    forgetLight: ForgetLight(lights: seed.lights, store: seed.store),
    sync: sync,
  );

  /// A coordinator over the seeded lights. [pollInterval] is the knob the
  /// tests need: the default is long enough that nothing can read a bulb
  /// except the code under test; a short one makes a tick visible.
  SyncCoordinator coordinator([
    Duration pollInterval = const Duration(seconds: 10),
  ]) => SyncCoordinator(
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

  /// What a scripted bulb reports: the channel and the values [live] holds.
  ///
  /// The bloc reads its light as the screen opens (spec §5.8), so a bulb that
  /// answered with `isOn` alone would report "no scene, no temperature" and
  /// the mapper would rightly move the light to plain white — wiping the
  /// scene the fixture seeded before any test could look at it. A real bulb
  /// answers with what it is doing; so does this one.
  wiz.LightState reported(LiveState live) => wiz.LightState(
    isOn: live.isOn,
    dimming: live.brightness,
    sceneId: live.active == ActiveChannel.scene ? live.sceneId : null,
    temperature: live.active == ActiveChannel.white ? live.kelvin : null,
    r: live.active == ActiveChannel.colour ? live.rgb.r : null,
    g: live.active == ActiveChannel.colour ? live.rgb.g : null,
    b: live.active == ActiveChannel.colour ? live.rgb.b : null,
    speed: live.speed,
    rssi: reportedRssi,
  );

  setUp(() async {
    seed = SeedHome();
    addTearDown(seed.dispose);
    gateway = FakeGateway();
    for (var l in seed.all) {
      gateway.states[l.ip] = reported(seed.store.of(l.id));
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
    sync = coordinator();
    sync.activateHome('h1');
  });

  tearDown(() {
    sync.dispose();
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<LightBloc, LightState>(
    'the dome: name, room, class, capabilities, a static scene, and one read on open',
    build: () => build('dome'),
    act: (bloc) => bloc.add(const LightSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, LightStatus.ready);
      expect(s.light?.name, 'Ceiling dome light');
      expect(s.room?.name, 'Living Room');
      expect(s.light?.className, 'RGB');
      expect(s.live.isOn, isTrue);
      expect(s.canBrightness, isTrue);
      expect(s.canKelvin, isTrue);
      expect(s.canColour, isTrue);
      expect(s.canScenes, isTrue);
      expect(s.isSocket, isFalse);
      expect(s.summary.name, 'Cozy');
      expect(s.isStaticScene, isTrue);
      expect(s.sceneName, 'Cozy');
      expect(s.speedVisible, isFalse);
      expect(gateway.reads, [
        '192.168.1.104',
      ], reason: 'refreshed when the screen opens');
      expect(s.live.rssi, reportedRssi, reason: 'and the read landed');
    },
  );

  blocTest<LightBloc, LightState>(
    'the hallway dims only; a plug switches only',
    build: () {
      seed.lights.seed([
        Light(
          id: 'plug',
          homeId: 'h1',
          roomId: 'kitchen',
          name: 'Plug by the TV',
          ip: '192.168.1.140',
          mac: 'plug',
          bulbClass: wiz.BulbClass.socket,
          fixture: Fixture.socket,
          sortIndex: 9,
          addedAt: DateTime(2026),
        ),
      ]);
      gateway.states['192.168.1.140'] = const wiz.LightState(isOn: false);
      return build('hall');
    },
    act: (bloc) => bloc.add(const LightSubscribed()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.canKelvin, isFalse);
      expect(bloc.state.canColour, isFalse);
      expect(bloc.state.canScenes, isTrue);
      expect(bloc.state.canBrightness, isTrue);
      var plug = build('plug');
      addTearDown(plug.close);
      plug.add(const LightSubscribed());
      return Future<void>.delayed(wait).then((_) {
        expect(plug.state.isSocket, isTrue);
        expect(plug.state.canScenes, isFalse);
        expect(plug.state.canBrightness, isFalse);
      });
    },
  );

  blocTest<LightBloc, LightState>(
    'power, brightness, kelvin reach the bulb; speed only on a dynamic scene',
    build: () => build('dome'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightPowerChanged(false));
      await Future<void>.delayed(wait);
      bloc.add(const LightBrightnessChanged(35));
      await Future<void>.delayed(wait);
      bloc.add(const LightKelvinChanged(3500));
      await Future<void>.delayed(wait);
      bloc.add(const LightSpeedChanged(150));
      await Future<void>.delayed(wait);
      seed.store.update(
        'dome',
        (s) => s.copyWith(active: ActiveChannel.scene, sceneId: 1),
      );
      await Future<void>.delayed(wait);
      bloc.add(const LightSpeedChanged(160));
    },
    wait: wait,
    verify: (bloc) {
      var sends = gateway.sends.map((s) => s.$2).toList();
      expect(sends[0].state, isFalse);
      expect(sends[1].dimming, 35);
      expect(sends[2].temperature, 3500);
      expect(
        sends,
        hasLength(4),
        reason: 'the first speed went nowhere: Cozy is static',
      );
      expect(sends[3].speed, 160);
      expect(bloc.state.speedVisible, isTrue);
      expect(bloc.state.sceneName, 'Ocean');
      expect(bloc.state.isStaticScene, isFalse);
    },
  );

  blocTest<LightBloc, LightState>(
    'fixture and alias changes land in the repository and the state',
    build: () => build('dome'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightFixtureChanged(Fixture.strip));
      await Future<void>.delayed(wait);
      bloc.add(const LightRenamed('Big dome'));
    },
    wait: wait,
    verify: (bloc) async {
      expect(bloc.state.light?.fixture, Fixture.strip);
      expect(bloc.state.light?.name, 'Big dome');
      expect((await seed.lights.get('dome'))?.name, 'Big dome');
    },
  );

  blocTest<LightBloc, LightState>(
    'an empty alias is an error notice, which clears on request',
    build: () => build('dome'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightRenamed('  '));
      await Future<void>.delayed(wait);
      expect(bloc.state.notice, const LightError('A name is required.'));
      expect(bloc.state.light?.name, 'Ceiling dome light', reason: 'unchanged');
      bloc.add(const LightNoticeCleared());
    },
    wait: wait,
    verify: (bloc) => expect(bloc.state.notice, isNull),
  );

  blocTest<LightBloc, LightState>(
    'forgetting raises the notice, then the light is gone',
    build: () => build('strip'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const LightForgotten());
    },
    wait: wait,
    verify: (bloc) async {
      expect(bloc.state.notice, const LightForgottenNotice('Shelf strip'));
      expect(bloc.state.status, LightStatus.gone);
      expect(await seed.lights.get('strip'), isNull);
      expect(seed.store.snapshot.containsKey('strip'), isFalse);
    },
  );

  test(
    'forgetting emits one state, carrying both the notice and gone',
    () async {
      // The repository tells its watchers the light has gone before the
      // delete itself finishes, so the projection is given its own chance to
      // call this light `gone` while the forget is still in flight. The
      // screen must still be told once: it leaves on the notice, and a bare
      // `gone` ahead of that would send it out of the room twice.
      seed.lights.deleteLatency = const Duration(milliseconds: 5);
      var bloc = build('strip')..add(const LightSubscribed());
      addTearDown(bloc.close);
      await Future<void>.delayed(wait);
      var seen = <LightState>[];
      var subscription = bloc.stream.listen(seen.add);
      bloc.add(const LightForgotten());
      await Future<void>.delayed(wait);
      await subscription.cancel();
      expect(
        seen,
        hasLength(1),
        reason: 'the screen gets exactly one reason to leave',
      );
      expect(seen.single.status, LightStatus.gone);
      expect(seen.single.notice, const LightForgottenNotice('Shelf strip'));
      expect(
        seen.single.light?.name,
        'Shelf strip',
        reason: 'the last known light stays so the notice can name it',
      );
    },
  );

  test(
    'clearing the forgotten notice leaves only a bare gone behind',
    () async {
      var bloc = build('strip')..add(const LightSubscribed());
      addTearDown(bloc.close);
      await Future<void>.delayed(wait);
      bloc.add(const LightForgotten());
      await Future<void>.delayed(wait);
      bloc.add(const LightNoticeCleared());
      await Future<void>.delayed(wait);
      expect(bloc.state.status, LightStatus.gone);
      expect(
        bloc.state.notice,
        isNull,
        reason:
            'so this state no longer says which kind of gone it is: a view '
            'that leaves on a bare gone must not clear a forgotten notice, or '
            'must remember that it has already left',
      );
    },
  );

  blocTest<LightBloc, LightState>(
    'retry reads the bulb again',
    build: () => build('hall'),
    act: (bloc) async {
      bloc.add(const LightSubscribed());
      await Future<void>.delayed(wait);
      gateway.reads.clear();
      bloc.add(const LightRetryRequested());
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.reads, ['192.168.1.118']);
      expect(bloc.state.live.reachable, isTrue);
    },
  );

  test('two lost reads in a row show the light as unreachable', () async {
    var bloc = build('hall')..add(const LightSubscribed());
    addTearDown(bloc.close);
    await Future<void>.delayed(wait);
    expect(
      bloc.state.live.reachable,
      isTrue,
      reason: 'the read on open landed',
    );
    gateway.failing['192.168.1.118'] = const UnreachableFailure(
      '192.168.1.118',
      'no answer',
    );
    bloc.add(const LightRetryRequested());
    await Future<void>.delayed(wait);
    expect(
      bloc.state.live.reachable,
      isTrue,
      reason: 'one lost packet is not unreachable',
    );
    bloc.add(const LightRetryRequested());
    await Future<void>.delayed(wait);
    expect(bloc.state.live.reachable, isFalse, reason: 'two in a row are');
  });

  test('the light is polled while it is on show, and not after', () async {
    // A coordinator whose tick can fire inside this test. The one from
    // `setUp` polls every ten seconds, so every other test's reads are the
    // ones its own code asked for.
    sync.dispose();
    sync = coordinator(const Duration(milliseconds: 20));
    sync.activateHome('h1');
    var bloc = build('dome')..add(const LightSubscribed());
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(gateway.reads.toSet(), {
      '192.168.1.104',
    }, reason: 'its own bulb, and nothing else is on show');
    expect(
      gateway.reads.length,
      greaterThan(1),
      reason: 'the read on open, then the poll',
    );
    await bloc.close();
    gateway.reads.clear();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(gateway.reads, isEmpty, reason: 'the scope went with the bloc');
  });

  test(
    'an unknown id is gone, and a light that appears under it revives',
    () async {
      var bloc = build('ghost')..add(const LightSubscribed());
      addTearDown(bloc.close);
      await Future<void>.delayed(wait);
      expect(bloc.state.status, LightStatus.gone);
      expect(bloc.state.light, isNull);
      expect(gateway.reads, isEmpty, reason: 'there is nothing to read');
      await seed.lights.insert(
        Light(
          id: 'ghost',
          homeId: 'h1',
          roomId: 'kitchen',
          name: 'New downlight',
          ip: '192.168.1.150',
          mac: 'ghost',
          bulbClass: wiz.BulbClass.tw,
          fixture: Fixture.dome,
          sortIndex: 9,
          addedAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(wait);
      expect(
        bloc.state.status,
        LightStatus.ready,
        reason: 'the repository stream revives the bloc',
      );
      expect(bloc.state.light?.name, 'New downlight');
      expect(bloc.state.room?.name, 'Kitchen');
    },
  );
}
