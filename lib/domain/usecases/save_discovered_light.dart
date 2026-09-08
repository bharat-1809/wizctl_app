import '../entities/entities.dart';
import '../repositories/light_repository.dart';
import '../services/clock.dart';
import '../services/id_generator.dart';
import '../services/live_state_store.dart';
import 'usecase_exceptions.dart';

/// Turns a discovered device into a saved light, appended after the home's
/// existing lights.
class SaveDiscoveredLight {
  final LightRepository _lights;
  final LiveStateStore _store;
  final IdGenerator _ids;
  final Clock _clock;

  SaveDiscoveredLight({
    required LightRepository lights,
    required LiveStateStore store,
    required IdGenerator ids,
    required Clock clock,
  }) : _lights = lights, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _ids = ids, // ignore: prefer_initializing_formals
       _clock = clock; // ignore: prefer_initializing_formals

  Future<Light> call({
    required String homeId,
    required String roomId,
    required DiscoveredDevice device,
    required String alias,
    required Fixture fixture,
    LiveState? initial,
  }) async {
    if (await _lights.getByMac(homeId, device.mac) != null) {
      throw const AlreadySavedException();
    }
    var name = alias.trim().isEmpty ? device.displayName : alias.trim();
    var count = (await _lights.getByHome(homeId)).length;
    var light = Light(
      id: _ids.next(),
      homeId: homeId,
      roomId: roomId,
      name: name,
      ip: device.ip,
      mac: device.mac,
      moduleName: device.moduleName,
      bulbClass: device.bulbClass,
      fixture: fixture,
      fwVersion: device.fwVersion,
      sortIndex: count,
      addedAt: _clock.now(),
    );
    await _lights.insert(light);
    if (initial != null) _store.put(light.id, initial);
    return light;
  }
}
