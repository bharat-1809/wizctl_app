import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_event.dart';
import 'package:wizctl_app/features/onboarding/bloc/onboarding_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

const _rgb = FoundDevice(
  device: DiscoveredDevice(
    ip: '192.168.1.126',
    mac: 'rgb',
    bulbClass: BulbClass.rgb,
  ),
  initial: LiveState.initial,
);
const _plug = FoundDevice(
  device: DiscoveredDevice(
    ip: '192.168.1.140',
    mac: 'plug',
    bulbClass: BulbClass.socket,
  ),
);
const _dropped = FoundDevice(
  device: DiscoveredDevice(
    ip: '192.168.1.131',
    mac: 'dw',
    bulbClass: BulbClass.dw,
  ),
  kept: false,
);

/// Long enough to catch the write mid-flight without making the suite wait.
const _slowWrite = Duration(milliseconds: 40);

/// Long enough for a write over the fakes, which awaits but never delays.
const _settled = Duration(milliseconds: 10);

void main() {
  late SeedHome seed;

  OnboardingBloc build() => OnboardingBloc(
    finishOnboarding: FinishOnboarding(
      homes: seed.homes,
      rooms: seed.rooms,
      lights: seed.lights,
      settings: seed.settings,
      store: seed.store,
      ids: SequenceIds(),
      clock: FakeClock(),
    ),
    ids: SequenceIds(),
  );

  setUp(() {
    seed = SeedHome.empty();
    addTearDown(seed.dispose);
  });

  test('the first state is step one with the three offered rooms', () {
    var s = OnboardingState.initial;
    expect(s.step, OnboardingStep.nameHome);
    expect(s.nameEmpty, isTrue);
    expect(s.setupRooms.map((r) => r.name), [
      'Living Room',
      'Bedroom',
      'Kitchen',
    ]);
    expect(s.setupRooms.every((r) => !r.custom), isTrue);
  });

  blocTest<OnboardingBloc, OnboardingState>(
    'a name moves to discovering; a blank one does not',
    build: build,
    act: (bloc) async {
      bloc
        ..add(const OnboardingNameChanged('   '))
        ..add(const OnboardingHomeCreated());
      await pumpEventQueue();
      expect(
        bloc.state.step,
        OnboardingStep.nameHome,
        reason: 'a blank name leaves the flow on step one',
      );
      bloc
        ..add(const OnboardingNameChanged('Kaverappa House'))
        ..add(const OnboardingHomeCreated());
    },
    verify: (bloc) {
      expect(bloc.state.step, OnboardingStep.discovering);
      expect(bloc.state.draftName, 'Kaverappa House');
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'to naming: only kept devices, each assigned the first room and its default fixture',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _dropped, _plug], '192.168.1')),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.step, OnboardingStep.nameLights);
      expect(s.kept.map((f) => f.device.ip), [
        '192.168.1.126',
        '192.168.1.140',
      ]);
      expect(s.subnet, '192.168.1');
      expect(
        s.assignments['192.168.1.126'],
        const Assignment(
          alias: '',
          roomTempId: 'sr-living',
          fixture: Fixture.bulb,
        ),
      );
      expect(s.assignments['192.168.1.140']?.fixture, Fixture.socket);
      expect(s.namesComplete, isFalse);
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'back walks the steps down',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb], null))
      ..add(const OnboardingBack())
      ..add(const OnboardingBack())
      ..add(const OnboardingBack()),
    verify: (bloc) => expect(bloc.state.step, OnboardingStep.nameHome),
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'going back and forward again keeps what was named',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingBack())
      ..add(const OnboardingToNaming([_rgb], '192.168.1')),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.step, OnboardingStep.nameLights);
      expect(
        s.assignments['192.168.1.126']?.alias,
        'Ceiling dome light',
        reason: 'a row the second run kept again keeps the name it was given',
      );
      expect(s.assignments.keys, [
        '192.168.1.126',
      ], reason: 'a row the second run did not keep is no longer assigned');
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'alias, room and fixture edits; a new room is custom and can take the light',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingRoomPicked('192.168.1.126', 'sr-bedroom'))
      ..add(const OnboardingFixturePicked('192.168.1.126', Fixture.dome))
      ..add(
        const OnboardingRoomAdded(
          'Study',
          RoomGlyph.lampDesk,
          forIp: '192.168.1.140',
        ),
      )
      ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV')),
    verify: (bloc) {
      var s = bloc.state;
      expect(
        s.assignments['192.168.1.126'],
        const Assignment(
          alias: 'Ceiling dome light',
          roomTempId: 'sr-bedroom',
          fixture: Fixture.dome,
        ),
      );
      expect(s.setupRooms.last.name, 'Study');
      expect(s.setupRooms.last.custom, isTrue);
      expect(
        s.assignments['192.168.1.140']?.roomTempId,
        s.setupRooms.last.tempId,
      );
      expect(s.namesComplete, isTrue);
      expect(
        s.roomsToWrite,
        2,
        reason: 'Bedroom took a light, Study is custom; Living Room and Kitchen are dropped',
      );
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'finishing writes the home and reports the counts',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV'))
      ..add(const OnboardingFinished()),
    wait: _settled,
    verify: (bloc) async {
      var notice = bloc.state.notice;
      expect(notice, isA<OnboardingDone>());
      var done = notice! as OnboardingDone;
      expect(done.home.name, 'Kaverappa House');
      expect(done.home.subnet, '192.168.1');
      expect(done.lightCount, 2);
      expect(done.roomCount, 1, reason: 'both lights went to the Living Room');
      expect((await seed.settings.get()).activeHomeId, done.home.id);
      expect(await seed.lights.getByHome(done.home.id), hasLength(2));
      expect(
        seed.store.of((await seed.lights.getByMac(done.home.id, 'rgb'))!.id),
        LiveState.initial,
      );
      expect(
        bloc.state.finishing,
        isTrue,
        reason: 'the flow is over; Finish never runs twice',
      );
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'a second finish while the first is in flight is ignored',
    build: build,
    setUp: () => seed.lights.insertLatency = _slowWrite,
    act: (bloc) async {
      bloc
        ..add(const OnboardingNameChanged('Kaverappa House'))
        ..add(const OnboardingHomeCreated())
        ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
        ..add(
          const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'),
        )
        ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV'))
        ..add(const OnboardingFinished());
      await Future<void>.delayed(_slowWrite ~/ 2);
      expect(
        bloc.state.finishing,
        isTrue,
        reason: 'the write is still running',
      );
      bloc.add(const OnboardingFinished());
    },
    wait: _slowWrite * 3,
    verify: (bloc) async {
      var homes = await seed.homes.getAll();
      expect(homes, hasLength(1), reason: 'one home, not two');
      expect(await seed.lights.getByHome(homes.single.id), hasLength(2));
      expect(bloc.state.finishing, isTrue, reason: 'the flow is over');
      expect(bloc.state.notice, isA<OnboardingDone>());
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'a finish the domain refuses frees the button and says why',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV'))
      ..add(const OnboardingNameChanged('   '))
      ..add(const OnboardingFinished()),
    wait: _settled,
    verify: (bloc) async {
      expect(bloc.state.finishing, isFalse);
      expect(bloc.state.notice, const OnboardingError('A name is required.'));
      expect(await seed.homes.getAll(), isEmpty, reason: 'nothing was written');
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'a finish after one that succeeded writes nothing more',
    build: build,
    act: (bloc) async {
      bloc
        ..add(const OnboardingNameChanged('Kaverappa House'))
        ..add(const OnboardingHomeCreated())
        ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
        ..add(
          const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'),
        )
        ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV'))
        ..add(const OnboardingFinished());
      await Future<void>.delayed(_settled);
      expect(bloc.state.notice, isA<OnboardingDone>());
      bloc.add(const OnboardingFinished());
    },
    wait: _settled,
    verify: (bloc) async {
      var homes = await seed.homes.getAll();
      expect(
        homes,
        hasLength(1),
        reason:
            'each run of the use case writes a home of its own, so one '
            'home is one run',
      );
      expect(await seed.lights.getByHome(homes.single.id), hasLength(2));
      expect((bloc.state.notice! as OnboardingDone).home.id, homes.single.id);
      expect(bloc.state.finishing, isTrue);
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'a finish that fails outside the domain frees the button and says why',
    build: build,
    setUp: () => seed.lights.insertError = StateError('database closed'),
    act: (bloc) => bloc
      ..add(const OnboardingNameChanged('Kaverappa House'))
      ..add(const OnboardingHomeCreated())
      ..add(const OnboardingToNaming([_rgb, _plug], '192.168.1'))
      ..add(const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'))
      ..add(const OnboardingAliasChanged('192.168.1.140', 'Plug by the TV'))
      ..add(const OnboardingFinished()),
    wait: _settled,
    verify: (bloc) {
      expect(
        bloc.state.finishing,
        isFalse,
        reason: 'the flow is not stranded with Finish disabled',
      );
      expect(bloc.state.notice, isA<OnboardingError>());
      expect(
        (bloc.state.notice! as OnboardingError).message,
        contains('database closed'),
      );
    },
  );

  blocTest<OnboardingBloc, OnboardingState>(
    'a notice is cleared once the view has acted on it',
    build: build,
    act: (bloc) async {
      bloc
        ..add(const OnboardingNameChanged('Kaverappa House'))
        ..add(const OnboardingHomeCreated())
        ..add(const OnboardingToNaming([_rgb], '192.168.1'))
        ..add(
          const OnboardingAliasChanged('192.168.1.126', 'Ceiling dome light'),
        )
        ..add(const OnboardingFinished());
      await Future<void>.delayed(_settled);
      expect(bloc.state.notice, isA<OnboardingDone>());
      bloc.add(const OnboardingNoticeCleared());
    },
    verify: (bloc) => expect(bloc.state.notice, isNull),
  );
}
