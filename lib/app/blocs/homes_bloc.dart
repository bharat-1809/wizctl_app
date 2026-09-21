import 'package:bloc/bloc.dart';

import '../../core/util/latest.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/light_repository.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/services/active_home.dart';
import '../../domain/usecases/usecases.dart';
import 'homes_event.dart';
import 'homes_state.dart';

/// Every home on this device and which one is active (spec §8).
///
/// The active home's counts are live (its rooms and lights are what the
/// user is editing); the others are read once per emission, since nothing
/// changes in a home that is not active.
class HomesBloc extends Bloc<HomesEvent, HomesState> {
  final HomeRepository _homes;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final SettingsRepository _settings;
  final CreateHome _createHome;
  final SwitchHome _switchHome;
  final RenameHome _renameHome;
  final DeleteHome _deleteHome;

  HomesBloc({
    required HomeRepository homes,
    required RoomRepository rooms,
    required LightRepository lights,
    required SettingsRepository settings,
    required CreateHome createHome,
    required SwitchHome switchHome,
    required RenameHome renameHome,
    required DeleteHome deleteHome,
    HomesState? initial,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _createHome = createHome, // ignore: prefer_initializing_formals
       _switchHome = switchHome, // ignore: prefer_initializing_formals
       _renameHome = renameHome, // ignore: prefer_initializing_formals
       _deleteHome = deleteHome, // ignore: prefer_initializing_formals
       super(
         initial ??
             const HomesState(
               status: HomesStatus.loading,
               homes: [],
               activeHomeId: null,
             ),
       ) {
    on<HomesSubscribed>(_onSubscribed);
    on<HomeCreated>(_onCreated);
    on<HomeSwitched>(_onSwitched);
    on<HomeRenamed>(_onRenamed);
    on<HomeDeleted>(_onDeleted);
    on<HomesNoticeCleared>(
      (_, emit) => emit(state.copyWith(clearNotice: true)),
    );
  }

  Future<void> _onSubscribed(
    HomesSubscribed event,
    Emitter<HomesState> emit,
  ) async {
    await emit.forEach(
      switchLatest(activeHomeIds(_settings), _forActive),
      onData: (next) => state.copyWith(
        status: HomesStatus.ready,
        homes: next.homes,
        activeHomeId: next.activeHomeId,
        clearActiveHome: next.activeHomeId == null,
      ),
    );
  }

  /// Homes with counts, the active one's counts following its rooms and
  /// lights.
  Stream<({List<HomeSummary> homes, String? activeHomeId})> _forActive(
    String? activeId,
  ) {
    var rooms = activeId == null
        ? Stream.value(const <Room>[])
        : _rooms.watchByHome(activeId);
    var lights = activeId == null
        ? Stream.value(const <Light>[])
        : _lights.watchByHome(activeId);
    return combineLatest3(_homes.watchAll(), rooms, lights).asyncMap((
      tuple,
    ) async {
      var (all, activeRooms, activeLights) = tuple;
      var summaries = <HomeSummary>[];
      for (var home in all) {
        if (home.id == activeId) {
          summaries.add(
            HomeSummary(
              home: home,
              roomCount: activeRooms.length,
              lightCount: activeLights.length,
            ),
          );
        } else {
          summaries.add(
            HomeSummary(
              home: home,
              roomCount: (await _rooms.getByHome(home.id)).length,
              lightCount: (await _lights.getByHome(home.id)).length,
            ),
          );
        }
      }
      return (homes: summaries, activeHomeId: activeId);
    });
  }

  Future<void> _onCreated(HomeCreated event, Emitter<HomesState> emit) async {
    try {
      var home = await _createHome(event.name);
      emit(state.copyWith(notice: HomeCreatedNotice(home)));
    } on DomainException catch (e) {
      emit(state.copyWith(notice: HomesError(e.message)));
    }
  }

  Future<void> _onSwitched(HomeSwitched event, Emitter<HomesState> emit) =>
      _switchHome(event.homeId);

  Future<void> _onRenamed(HomeRenamed event, Emitter<HomesState> emit) async {
    try {
      await _renameHome(event.homeId, event.name);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: HomesError(e.message)));
    }
  }

  Future<void> _onDeleted(HomeDeleted event, Emitter<HomesState> emit) async {
    try {
      await _deleteHome(event.homeId);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: HomesError(e.message)));
    }
  }
}
