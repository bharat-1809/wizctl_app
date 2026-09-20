import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/services/network_monitor.dart';
import '../domain/services/sync_coordinator.dart';
import 'blocs/homes_bloc.dart';

/// What the shell owes the logic layer (`AppDependencies.sync`): the active
/// home reaches [SyncCoordinator], the cold start reads once, the app going
/// away pauses polling and coming back refreshes both the subnet and the
/// bulbs (spec §5.8, §5.9).
///
/// Only [AppLifecycleListener.onResume] and [AppLifecycleListener.onHide] are
/// bound. A real foreground return fires `onShow` *and* `onResume`, so
/// binding both would refresh twice; and the listener asserts on a
/// `hidden → resumed` jump, so the pair `onHide`/`onResume` is the one that
/// sees every real transition exactly once.
class AppLifecycleDriver {
  final SyncCoordinator _sync;
  final NetworkMonitor _network;
  final HomesBloc _homes;
  StreamSubscription<String?>? _subscription;
  AppLifecycleListener? _listener;

  /// Whether the one launch read has happened. The first home to arrive gets
  /// it — on a device with no home the first run has nothing to read, and the
  /// home it creates is read by the screens that open on it, not again here.
  bool _coldStarted = false;

  AppLifecycleDriver({
    required SyncCoordinator sync,
    required NetworkMonitor network,
    required HomesBloc homes,
  }) : _sync = sync, // ignore: prefer_initializing_formals
       _network = network, // ignore: prefer_initializing_formals
       _homes = homes; // ignore: prefer_initializing_formals

  /// Idempotent: a second call neither adds a second observer nor takes a
  /// second subscription.
  void start() {
    _listener ??= AppLifecycleListener(onResume: _resumed, onHide: _paused);
    _subscription ??= _homes.stream
        .map((s) => s.activeHomeId)
        .distinct()
        .listen(_activate);
    _activate(_homes.state.activeHomeId);
  }

  void _activate(String? homeId) {
    _sync.activateHome(homeId);
    if (homeId != null && !_coldStarted) {
      _coldStarted = true;
      unawaited(_sync.onColdStart());
    }
  }

  /// The subnet first: a return from the background is exactly when the
  /// device may have joined another network, and the banner has to be right
  /// before the writes the user makes on the screen they came back to.
  void _resumed() {
    unawaited(_network.refresh());
    unawaited(_sync.onResumed());
  }

  void _paused() => _sync.onPaused();

  void dispose() {
    _listener?.dispose();
    unawaited(_subscription?.cancel());
  }
}
