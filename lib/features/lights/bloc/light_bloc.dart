import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../core/util/latest.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/light_repository.dart';
import '../../../domain/repositories/room_repository.dart';
import '../../../domain/services/live_state_store.dart';
import '../../../domain/services/mode_summarizer.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'light_event.dart';
import 'light_state.dart';

/// One light (spec §8, §10.4, §10.9): the detail screen on a phone and the
/// inspector on a desktop. Reads the bulb once when it opens (spec §5.8),
/// keeps it polled while on show, and owns its writes and edits.
class LightBloc extends Bloc<LightEvent, LightState> {
  final String lightId;
  final LightRepository _lights;
  final RoomRepository _rooms;
  final LiveStateStore _store;
  final SetPower _setPower;
  final SetBrightness _setBrightness;
  final SetKelvin _setKelvin;
  final SetSpeed _setSpeed;
  final SetFixture _setFixture;
  final RenameLight _renameLight;
  final ForgetLight _forgetLight;
  final SyncCoordinator _sync;
  PollScope? _scope;

  /// Set while this light's own forget is in flight, so the projection leaves
  /// announcing it to [_onForgotten]. Without it, whether the view saw a bare
  /// `gone` before the notice, or one state carrying both, would come down to
  /// which microtask ran first — and a view that leaves on either would leave
  /// twice. See [_onForgotten].
  bool _forgetting = false;

  LightBloc({
    required this.lightId,
    required LightRepository lights,
    required RoomRepository rooms,
    required LiveStateStore store,
    required SetPower setPower,
    required SetBrightness setBrightness,
    required SetKelvin setKelvin,
    required SetSpeed setSpeed,
    required SetFixture setFixture,
    required RenameLight renameLight,
    required ForgetLight forgetLight,
    required SyncCoordinator sync,
  }) : _lights = lights, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _setPower = setPower, // ignore: prefer_initializing_formals
       _setBrightness = setBrightness, // ignore: prefer_initializing_formals
       _setKelvin = setKelvin, // ignore: prefer_initializing_formals
       _setSpeed = setSpeed, // ignore: prefer_initializing_formals
       _setFixture = setFixture, // ignore: prefer_initializing_formals
       _renameLight = renameLight, // ignore: prefer_initializing_formals
       _forgetLight = forgetLight, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(LightState.initial) {
    on<LightSubscribed>(_onSubscribed);
    on<LightPowerChanged>((e, _) => _setPower(LightTarget(lightId), e.on));
    on<LightBrightnessChanged>(
      (e, _) => _setBrightness(LightTarget(lightId), e.value),
    );
    on<LightKelvinChanged>(
      (e, _) => _setKelvin(LightTarget(lightId), e.kelvin),
    );
    on<LightSpeedChanged>((e, _) => _setSpeed(LightTarget(lightId), e.speed));
    on<LightFixtureChanged>((e, _) => _setFixture(lightId, e.fixture));
    on<LightRenamed>(_onRenamed);
    on<LightForgotten>(_onForgotten);
    on<LightRetryRequested>((_, _) => _sync.refreshLight(lightId));
    on<LightNoticeCleared>(
      (_, emit) => emit(state.copyWith(clearNotice: true)),
    );
  }

  Future<void> _onSubscribed(
    LightSubscribed event,
    Emitter<LightState> emit,
  ) async {
    // Registered empty: the projection below sets the ids, so a light that
    // appears or disappears under the bloc joins or leaves the poll with it.
    _scope ??= _sync.registerScope(const {});
    unawaited(_sync.refreshLight(lightId));
    // The room is looked up once per room the light belongs to, rather than
    // followed: a light changes room rarely, and the lookup is skipped on
    // every other projection.
    Room? room;
    await emit.forEach(
      combineLatest2(_lights.watch(lightId), _store.watch(lightId)).asyncMap((
        tuple,
      ) async {
        var (light, live) = tuple;
        if (light != null && room?.id != light.roomId) {
          room = await _rooms.get(light.roomId);
        }
        return (light: light, live: live, room: room);
      }),
      onData: (next) {
        var light = next.light;
        if (light == null) {
          // This light's own forget says so itself, with the notice; anything
          // else (an unknown id, a light removed elsewhere) is gone from here.
          if (_forgetting) return state;
          _scope?.update(const {});
          return state.copyWith(status: LightStatus.gone);
        }
        _scope?.update({lightId});
        return state.copyWith(
          status: LightStatus.ready,
          light: light,
          room: next.room,
          live: next.live,
          summary: ModeSummarizer.summarize([(light: light, state: next.live)]),
        );
      },
    );
  }

  Future<void> _onRenamed(LightRenamed event, Emitter<LightState> emit) async {
    try {
      await _renameLight(lightId, event.name);
    } on DomainException catch (e) {
      emit(state.copyWith(notice: LightError(e.message)));
    }
  }

  /// Forgets the light and says so in one state: [LightStatus.gone] and the
  /// [LightForgottenNotice] together, with the last known light still on it
  /// so the notice can name it. The projection's own `gone` is suppressed
  /// while this runs, and the one that arrives after it is equal to what is
  /// emitted here, so the view is told exactly once.
  Future<void> _onForgotten(
    LightForgotten event,
    Emitter<LightState> emit,
  ) async {
    var name = state.light?.name;
    if (name == null) return;
    _forgetting = true;
    try {
      await _forgetLight(lightId);
      // Nothing is on show to poll any more.
      _scope?.update(const {});
      emit(
        state.copyWith(
          status: LightStatus.gone,
          notice: LightForgottenNotice(name),
        ),
      );
    } finally {
      _forgetting = false;
    }
  }

  @override
  Future<void> close() {
    _scope?.dispose();
    return super.close();
  }
}
