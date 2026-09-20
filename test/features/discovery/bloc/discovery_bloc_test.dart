import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/sync_coordinator.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_bloc.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_event.dart';
import 'package:wizctl_app/features/discovery/bloc/discovery_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

/// Writes down when discovery pauses and resumes polling.
class _RecordingSync extends SyncCoordinator {
  final List<String> calls = [];
  _RecordingSync({
    required super.refresh,
    required super.lights,
    required super.settings,
  });
  @override
  void pauseForDiscovery() {
    calls.add('pause');
    super.pauseForDiscovery();
  }

  @override
  void resumeAfterDiscovery() {
    calls.add('resume');
    super.resumeAfterDiscovery();
  }
}

const _rgb = DiscoveredLight(
  ip: '192.168.1.126',
  mac: 'newrgb',
  moduleName: 'ESP01_SHRGB1C_31',
);
const _dw = DiscoveredLight(
  ip: '192.168.1.131',
  mac: 'newdw',
  moduleName: 'ESP01_SHDW1C_31',
);
const _known = DiscoveredLight(
  ip: '192.168.1.104',
  mac: 'a8bb50f1c204',
  moduleName: 'ESP01_SHRGB1C_31',
);

void main() {
  late SeedHome seed;
  late FakeGateway gateway;
  late _RecordingSync sync;
  late FakeClock clock;

  DiscoveryBloc build({String? homeId = 'h1', bool onboarding = false}) =>
      DiscoveryBloc(
        homeId: homeId,
        onboarding: onboarding,
        runDiscovery: RunDiscovery(
          gateway: gateway,
          lights: seed.lights,
          store: seed.store,
          network: FakeNetworkInfo('192.168.1'),
          clock: clock,
        ),
        saveDiscoveredLight: SaveDiscoveredLight(
          lights: seed.lights,
          store: seed.store,
          ids: SequenceIds(),
          clock: clock,
        ),
        learnHomeSubnet: LearnHomeSubnet(homes: seed.homes),
        sync: sync,
      );

  setUp(() {
    seed = SeedHome();
    gateway = FakeGateway();
    clock = FakeClock();
    sync = _RecordingSync(
      refresh: RefreshStates(
        gateway: gateway,
        store: seed.store,
        lights: seed.lights,
        clock: clock,
      ),
      lights: seed.lights,
      settings: seed.settings,
    );
    gateway.probeEvents = [const ScanDone([])];
    gateway.broadcastResult = [_rgb, _dw, _known];
    gateway.states['192.168.1.126'] = const LightState(
      isOn: true,
      dimming: 40,
      temperature: 3000,
    );
    gateway.states['192.168.1.131'] = const LightState(
      isOn: false,
      dimming: 60,
    );
    gateway.states['192.168.1.104'] = const LightState(isOn: true, dimming: 70);
  });

  tearDown(() => sync.dispose());

  const wait = Duration(milliseconds: 20);

  /// Long enough that a read is still in flight after [wait], so a test can
  /// interrupt a run rather than race it.
  const stalledRead = Duration(milliseconds: 60);

  /// A read slow enough that the three scripted bulbs land one at a time,
  /// so a test can act between the first row and the end of the run.
  const slowRead = Duration(milliseconds: 30);

  /// The lights `SeedHome` puts in `h1`; the probe phase counts them.
  const knownInHome = 6;

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a quick run probes the known addresses, broadcasts, and ends found',
    build: build,
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    expect: () => [
      // The handler shows the phase the moment the run starts; `RunDiscovery`
      // then names the same phase with the count of addresses to go with it.
      isA<DiscoveryState>()
          .having((s) => s.view, 'view', DiscoveryView.probingKnown)
          .having((s) => s.progress, 'progress', isNull),
      isA<DiscoveryState>()
          .having((s) => s.view, 'view', DiscoveryView.probingKnown)
          .having((s) => s.progress?.total, 'progress.total', knownInHome),
      isA<DiscoveryState>().having(
        (s) => s.view,
        'view',
        DiscoveryView.broadcasting,
      ),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(1)),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(2)),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(3)),
      isA<DiscoveryState>().having((s) => s.view, 'view', DiscoveryView.found),
    ],
    verify: (bloc) {
      var s = bloc.state;
      expect(
        gateway.probeCalls.single,
        containsAll(['192.168.1.104', '192.168.1.118']),
      );
      expect(s.found.map((f) => f.device.displayName), [
        'WiZ RGB',
        'WiZ Dimmable',
        'WiZ RGB',
      ]);
      expect(s.found.first.initial?.brightness, 40);
      expect(s.found.first.kept, isTrue);
      expect(
        s.found.last.device.alreadySaved,
        isTrue,
        reason: 'the dome is already in the home',
      );
      expect(s.subnet, '192.168.1');
      expect(s.sweptOnce, isFalse);
      expect(sync.calls, ['pause', 'resume']);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'onboarding has no home: no probe, nothing already saved',
    build: () => build(homeId: null, onboarding: true),
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    expect: () => [
      // No home, so no probe phase at either end: the run opens on the
      // broadcast and the count never appears.
      isA<DiscoveryState>()
          .having((s) => s.view, 'view', DiscoveryView.broadcasting)
          .having((s) => s.progress, 'progress', isNull),
      isA<DiscoveryState>()
          .having((s) => s.view, 'view', DiscoveryView.broadcasting)
          .having(
            (s) => s.progress?.phase,
            'phase',
            DiscoveryPhase.broadcasting,
          ),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(1)),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(2)),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(3)),
      isA<DiscoveryState>().having((s) => s.view, 'view', DiscoveryView.found),
    ],
    verify: (bloc) {
      expect(gateway.probeCalls, isEmpty);
      expect(bloc.state.view, DiscoveryView.found);
      expect(bloc.state.found.every((f) => !f.device.alreadySaved), isTrue);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a sweep reports its progress and remembers it swept',
    build: build,
    setUp: () {
      gateway.sweepEvents = [
        const ScanProgress(
          addressesProbed: 34,
          addressCount: 254,
          fraction: 34 / 254,
          subnet: '192.168.1',
        ),
        const ScanFound(_rgb),
        const ScanProgress(
          addressesProbed: 254,
          addressCount: 254,
          fraction: 1,
          subnet: '192.168.1',
        ),
        const ScanDone([_rgb]),
      ];
    },
    act: (bloc) => bloc.add(const DiscoverySweepRequested()),
    wait: wait,
    expect: () => [
      isA<DiscoveryState>()
          .having((s) => s.view, 'view', DiscoveryView.sweeping)
          .having((s) => s.progress, 'progress', isNull),
      isA<DiscoveryState>().having((s) => s.progress?.total, 'total', 0),
      isA<DiscoveryState>()
          .having((s) => s.progress?.probed, 'probed', 34)
          .having((s) => s.subnet, 'subnet', '192.168.1'),
      isA<DiscoveryState>().having((s) => s.found, 'found', hasLength(1)),
      isA<DiscoveryState>().having((s) => s.progress?.probed, 'probed', 254),
      isA<DiscoveryState>()
          .having((s) => s.view, 'view', DiscoveryView.found)
          .having((s) => s.sweptOnce, 'sweptOnce', isTrue),
    ],
    verify: (bloc) {
      expect(bloc.state.view, DiscoveryView.found);
      expect(bloc.state.sweptOnce, isTrue);
      expect(bloc.state.found, hasLength(1));
      expect(bloc.state.progress?.total, 254);
      expect(bloc.state.progress?.probed, 254);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'nothing answering is the empty view',
    build: build,
    setUp: () => gateway.broadcastResult = [],
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) => expect(bloc.state.view, DiscoveryView.empty),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a port that will not open is the error view, and polling resumes',
    build: build,
    setUp: () => gateway.failing['broadcast'] = const UnreachableFailure(
      'broadcast',
      'port busy',
    ),
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.view, DiscoveryView.error);
      expect(bloc.state.failure, isA<UnreachableFailure>());
      expect(sync.calls.last, 'resume');
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'keep toggles, and saving marks the row and raises the notice',
    build: build,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      bloc.add(const DiscoveryKeepToggled('192.168.1.126'));
      bloc.add(
        const DiscoverySaveRequested(
          ip: '192.168.1.131',
          alias: 'Hall plug',
          roomId: 'bedroom',
          fixture: Fixture.bulb,
        ),
      );
    },
    wait: wait,
    verify: (bloc) async {
      expect(bloc.state.found.first.kept, isFalse);
      expect(bloc.state.keptCount, 2);
      expect(bloc.state.found[1].device.alreadySaved, isTrue);
      expect(bloc.state.saving, isEmpty);
      expect(
        bloc.state.notice,
        const LightSavedNotice('Hall plug', '192.168.1.131'),
      );
      var saved = await seed.lights.getByMac('h1', 'newdw');
      expect(saved?.name, 'Hall plug');
      expect(saved?.roomId, 'bedroom');
      expect(
        seed.store.of(saved!.id).brightness,
        60,
        reason: 'the initial read seeded the store',
      );
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    "saving the same bulb twice is refused with the use case's line",
    build: build,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      bloc.add(
        const DiscoverySaveRequested(
          ip: '192.168.1.104',
          alias: 'Dome again',
          roomId: 'living',
          fixture: Fixture.dome,
        ),
      );
    },
    wait: wait,
    verify: (bloc) => expect(
      bloc.state.notice,
      const SaveFailedNotice('This light is already in this home.'),
    ),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a save made while the scan is still running keeps its mark',
    build: build,
    // Each read takes [slowRead], so the three rows land at roughly 1x, 2x
    // and 3x it and the run finishes with the last of them. The save below
    // goes in between the first row and that finish.
    setUp: () => gateway.readLatency = slowRead,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(slowRead * 5 ~/ 3);
      bloc.add(
        const DiscoverySaveRequested(
          ip: '192.168.1.126',
          alias: 'Desk lamp',
          roomId: 'living',
          fixture: Fixture.bulb,
        ),
      );
    },
    wait: slowRead * 4,
    verify: (bloc) async {
      expect(bloc.state.view, DiscoveryView.found, reason: 'the run finished');
      expect(bloc.state.found, hasLength(3));
      expect(
        bloc.state.found.first.device.alreadySaved,
        isTrue,
        reason: 'the final list must not undo a save the user already made',
      );
      expect(await seed.lights.getByMac('h1', 'newrgb'), isNotNull);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a home without a subnet learns it from the run',
    build: () => build(homeId: 'h2'),
    act: (bloc) => bloc.add(const DiscoveryStarted()),
    wait: wait,
    verify: (bloc) async =>
        expect((await seed.homes.get('h2'))?.subnet, '192.168.1'),
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'cancelling mid-run leaves the scan and resumes polling once',
    build: build,
    setUp: () => gateway.readLatency = stalledRead,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      bloc.add(const DiscoveryCancelled());
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.isScanning, isFalse);
      expect(
        bloc.state.view,
        DiscoveryView.idle,
        reason: 'the first read had not landed when it was cancelled',
      );
      expect(sync.calls, ['pause', 'resume']);
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'a second start drops the first run and keeps one pause',
    build: build,
    setUp: () => gateway.readLatency = stalledRead,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      gateway.readLatency = Duration.zero;
      bloc.add(const DiscoveryStarted());
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.view, DiscoveryView.found);
      expect(
        bloc.state.found,
        hasLength(3),
        reason: 'the rows are the second run\'s, not both runs\'',
      );
      expect(gateway.probeCalls, hasLength(2));
      expect(sync.calls, [
        'pause',
        'resume',
      ], reason: 'one pause for the screen, resumed once when a run ends');
    },
  );

  blocTest<DiscoveryBloc, DiscoveryState>(
    'clearing the notice leaves the rows alone',
    build: build,
    act: (bloc) async {
      bloc.add(const DiscoveryStarted());
      await Future<void>.delayed(wait);
      bloc.add(
        const DiscoverySaveRequested(
          ip: '192.168.1.131',
          alias: 'Hall plug',
          roomId: 'bedroom',
          fixture: Fixture.bulb,
        ),
      );
      await Future<void>.delayed(wait);
      bloc.add(const DiscoveryNoticeCleared());
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.notice, isNull);
      expect(bloc.state.found, hasLength(3));
      expect(bloc.state.found[1].device.alreadySaved, isTrue);
    },
  );

  test('closing cancels the run and resumes polling', () async {
    var bloc = build()..add(const DiscoveryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await bloc.close();
    expect(sync.calls.last, 'resume');
  });
}
