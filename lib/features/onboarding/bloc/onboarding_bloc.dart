import 'package:bloc/bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/id_generator.dart';
import '../../../domain/usecases/usecases.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// The first run (spec §8, §10.1): the draft name, the kept lights and
/// what each becomes, written as one home at the end.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final FinishOnboarding _finish;
  final IdGenerator _ids;

  OnboardingBloc({
    required FinishOnboarding finishOnboarding,
    required IdGenerator ids,
  }) : _finish = finishOnboarding, // ignore: prefer_initializing_formals
       _ids = ids, // ignore: prefer_initializing_formals
       super(OnboardingState.initial) {
    on<OnboardingNameChanged>(
      (e, emit) => emit(state.copyWith(draftName: e.name)),
    );
    on<OnboardingHomeCreated>((_, emit) {
      if (state.nameEmpty) return;
      emit(state.copyWith(step: OnboardingStep.discovering));
    });
    on<OnboardingBack>((_, emit) {
      emit(
        state.copyWith(
          step: switch (state.step) {
            OnboardingStep.nameHome => OnboardingStep.nameHome,
            OnboardingStep.discovering => OnboardingStep.nameHome,
            OnboardingStep.nameLights => OnboardingStep.discovering,
          },
        ),
      );
    });
    on<OnboardingToNaming>(_onToNaming);
    on<OnboardingAliasChanged>(
      (e, emit) => _assign(emit, e.ip, (a) => a.copyWith(alias: e.alias)),
    );
    on<OnboardingRoomPicked>((e, emit) {
      // An assignment only ever names a room that exists: a pick from a list
      // the state has moved past is dropped rather than left pointing at
      // nothing, where the write would quietly lose the light.
      if (!state.setupRooms.any((r) => r.tempId == e.roomTempId)) return;
      _assign(emit, e.ip, (a) => a.copyWith(roomTempId: e.roomTempId));
    });
    on<OnboardingFixturePicked>(
      (e, emit) => _assign(emit, e.ip, (a) => a.copyWith(fixture: e.fixture)),
    );
    on<OnboardingRoomAdded>(_onRoomAdded);
    on<OnboardingFinished>(_onFinished);
    on<OnboardingNoticeCleared>(
      (_, emit) => emit(state.copyWith(clearNotice: true)),
    );
  }

  void _onToNaming(OnboardingToNaming event, Emitter<OnboardingState> emit) {
    var kept = event.kept.where((f) => f.kept).toList();
    var first = state.setupRooms.first.tempId;
    emit(
      state.copyWith(
        step: OnboardingStep.nameLights,
        kept: kept,
        subnet: event.subnet,
        assignments: {
          for (var f in kept)
            f.device.ip:
                state.assignments[f.device.ip] ??
                Assignment(
                  alias: '',
                  roomTempId: first,
                  fixture: Fixture.defaultFor(f.device.bulbClass),
                ),
        },
      ),
    );
  }

  void _assign(
    Emitter<OnboardingState> emit,
    String ip,
    Assignment Function(Assignment current) change,
  ) {
    var current = state.assignments[ip];
    if (current == null) return;
    emit(
      state.copyWith(assignments: {...state.assignments, ip: change(current)}),
    );
  }

  void _onRoomAdded(OnboardingRoomAdded event, Emitter<OnboardingState> emit) {
    var name = event.name.trim();
    if (name.isEmpty) return;
    var room = OnboardingRoom(
      tempId: 'sr-${_ids.next()}',
      name: name,
      glyph: event.glyph,
      custom: true,
    );
    var assignments = state.assignments;
    var forIp = event.forIp;
    if (forIp != null && assignments[forIp] != null) {
      assignments = {
        ...assignments,
        forIp: assignments[forIp]!.copyWith(roomTempId: room.tempId),
      };
    }
    emit(
      state.copyWith(
        setupRooms: [...state.setupRooms, room],
        assignments: assignments,
      ),
    );
  }

  Future<void> _onFinished(
    OnboardingFinished event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.namesComplete || state.finishing) return;
    // The previous attempt's notice goes with it: a retry that is refused for
    // the same reason must still read as a new notice to a listener watching
    // for one to change.
    emit(state.copyWith(finishing: true, clearNotice: true));
    var lights = [
      for (var f in state.kept)
        OnboardingLight(
          device: f.device,
          alias: state.assignments[f.device.ip]!.alias,
          roomTempId: state.assignments[f.device.ip]!.roomTempId,
          fixture: state.assignments[f.device.ip]!.fixture,
          initial: f.initial,
        ),
    ];
    // Counted before the write, from the same lists the use case is given: a
    // room added while the write is in flight must not inflate what the
    // notice reports.
    var roomCount = state.roomsToWrite;
    try {
      var home = await _finish(
        OnboardingResult(
          homeName: state.draftName,
          subnet: state.subnet,
          rooms: state.setupRooms,
          lights: lights,
        ),
      );
      // [OnboardingState.finishing] stays true: the first run is over, so the
      // guard above turns a repeat [OnboardingFinished] into a no-op rather
      // than a second home.
      emit(
        state.copyWith(notice: OnboardingDone(home, lights.length, roomCount)),
      );
    } on DomainException catch (e) {
      // The domain's own line, already written for the user.
      emit(
        state.copyWith(finishing: false, notice: OnboardingError(e.message)),
      );
    } catch (e) {
      // Anything the domain did not model — a closed database, a platform
      // channel that went away. Whatever it was, the flow must not be left
      // stranded with Finish disabled over it, so it is reported like any
      // other refusal and can be tried again.
      emit(state.copyWith(finishing: false, notice: OnboardingError('$e')));
    }
  }
}
