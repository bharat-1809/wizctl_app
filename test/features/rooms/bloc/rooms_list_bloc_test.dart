import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_bloc.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_event.dart';
import 'package:wizctl_app/features/rooms/bloc/rooms_list_state.dart';

import '../../../support/fakes.dart';
import '../../../support/seed.dart';

void main() {
  late SeedHome seed;

  RoomsListBloc build() => RoomsListBloc(
    rooms: seed.rooms,
    lights: seed.lights,
    store: seed.store,
    settings: seed.settings,
    addRoom: AddRoom(rooms: seed.rooms, ids: SequenceIds()),
    renameRoom: RenameRoom(rooms: seed.rooms),
    deleteRoom: DeleteRoom(rooms: seed.rooms, lights: seed.lights),
  );

  setUp(() {
    seed = SeedHome();
    addTearDown(seed.dispose);
  });

  const wait = Duration(milliseconds: 10);

  blocTest<RoomsListBloc, RoomsListState>(
    'lists the active home\'s rooms with their counts',
    build: build,
    act: (bloc) => bloc.add(const RoomsListSubscribed()),
    wait: wait,
    verify: (bloc) {
      var s = bloc.state;
      expect(s.status, RoomsListStatus.ready);
      expect(s.homeId, 'h1');
      expect(s.rooms.map((r) => r.room.name), [
        'Living Room',
        'Bedroom',
        'Kitchen',
      ]);
      expect(s.rooms.map((r) => r.lightCount), [3, 2, 1]);
      expect(s.rooms.map((r) => r.onCount), [2, 0, 1]);
      expect(s.lightCount, 6);
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'adding a room appends it and raises the saved notice',
    build: build,
    act: (bloc) async {
      bloc.add(const RoomsListSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomAdded('Study', RoomGlyph.lampDesk));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.rooms.last.room.name, 'Study');
      expect(bloc.state.rooms.last.room.glyph, RoomGlyph.lampDesk);
      expect(bloc.state.rooms.last.room.sortIndex, 3);
      expect(bloc.state.notice, const RoomSavedNotice('Study'));
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'renaming keeps the glyph and the order',
    build: build,
    act: (bloc) async {
      bloc.add(const RoomsListSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomRenamed('bedroom', 'Master bedroom'));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.rooms[1].room.name, 'Master bedroom');
      expect(bloc.state.rooms[1].room.glyph, RoomGlyph.bed);
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'a room with lights refuses to go; an empty one goes',
    build: build,
    act: (bloc) async {
      bloc.add(const RoomsListSubscribed());
      await Future<void>.delayed(wait);
      bloc.add(const RoomDeleted('living'));
      await Future<void>.delayed(wait);
      bloc.add(const RoomAdded('Garage', RoomGlyph.trees));
      await Future<void>.delayed(wait);
      bloc.add(const RoomsNoticeCleared());
      bloc.add(RoomDeleted(bloc.state.rooms.last.room.id));
    },
    wait: wait,
    verify: (bloc) {
      expect(bloc.state.rooms.map((r) => r.room.name), [
        'Living Room',
        'Bedroom',
        'Kitchen',
      ]);
      expect(bloc.state.notice, isNull);
    },
  );

  blocTest<RoomsListBloc, RoomsListState>(
    'the refusal is an error notice with the spec\'s line',
    build: build,
    act: (bloc) => bloc
      ..add(const RoomsListSubscribed())
      ..add(const RoomDeleted('living')),
    wait: wait,
    verify: (bloc) =>
        expect(bloc.state.notice, const RoomsError('Move its lights first.')),
  );
}
