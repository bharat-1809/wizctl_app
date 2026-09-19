import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/services/active_home.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/usecases/usecases.dart';
import 'rooms_list_event.dart';
import 'rooms_list_state.dart';

/// The Rooms tab (spec §8, §10.6): the active home's rooms with their
/// counts; add, rename and delete.
class RoomsListBloc extends Bloc<RoomsListEvent, RoomsListState> {
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final SettingsRepository _settings;
  final AddRoom _addRoom;
  final RenameRoom _renameRoom;
  final DeleteRoom _deleteRoom;

  RoomsListBloc({
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required SettingsRepository settings,
    required AddRoom addRoom,
    required RenameRoom renameRoom,
    required DeleteRoom deleteRoom,
  }) : _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _addRoom = addRoom, // ignore: prefer_initializing_formals
       _renameRoom = renameRoom, // ignore: prefer_initializing_formals
       _deleteRoom = deleteRoom, // ignore: prefer_initializing_formals
       super(RoomsListState.initial) {
    on<RoomsListSubscribed>(_onSubscribed);
    on<RoomAdded>(_onAdded);
    on<RoomRenamed>(_onRenamed);
    on<RoomDeleted>(_onDeleted);
    on<RoomsNoticeCleared>(
      (_, emit) => emit(state.copyWith(clearNotice: true)),
    );
  }

  Future<void> _onSubscribed(
    RoomsListSubscribed event,
    Emitter<RoomsListState> emit,
  ) async {
    await emit.forEach(
      // `switchLatest`, not `asyncExpand`: a repository watch never ends, so
      // an `asyncExpand` would pause on the first home and never read the
      // next one (`lib/core/util/latest.dart` says it in full).
      switchLatest(activeHomeIds(_settings), _forHome),
      // The list arrives from the streams; the notice is the bloc's own and
      // survives until the view has acted on it.
      onData: (next) => state.copyWith(
        status: next.status,
        homeId: next.homeId,
        rooms: next.rooms,
        lightCount: next.lightCount,
      ),
    );
  }

  Stream<RoomsListState> _forHome(String? homeId) {
    if (homeId == null) {
      return Stream.value(
        RoomsListState.initial.copyWith(status: RoomsListStatus.noHome),
      );
    }
    return combineLatest3(
      _rooms.watchByHome(homeId),
      _lights.watchByHome(homeId),
      _store.watchAll(),
    ).map((tuple) {
      var (rooms, lights, states) = tuple;
      bool isOn(Light l) => (states[l.id] ?? LiveState.initial).isOn;
      return RoomsListState(
        status: RoomsListStatus.ready,
        homeId: homeId,
        rooms: [
          for (var room in rooms)
            RoomRow(
              room: room,
              lightCount: lights.where((l) => l.roomId == room.id).length,
              onCount: lights
                  .where((l) => l.roomId == room.id && isOn(l))
                  .length,
            ),
        ],
        lightCount: lights.length,
      );
    });
  }

  Future<void> _onAdded(RoomAdded event, Emitter<RoomsListState> emit) async {
    var homeId = state.homeId;
    if (homeId == null) return;
    try {
      var room = await _addRoom(homeId, event.name, event.glyph);
      emit(state.copyWith(notice: RoomSavedNotice(room.name)));
    } on DomainException catch (e) {
      emit(state.copyWith(notice: RoomsError(e.message)));
    }
  }

  Future<void> _onRenamed(
    RoomRenamed event,
    Emitter<RoomsListState> emit,
  ) async {
    try {
      await _renameRoom(event.roomId, event.name);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: RoomsError(e.message)));
    }
  }

  Future<void> _onDeleted(
    RoomDeleted event,
    Emitter<RoomsListState> emit,
  ) async {
    try {
      await _deleteRoom(event.roomId);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: RoomsError(e.message)));
    }
  }
}
