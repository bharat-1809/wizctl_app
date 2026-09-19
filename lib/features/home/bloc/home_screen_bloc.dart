import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/home_repository.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/services/active_home.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'home_screen_event.dart';
import 'home_screen_state.dart';

/// The home overview (spec §8, §10.2): rooms with their counts, the whole
/// home's on/off summary, how many lights are not answering. Registers the
/// whole home as its poll scope while it is on show.
class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  final HomeRepository _homes;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final SettingsRepository _settings;
  final SetPower _setPower;
  final SyncCoordinator _sync;
  PollScope? _scope;

  HomeScreenBloc({
    required HomeRepository homes,
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required SettingsRepository settings,
    required SetPower setPower,
    required SyncCoordinator sync,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _setPower = setPower, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(HomeScreenState.initial) {
    on<HomeScreenSubscribed>(_onSubscribed);
    on<AllPowerToggled>(_onAllPower);
    on<RoomPowerToggled>(_onRoomPower);
    on<HomeRefreshRequested>((_, _) => _sync.refreshAll());
  }

  Future<void> _onSubscribed(
    HomeScreenSubscribed event,
    Emitter<HomeScreenState> emit,
  ) async {
    await emit.forEach(
      switchLatest(activeHomeIds(_settings), _forHome),
      onData: (s) => s,
    );
  }

  Stream<HomeScreenState> _forHome(String? homeId) {
    if (homeId == null) {
      _scope?.update(const {});
      return Stream.value(
        const HomeScreenState(
          status: HomeScreenStatus.noHome,
          home: null,
          rooms: [],
          lights: [],
        ),
      );
    }
    var home = _homes.watchAll().map((all) {
      for (var h in all) {
        if (h.id == homeId) return h;
      }
      return null;
    });
    return combineLatest4(
      home,
      _rooms.watchByHome(homeId),
      _lights.watchByHome(homeId),
      _store.watchAll(),
    ).map((tuple) {
      var (home, rooms, lights, states) = tuple;
      if (home == null) {
        return const HomeScreenState(
          status: HomeScreenStatus.noHome,
          home: null,
          rooms: [],
          lights: [],
        );
      }
      var live = <LiveLight>[
        for (var l in lights)
          (light: l, state: states[l.id] ?? LiveState.initial),
      ];
      (_scope ??= _sync.registerScope({})).update({for (var l in lights) l.id});
      return HomeScreenState(
        status: HomeScreenStatus.ready,
        home: home,
        rooms: [
          for (var room in rooms)
            RoomTile(
              room: room,
              lightCount: live.where((l) => l.light.roomId == room.id).length,
              onCount: live
                  .where((l) => l.light.roomId == room.id && l.state.isOn)
                  .length,
            ),
        ],
        lights: live,
      );
    });
  }

  Future<void> _onAllPower(
    AllPowerToggled event,
    Emitter<HomeScreenState> emit,
  ) async {
    var home = state.home;
    if (home == null) return;
    await _setPower(WholeHomeTarget(home.id), event.on);
  }

  Future<void> _onRoomPower(
    RoomPowerToggled event,
    Emitter<HomeScreenState> emit,
  ) => _setPower(RoomTarget(event.roomId), event.on);

  @override
  Future<void> close() {
    _scope?.dispose();
    return super.close();
  }
}
