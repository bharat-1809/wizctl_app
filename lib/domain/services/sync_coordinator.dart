import 'dart:async';

import '../repositories/light_repository.dart';
import '../repositories/settings_repository.dart';
import '../usecases/refresh_states.dart';

/// A screen's claim on polling: the lights it is showing right now.
class PollScope {
  final SyncCoordinator _owner;
  Set<String> _ids;

  PollScope._(this._owner, this._ids);

  void update(Set<String> lightIds) => _ids = lightIds;

  void dispose() => _owner._scopes.remove(this);
}

/// When the app reads the bulbs (spec §5.8): on cold start if the user
/// wants it, on resume, and every interval for whatever is on screen.
/// Polling pauses during discovery and while backgrounded.
class SyncCoordinator {
  final RefreshStates _refresh;
  final LightRepository _lights;
  final SettingsRepository _settings;

  /// How often the union of registered scopes is re-read (spec §5.8).
  final Duration pollInterval;

  final Set<PollScope> _scopes = {};
  String? _homeId;
  Timer? _timer;
  bool _background = false;
  bool _discovering = false;

  SyncCoordinator({
    required RefreshStates refresh,
    required LightRepository lights,
    required SettingsRepository settings,
    this.pollInterval = const Duration(seconds: 10),
  }) : _refresh = refresh, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _settings = settings; // ignore: prefer_initializing_formals

  void activateHome(String? homeId) {
    _homeId = homeId;
    _restart();
  }

  PollScope registerScope(Set<String> lightIds) {
    var scope = PollScope._(this, lightIds);
    _scopes.add(scope);
    return scope;
  }

  Future<void> onColdStart() async {
    if ((await _settings.get()).rescanOnLaunch) await refreshAll();
  }

  Future<void> onResumed() async {
    _background = false;
    _restart();
    await refreshAll();
  }

  void onPaused() {
    _background = true;
    _timer?.cancel();
  }

  void pauseForDiscovery() => _discovering = true;

  void resumeAfterDiscovery() => _discovering = false;

  Future<void> refreshAll() async {
    var homeId = _homeId;
    if (homeId == null || _discovering) return;
    await _refresh.forHome(homeId);
  }

  /// One light now (after a retry, or when a detail screen opens), if it
  /// still exists.
  Future<void> refreshLight(String lightId) async {
    if (await _lights.get(lightId) == null) return;
    await _refresh([lightId]);
  }

  void _restart() {
    _timer?.cancel();
    if (_background || _homeId == null) return;
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (_discovering || _background) return;
    var ids = {for (var s in _scopes) ...s._ids};
    if (ids.isEmpty) return;
    await _refresh(ids);
  }

  void dispose() {
    _timer?.cancel();
    _scopes.clear();
  }
}
