import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/app/blocs/homes_bloc.dart';
import 'package:wizctl_app/app/blocs/homes_event.dart';
import 'package:wizctl_app/app/blocs/homes_state.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';
import '../../support/seed.dart';

void main() {
  late SeedHome seed;

  HomesBloc build() => HomesBloc(
    homes: seed.homes,
    rooms: seed.rooms,
    lights: seed.lights,
    settings: seed.settings,
    createHome: CreateHome(
      homes: seed.homes,
      settings: seed.settings,
      ids: SequenceIds(),
      clock: FakeClock(),
    ),
    switchHome: SwitchHome(settings: seed.settings),
    renameHome: RenameHome(homes: seed.homes),
    deleteHome: DeleteHome(homes: seed.homes, settings: seed.settings),
  );

  setUp(() {
    seed = SeedHome();
    addTearDown(seed.dispose);
  });

  test('the snapshot state routes before anything is subscribed', () {
    var state = HomesState.snapshot([], AppSettings.defaults);
    expect(state.hasHome, isFalse);
    expect(state.status, HomesStatus.loading);
    var ready = HomesState.snapshot([
      seed.home,
    ], const AppSettings(activeHomeId: 'h1'));
    expect(ready.hasHome, isTrue);
    expect(ready.activeHome, seed.home);
  });

  blocTest<HomesBloc, HomesState>(
    'subscribing lists every home with its counts and the active one',
    build: build,
    act: (bloc) => bloc.add(const HomesSubscribed()),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, HomesStatus.ready);
      expect(s.activeHomeId, 'h1');
      expect(s.activeHome?.name, 'Kaverappa House');
      expect(s.homes.map((h) => h.home.id), ['h1', 'h2']);
      expect(s.homes.first.roomCount, 3);
      expect(s.homes.first.lightCount, 6);
      expect(s.homes.last.roomCount, 1);
      expect(s.homes.last.lightCount, 1);
    },
  );

  blocTest<HomesBloc, HomesState>(
    'the active home\'s counts follow its rooms and lights',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await seed.rooms.insert(
        const Room(
          id: 'garage',
          homeId: 'h1',
          name: 'Garage',
          glyph: RoomGlyph.trees,
          sortIndex: 3,
        ),
      );
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) => expect(bloc.state.homes.first.roomCount, 4),
  );

  blocTest<HomesBloc, HomesState>(
    'creating a home activates it and raises the created notice',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeCreated('Cabin'));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      var s = bloc.state;
      expect(s.homes.map((h) => h.home.name), contains('Cabin'));
      expect(s.activeHome?.name, 'Cabin');
      expect(s.notice, isA<HomeCreatedNotice>());
      expect((s.notice! as HomeCreatedNotice).home.name, 'Cabin');
    },
  );

  blocTest<HomesBloc, HomesState>(
    'an empty name is an error notice, not a home',
    build: build,
    act: (bloc) => bloc
      ..add(const HomesSubscribed())
      ..add(const HomeCreated('   ')),
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.homes, hasLength(2));
      expect(bloc.state.notice, const HomesError('A name is required.'));
    },
  );

  blocTest<HomesBloc, HomesState>(
    'switching, renaming and clearing the notice',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeSwitched('h2'));
      bloc.add(const HomeRenamed('h2', 'Loft'));
      bloc.add(const HomeCreated(''));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomesNoticeCleared());
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.activeHomeId, 'h2');
      expect(bloc.state.activeHome?.name, 'Loft');
      expect(bloc.state.notice, isNull);
    },
  );

  blocTest<HomesBloc, HomesState>(
    'the last home cannot be deleted',
    build: build,
    act: (bloc) async {
      bloc.add(const HomesSubscribed());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeDeleted('h2'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const HomeDeleted('h1'));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.homes.map((h) => h.home.id), ['h1']);
      expect(bloc.state.notice, isA<HomesError>());
    },
  );
}
