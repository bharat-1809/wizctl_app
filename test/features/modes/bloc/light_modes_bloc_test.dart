import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/device_command_pipeline.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';
import 'package:wizctl_app/domain/services/target_resolver.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_bloc.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_event.dart';
import 'package:wizctl_app/features/modes/bloc/light_modes_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late NetworkMonitor monitor;
  late DeviceCommandPipeline pipeline;
  late TargetResolver resolver;

  LightModesBloc build(ModeTarget target) => LightModesBloc(
    target: target,
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    applyColour: ApplyColour(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    applyWhite: ApplyWhite(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    applyScene: ApplyScene(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
    setSpeed: SetSpeed(
      resolver: resolver,
      store: seed.store,
      pipeline: pipeline,
    ),
  );

  setUp(() async {
    seed = SeedHome();
    addTearDown(seed.dispose);
    gateway = FakeGateway();
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
  });

  tearDown(() {
    pipeline.dispose();
    monitor.dispose();
  });

  const wait = Duration(milliseconds: 10);

  blocTest<LightModesBloc, LightModesState>(
    'a room target lists its lights, has a wheel when one is RGB, and reads the first RGB colour',
    build: () => build(const RoomTarget('living')),
    act: (bloc) => bloc.add(const ModesSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, ModesStatus.ready);
      expect(s.targetName, 'Living Room');
      expect(s.lights.map((l) => l.light.id), ['dome', 'floor', 'strip']);
      expect(s.hasWheel, isTrue);
      expect(s.wheelRgb, Rgb.amber, reason: 'the dome is the first RGB light');
      expect(s.tab, ModesTab.colour);
      expect(s.speedVisible, isFalse, reason: 'not all on one dynamic scene');
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'the whole home has no name of its own; a light target has its name and no wheel when it dims only',
    build: () => build(const LightTarget('hall')),
    act: (bloc) => bloc.add(const ModesSubscribed()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.targetName, 'Hallway');
      expect(bloc.state.hasWheel, isFalse);
      expect(bloc.state.lights, hasLength(1));
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'changing the target re-subscribes',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ModesTargetChanged(WholeHomeTarget('h1')));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.target, const WholeHomeTarget('h1'));
      expect(bloc.state.targetName, isNull);
      expect(bloc.state.lights, hasLength(6));
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'a colour reaches the RGB lights of the target; a white the RGB and tunable ones',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ColourPicked(Rgb(255, 0, 0)));
      await Future<void>.delayed(wait);
      bloc.add(const WhitePicked(4000));
    },
    wait: wait,
    verify: (bloc) {
      var colour = gateway.sends.where((s) => s.$2.r == 255).map((s) => s.$1);
      expect(colour, ['192.168.1.104', '192.168.1.107']);
      var white = gateway.sends
          .where((s) => s.$2.temperature == 4000)
          .map((s) => s.$1);
      expect(white, ['192.168.1.104', '192.168.1.107', '192.168.1.111']);
      expect(bloc.state.notice, isNull);
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'nothing eligible is a notice, not a write',
    build: () => build(const LightTarget('hall')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ColourPicked(Rgb(255, 0, 0)));
      await Future<void>.delayed(wait);
      expect(bloc.state.notice, const NoColourNotice());
      bloc.add(const ModesNoticeCleared());
      bloc.add(const WhitePicked(4000));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, isEmpty);
      expect(bloc.state.notice, const NoWhiteNotice());
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'a scene applies with the speed on dynamic ones and reports where it went',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ModesTabChanged(ModesTab.dynamicScenes));
      bloc.add(const ScenePicked(1));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, hasLength(3), reason: 'no plug in the living room');
      expect(
        gateway.sends.every((s) => s.$2.sceneId == 1 && s.$2.speed != null),
        isTrue,
      );
      expect(
        bloc.state.notice,
        const SceneAppliedNotice('Ocean', RoomTarget('living'), 'Living Room'),
      );
      expect(
        bloc.state.speedVisible,
        isTrue,
        reason: 'now all on one dynamic scene',
      );
      expect(bloc.state.currentScene, 1);
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'speed reaches the lights on a dynamic scene',
    build: () => build(const RoomTarget('living')),
    act: (bloc) async {
      bloc.add(const ModesSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const ScenePicked(1));
      await Future<void>.delayed(wait);
      gateway.sends.clear();
      bloc.add(const SpeedChanged(180));
    },
    wait: wait,
    verify: (bloc) {
      expect(gateway.sends, hasLength(3));
      expect(gateway.sends.first.$2.speed, 180);
      expect(bloc.state.speed, 180);
    },
  );

  blocTest<LightModesBloc, LightModesState>(
    'a plug alone has no scene channel',
    build: () {
      seed.lights.seed([
        Light(
          id: 'plug',
          homeId: 'h1',
          roomId: 'kitchen',
          name: 'Plug by the TV',
          ip: '192.168.1.140',
          mac: 'plug',
          bulbClass: BulbClass.socket,
          fixture: Fixture.socket,
          sortIndex: 9,
          addedAt: DateTime(2026),
        ),
      ]);
      return build(const LightTarget('plug'));
    },
    act: (bloc) => bloc
      ..add(const ModesSubscribed())
      ..add(const ScenePicked(6)),
    wait: wait,
    verify: (bloc) => expect(bloc.state.notice, const NoSceneNotice()),
  );

  test('closing a bloc that was never subscribed returns', () async {
    // A sheet can be dismissed before its first frame. The target controller
    // is single-subscription, so awaiting its `close()` here would wait for a
    // done event nobody is listening for: this hangs if that await comes back.
    await build(const LightTarget('hall')).close();
    // Fail fast rather than parking the suite on the 30s default.
  }, timeout: const Timeout(Duration(seconds: 5)));
}
