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

  /// Stops the run the user is looking at.
  ///
  /// The view answers **first**, before the stream is wound down: cancelling
  /// an `async*` generator that is mid-read does not complete until that read
  /// does, and the user should not go on waiting for a bulb they have just
  /// stopped waiting for. `progress` is left where it stopped.
  ///
  /// Polling resumes only if no new run has been installed while the cancel
  /// was in flight. A `DiscoveryStarted` or `DiscoverySweepRequested` that
  /// arrives during the await takes over the pause from here, and resuming
  /// would let the poll tick into a scan that is still going.
  Future<void> _onCancelled(
    DiscoveryCancelled event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state.isScanning) {
      emit(
        state.copyWith(
          view: state.found.isEmpty ? DiscoveryView.idle : DiscoveryView.found,
        ),
      );
    }
    var running = _subscription;
    _subscription = null;
    await running?.cancel();
    if (_subscription == null) _resumePolling();
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
          unawaited(_learnQuietly(home, subnet));
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

  /// Teaching the home its subnet is best effort: the run has already given
  /// the user what they asked for, and a write that fails has nothing to say
  /// to them. Swallowed here rather than left to `unawaited`, where it would
  /// surface as an unhandled asynchronous error and take the app with it.
  Future<void> _learnQuietly(String homeId, String subnet) async {
    try {
      await _learn(homeId, subnet);
    } catch (_) {
      // The home simply has not learned its subnet yet; the next run tries
      // again. There is no notice, because there is nothing to act on.
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
    var saved = false;
    DiscoveryNotice notice;
    try {
      await _save(
        homeId: home,
        roomId: event.roomId,
        device: row.device,
        alias: event.alias,
        fixture: event.fixture,
        initial: row.initial,
      );
      saved = true;
      notice = LightSavedNotice(event.alias, event.ip);
    } on DomainException catch (e) {
      // The domain's own line, already written for the user.
      notice = SaveFailedNotice(e.message);
    } catch (e) {
      // Anything the domain did not model — a closed database, a platform
      // channel that went away. Whatever it was, the row must not be left
      // spinning over it, so it is reported like any other refused save.
      notice = SaveFailedNotice('$e');
    }
    // One exit for both outcomes: the address always leaves [saving], and
    // [found] is only rebuilt when there is a mark to add.
    emit(
      state.copyWith(
        found: saved ? _marked(event.ip) : null,
        saving: {...state.saving}..remove(event.ip),
        notice: notice,
      ),
    );
  }

  /// The rows, with the one at [ip] marked as belonging to this home.
  List<FoundDevice> _marked(String ip) => [
    for (var f in state.found)
      f.device.ip == ip
          ? f.copyWith(device: f.device.copyWith(alreadySaved: true))
          : f,
  ];

  @override
  Future<void> close() async {
    var running = _subscription;
    _subscription = null;
    await running?.cancel();
    _resumePolling();
    return super.close();
  }
}
