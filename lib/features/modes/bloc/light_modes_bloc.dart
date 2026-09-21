import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/services/capability_rules.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/usecases/usecases.dart';
import 'light_modes_event.dart';
import 'light_modes_state.dart';

/// The modes sheet and the Scenes tab (spec §8, §10.5): the target's lights
/// live, what is selected, and the four writes. One tap applies.
class LightModesBloc extends Bloc<LightModesEvent, LightModesState> {
  final RoomRepository _rooms;
  final LightRepository _lights;
  final LiveStateStore _store;
  final ApplyColour _applyColour;
  final ApplyWhite _applyWhite;
  final ApplyScene _applyScene;
  final SetSpeed _setSpeed;

  /// Every target the bloc is switched to. Single-subscription: the projection
  /// is its one listener. A [ModesTargetChanged] that lands before
  /// [ModesSubscribed] needs nothing from this controller — its handler has
  /// already put the target in `state.target`, which [_targetStream] yields
  /// first.
  final StreamController<ModeTarget> _targets = StreamController();

  /// [ModesSubscribed] is idempotent: a view that re-adds it on rebuild must
  /// not start a second projection, which would re-listen the
  /// single-subscription [_targets] and throw through `emit.forEach`.
  bool _subscribed = false;

  LightModesBloc({
    required ModeTarget target,
    required RoomRepository rooms,
    required LightRepository lights,
    required LiveStateStore store,
    required ApplyColour applyColour,
    required ApplyWhite applyWhite,
    required ApplyScene applyScene,
    required SetSpeed setSpeed,
  }) : _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _applyColour = applyColour, // ignore: prefer_initializing_formals
       _applyWhite = applyWhite, // ignore: prefer_initializing_formals
       _applyScene = applyScene, // ignore: prefer_initializing_formals
       _setSpeed = setSpeed, // ignore: prefer_initializing_formals
       super(
         LightModesState(
           status: ModesStatus.loading,
           target: target,
           targetName: null,
           tab: ModesTab.colour,
           lights: const [],
         ),
       ) {
    on<ModesSubscribed>(_onSubscribed);
    on<ModesTargetChanged>((event, emit) {
      // The old target's name and lights go with it: until the new projection
      // lands, a view must not read the previous room's name under this one.
      emit(
        state.copyWith(
          target: event.target,
          status: ModesStatus.loading,
          clearTargetName: true,
          lights: const [],
        ),
      );
      _targets.add(event.target);
    });
    on<ModesTabChanged>((event, emit) => emit(state.copyWith(tab: event.tab)));
    on<ColourPicked>(_onColour);
    on<WhitePicked>(_onWhite);
    on<ScenePicked>(_onScene);
    on<SpeedChanged>(_onSpeed);
    on<ModesNoticeCleared>(
      (_, emit) => emit(state.copyWith(clearNotice: true)),
    );
  }

  /// The target the bloc was built with, then every one it is switched to.
  Stream<ModeTarget> _targetStream() async* {
    yield state.target;
    yield* _targets.stream;
  }

  Future<void> _onSubscribed(
    ModesSubscribed event,
    Emitter<LightModesState> emit,
  ) async {
    if (_subscribed) return;
    _subscribed = true;
    await emit.forEach(
      // `switchLatest`, not `asyncExpand`: a repository watch never ends, so
      // an `asyncExpand` would pause on the first target and never read the
      // next one (`lib/core/util/latest.dart` says it in full).
      switchLatest(_targetStream(), _forTarget),
      // Field by field, not whole: the notice and the tab are the bloc's own
      // and the streams know nothing about them.
      onData: (next) => state.copyWith(
        status: ModesStatus.ready,
        target: next.target,
        targetName: next.name,
        clearTargetName: next.name == null,
        lights: next.lights,
      ),
    );
  }

  Stream<({ModeTarget target, String? name, List<LiveLight> lights})>
  _forTarget(ModeTarget target) {
    Stream<List<Light>> lights;
    Future<String?> name;
    switch (target) {
      case WholeHomeTarget(:var homeId):
        lights = _lights.watchByHome(homeId);
        name = Future.value(null);
      case RoomTarget(:var roomId):
        lights = _lights.watchByRoom(roomId);
        name = _rooms.get(roomId).then((r) => r?.name);
      case LightTarget(:var lightId):
        lights = _lights.watch(lightId).map((l) => [?l]);
        name = _lights.get(lightId).then((l) => l?.name);
    }
    // One value, so `asyncExpand` is the right operator here: it hands over
    // to the live projection once the name has been read, and never has a
    // second outer value to pause on.
    return Stream.fromFuture(name).asyncExpand(
      (name) => combineLatest2(lights, _store.watchAll()).map((tuple) {
        var (list, states) = tuple;
        return (
          target: target,
          name: name,
          lights: [
            for (var l in list)
              (light: l, state: states[l.id] ?? LiveState.initial),
          ],
        );
      }),
    );
  }

  Future<void> _onColour(
    ColourPicked event,
    Emitter<LightModesState> emit,
  ) async {
    var written = await _applyColour(state.target, event.rgb);
    if (written == 0) emit(state.copyWith(notice: const NoColourNotice()));
  }

  Future<void> _onWhite(
    WhitePicked event,
    Emitter<LightModesState> emit,
  ) async {
    var written = await _applyWhite(state.target, event.kelvin);
    if (written == 0) emit(state.copyWith(notice: const NoWhiteNotice()));
  }

  Future<void> _onScene(
    ScenePicked event,
    Emitter<LightModesState> emit,
  ) async {
    var speed = CapabilityRules.isDynamicScene(event.sceneId)
        ? state.speed
        : null;
    var written = await _applyScene(state.target, event.sceneId, speed: speed);
    if (written == 0) {
      emit(state.copyWith(notice: const NoSceneNotice()));
      return;
    }
    emit(
      state.copyWith(
        notice: SceneAppliedNotice(
          ModeSummarizer.sceneName(event.sceneId),
          state.target,
          state.targetName,
        ),
      ),
    );
  }

  Future<void> _onSpeed(SpeedChanged event, Emitter<LightModesState> emit) =>
      _setSpeed(state.target, event.speed);

  @override
  Future<void> close() {
    // Not awaited: a single-subscription controller's `close()` future only
    // completes once the done event has been *delivered*, so awaiting it on a
    // bloc closed before `ModesSubscribed` ever subscribed never returns —
    // measured, it hung `close()` for good. Closing detaches the controller
    // either way; `super.close()` cancels the projection.
    unawaited(_targets.close());
    return super.close();
  }
}
