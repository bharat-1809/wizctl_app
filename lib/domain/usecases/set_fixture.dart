import '../entities/entities.dart';
import '../repositories/light_repository.dart';

/// Changes how a light is drawn, if it still exists.
class SetFixture {
  final LightRepository _lights;

  SetFixture({required LightRepository lights})
    : _lights = lights; // ignore: prefer_initializing_formals

  Future<void> call(String id, Fixture fixture) async {
    var light = await _lights.get(id);
    if (light != null) await _lights.update(light.copyWith(fixture: fixture));
  }
}
