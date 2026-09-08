import '../entities/entities.dart';
import '../repositories/light_repository.dart';
import '../services/clock.dart';
import '../services/device_gateway.dart';
import '../services/live_state_mapper.dart';
import '../services/live_state_store.dart';

/// Reads the bulbs and updates the store (spec §5.8). One lost packet is
/// not "unreachable"; two consecutive misses are.
class RefreshStates {
  final DeviceGateway _gateway;
  final LiveStateStore _store;
  final LightRepository _lights;
  final Clock _clock;

  /// At most this many reads in flight at once (spec §5.8).
  final int concurrency;

  /// Consecutive read failures before a light is marked unreachable (spec §5.8).
  final int missesToUnreachable;

  final Map<String, int> _misses = {};

  RefreshStates({
    required DeviceGateway gateway,
    required LiveStateStore store,
    required LightRepository lights,
    required Clock clock,
    this.concurrency = 8,
    this.missesToUnreachable = 2,
  }) : _gateway = gateway, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _clock = clock; // ignore: prefer_initializing_formals

  Future<void> forHome(String homeId) async =>
      call((await _lights.getByHome(homeId)).map((l) => l.id));

  Future<void> call(Iterable<String> lightIds) async {
    var lights = <Light>[];
    for (var id in lightIds) {
      var light = await _lights.get(id);
      if (light != null) lights.add(light);
    }
    for (var start = 0; start < lights.length; start += concurrency) {
      await Future.wait(lights.skip(start).take(concurrency).map(_readOne));
    }
  }

  Future<void> _readOne(Light light) async {
    try {
      var state = await _gateway.readState(light.ip);
      _misses[light.id] = 0;
      _store.put(
        light.id,
        LiveStateMapper.fromLightState(
          state,
          previous: _store.of(light.id),
          now: _clock.now(),
        ),
      );
    } on DeviceException {
      var misses = (_misses[light.id] ?? 0) + 1;
      _misses[light.id] = misses;
      if (misses >= missesToUnreachable) {
        _store.update(light.id, (s) => s.copyWith(reachable: false));
      }
    }
  }
}
