import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/room_aggregates.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'room_event.dart';
import 'room_state.dart';

/// One room (spec §8, §10.3): its lights live, the whole-room numbers and
/// note, the mode summary; the whole-room and per-light writes. Registers
/// the room as its poll scope while on show.
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final String roomId;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final SetPower _setPower;
  final SetBrightness _setBrightness;
  final SetKelvin _setKelvin;
  final SyncCoordinator _sync;
  PollScope? _scope;

  RoomBloc({
    required this.roomId,
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required SetPower setPower,
    required SetBrightness setBrightness,
    required SetKelvin setKelvin,
    required SyncCoordinator sync,
  }) : _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _setPower = setPower, // ignore: prefer_initializing_formals
       _setBrightness = setBrightness, // ignore: prefer_initializing_formals
       _setKelvin = setKelvin, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(RoomState.initial) {
    on<RoomSubscribed>(_onSubscribed);
    on<RoomBrightnessChanged>(
      (e, _) => _setBrightness(RoomTarget(roomId), e.value),
    );
    on<RoomKelvinChanged>((e, _) => _setKelvin(RoomTarget(roomId), e.kelvin));
    on<RoomPowerToggled>((e, _) => _setPower(RoomTarget(roomId), e.on));
    on<RoomLightPowerToggled>(
      (e, _) => _setPower(LightTarget(e.lightId), e.on),
    );
    on<RoomLightBrightnessChanged>(
      (e, _) => _setBrightness(LightTarget(e.lightId), e.value),
    );
    on<RoomRefreshRequested>(_onRefresh);
  }

  Future<void> _onSubscribed(
    RoomSubscribed event,
    Emitter<RoomState> emit,
  ) async {
    // The repository has no per-room stream, so the room is found once and
    // then followed through its home's list (a rename lands that way).
    var room = Stream.fromFuture(_rooms.get(roomId)).asyncExpand(
      (found) => found == null
          ? Stream.value(null)
          : _rooms.watchByHome(found.homeId).map((all) {
              for (var r in all) {
                if (r.id == roomId) return r;
              }
              return null;
            }),
    );
    await emit.forEach(
      combineLatest3(room, _lights.watchByRoom(roomId), _store.watchAll()),
      onData: (tuple) {
        var (room, lights, states) = tuple;
        if (room == null) {
          // The room is gone (or never was). Its lights are no longer on
          // show, so the scope must let go of them too.
          _scope?.update(const {});
          return const RoomState(
            status: RoomStatus.gone,
            room: null,
            lights: [],
            aggregates: null,
            summary: ModeSummary.nothingSet,
          );
        }
        var live = [
          for (var l in lights)
            (light: l, state: states[l.id] ?? LiveState.initial),
        ];
        (_scope ??= _sync.registerScope(
          {},
        )).update({for (var l in lights) l.id});
        return RoomState(
          status: RoomStatus.ready,
          room: room,
          lights: live,
          aggregates: RoomAggregates.of(live),
          summary: ModeSummarizer.summarize(live),
        );
      },
    );
  }

  /// Reads every light of the home now, and tells the requester when that has
  /// finished.
  ///
  /// `done` completes in a `finally`, so a pull-to-refresh lets its loader go
  /// whether the read landed or threw — all the view is waiting for is the
  /// end of it. An error still leaves by the same door it did before, up to
  /// the bloc's error handler.
  Future<void> _onRefresh(
    RoomRefreshRequested event,
    Emitter<RoomState> emit,
  ) async {
    var done = event.done;
    try {
      await _sync.refreshAll();
    } finally {
      if (done != null && !done.isCompleted) done.complete();
    }
  }

  @override
  Future<void> close() {
    _scope?.dispose();
    return super.close();
  }
}
