import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/services/sync_coordinator.dart';
import '../../../domain/usecases/usecases.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// The discovery run (spec §5.7, §8, §10.8): drives `RunDiscovery`,
/// pauses polling while it runs, keeps what answered, saves rows into the
/// home, and teaches the home its subnet the first time a run finds a light
/// on it (spec §5.7.5).
///
/// With no [homeId] (onboarding) nothing is probed, nothing is already
/// saved and saving is not offered; the kept rows are handed to
/// `OnboardingBloc` instead. [onboarding] on its own only skips the probe:
/// onboarding shows every device on the network, not the ones a home
/// already knows.
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final String? homeId;
  final bool onboarding;
  final RunDiscovery _run;
  final SaveDiscoveredLight _save;
  final LearnHomeSubnet _learn;
  final SyncCoordinator _sync;
  StreamSubscription<DiscoveryUpdate>? _subscription;
  DiscoveryMode? _mode;

  /// Whether this bloc is the one holding polling down. Pausing and
  /// resuming are not counted by [SyncCoordinator] — a second resume would
  /// let the poll tick into a run that is still going, and a resume with no
  /// run to match it would do the same on the next screen. The flag makes
  /// the pair symmetric however a run ends: finished, cancelled, or closed
  /// under the user.
  bool _pausedPolling = false;

  DiscoveryBloc({
    this.homeId,
    this.onboarding = false,
    required RunDiscovery runDiscovery,
    required SaveDiscoveredLight saveDiscoveredLight,
    required LearnHomeSubnet learnHomeSubnet,
    required SyncCoordinator sync,
  }) : _run = runDiscovery, // ignore: prefer_initializing_formals
       _save = saveDiscoveredLight, // ignore: prefer_initializing_formals
       _learn = learnHomeSubnet, // ignore: prefer_initializing_formals
       _sync = sync, // ignore: prefer_initializing_formals
       super(DiscoveryState.initial) {
    on<DiscoveryStarted>((_, emit) => _start(DiscoveryMode.quick, emit));
    on<DiscoverySweepRequested>((_, emit) => _start(DiscoveryMode.sweep, emit));
    on<DiscoveryCancelled>(_onCancelled);
    on<DiscoveryUpdateReceived>(_onUpdate);
    on<DiscoveryRunEnded>(_onEnded);
    on<DiscoveryKeepToggled>(_onKeep);
    on<DiscoverySaveRequested>(_onSave);
    on<DiscoveryNoticeCleared>(
      (_, emit) => emit(state.copyWith(clearNotice: true)),
    );
  }

  /// Whether the known addresses are worth probing first: a home to take
  /// them from, and a run that is not onboarding's.
  bool get _probesKnown => homeId != null && !onboarding;

  void _start(DiscoveryMode mode, Emitter<DiscoveryState> emit) {
    // A run already going is dropped, not joined: its rows belong to the
    // scan the user has just replaced. Cancelling means no `onDone`, so it
    // raises no [DiscoveryRunEnded] and polling stays paused for the new one.
    unawaited(_subscription?.cancel());
    _mode = mode;
    _pausePolling();
    emit(
      state.copyWith(
        view: switch (mode) {
          DiscoveryMode.sweep => DiscoveryView.sweeping,
          DiscoveryMode.quick when _probesKnown => DiscoveryView.probingKnown,
          DiscoveryMode.quick => DiscoveryView.broadcasting,
        },
        found: const [],
        clearProgress: true,
        clearFailure: true,
        failedRanges: const [],
      ),
    );
    _subscription = _run(homeId: homeId, mode: mode, probeKnown: _probesKnown)
        .listen(
          (update) => _feed(DiscoveryUpdateReceived(update)),
          onError: (Object error) => _feed(
            DiscoveryUpdateReceived(
              DiscoveryFailed(UnreachableFailure('', '$error')),
            ),
          ),
          onDone: () => _feed(const DiscoveryRunEnded()),
        );
  }

  /// The running stream talks to this bloc through its own event queue, so
  /// every update takes the same path as a tap. A bloc closed under a run
  /// that is still winding down takes nothing more.
  void _feed(DiscoveryEvent event) {
    if (!isClosed) add(event);
  }

  void _pausePolling() {
    if (_pausedPolling) return;
    _pausedPolling = true;
    _sync.pauseForDiscovery();
  }

  void _resumePolling() {
    if (!_pausedPolling) return;
    _pausedPolling = false;
    _sync.resumeAfterDiscovery();
  }

  Future<void> _onCancelled(
    DiscoveryCancelled event,
    Emitter<DiscoveryState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    _resumePolling();
    if (state.isScanning) {
      emit(
        state.copyWith(
          view: state.found.isEmpty ? DiscoveryView.idle : DiscoveryView.found,
        ),
      );
    }
  }

  void _onUpdate(DiscoveryUpdateReceived event, Emitter<DiscoveryState> emit) {
    switch (event.update) {
      case PhaseChanged(:var progress):
        emit(
          state.copyWith(
            view: switch (progress.phase) {
              DiscoveryPhase.probingKnown => DiscoveryView.probingKnown,
              DiscoveryPhase.broadcasting => DiscoveryView.broadcasting,
              DiscoveryPhase.sweeping => DiscoveryView.sweeping,
            },
            progress: progress,
            subnet: progress.subnet,
          ),
        );
      case DeviceFound(:var device, :var initial):
        emit(
          state.copyWith(
            found: [
              ...state.found,
              FoundDevice(device: device, initial: initial),
            ],
          ),
        );
      case DeviceUpdated(:var device):
        emit(
          state.copyWith(
            found: [
              for (var f in state.found)
                f.device.mac == device.mac ? f.copyWith(device: device) : f,
            ],
          ),
        );
      case DiscoveryFinished(:var devices, :var subnet, :var failedRanges):
        // The run's own list is the final one, in its order.
        var byMac = {for (var f in state.found) f.device.mac: f};
        var found = [for (var d in devices) _merge(byMac[d.mac], d)];
        emit(
          state.copyWith(
            view: found.isEmpty ? DiscoveryView.empty : DiscoveryView.found,
            found: found,
            subnet: subnet,
            sweptOnce: state.sweptOnce || _mode == DiscoveryMode.sweep,
            failedRanges: failedRanges,
          ),
        );
        var home = homeId;
        // Only a run that found something teaches the home its subnet.
        // `LearnHomeSubnet` never overwrites, so one empty scan on a guest
        // network would otherwise latch the wrong subnet for good.
        if (home != null && subnet != null && devices.isNotEmpty) {
          unawaited(_learn(home, subnet));
        }
      case DiscoveryFailed(:var failure):
        emit(state.copyWith(view: DiscoveryView.error, failure: failure));
    }
  }

  void _onEnded(DiscoveryRunEnded event, Emitter<DiscoveryState> emit) {
    _subscription = null;
    _resumePolling();
    if (state.isScanning) {
      // The stream closed without a Finished: treat what arrived as final.
      emit(
        state.copyWith(
          view: state.found.isEmpty ? DiscoveryView.empty : DiscoveryView.found,
        ),
      );
    }
  }

  /// The run's final record of a device laid over the row the screen already
  /// has. The row keeps its first read and the keep/drop the user has made,
  /// and a save made while the scan was still running keeps its mark: the
  /// run enriched its own copy of the device before that save happened, so
  /// its [DiscoveredDevice.alreadySaved] is the older answer of the two.
  static FoundDevice _merge(FoundDevice? row, DiscoveredDevice device) =>
      row == null
      ? FoundDevice(device: device)
      : row.copyWith(
          device: device.copyWith(
            alreadySaved: device.alreadySaved || row.device.alreadySaved,
          ),
        );

  void _onKeep(DiscoveryKeepToggled event, Emitter<DiscoveryState> emit) {
    emit(
      state.copyWith(
        found: [
          for (var f in state.found)
            f.device.ip == event.ip ? f.copyWith(kept: !f.kept) : f,
        ],
      ),
    );
  }

  Future<void> _onSave(
    DiscoverySaveRequested event,
    Emitter<DiscoveryState> emit,
  ) async {
    var home = homeId;
    FoundDevice? row;
    for (var f in state.found) {
      if (f.device.ip == event.ip) row = f;
    }
    // Onboarding has no home yet, so there is nothing to save into; a row
    // the run has since dropped is not saved either.
    if (home == null || row == null) return;
    emit(state.copyWith(saving: {...state.saving, event.ip: event.alias}));
    try {
      await _save(
        homeId: home,
        roomId: event.roomId,
        device: row.device,
        alias: event.alias,
        fixture: event.fixture,
        initial: row.initial,
      );
      emit(
        state.copyWith(
          found: [
            for (var f in state.found)
              f.device.ip == event.ip
                  ? f.copyWith(device: f.device.copyWith(alreadySaved: true))
                  : f,
          ],
          saving: {...state.saving}..remove(event.ip),
          notice: LightSavedNotice(event.alias, event.ip),
        ),
      );
    } on DomainException catch (e) {
      emit(
        state.copyWith(
          saving: {...state.saving}..remove(event.ip),
          notice: SaveFailedNotice(e.message),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _resumePolling();
    return super.close();
  }
}
