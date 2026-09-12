import '../repositories/light_repository.dart';

/// Moves a light to a different room, if it still exists.
class MoveLight {
  final LightRepository _lights;

  MoveLight({required LightRepository lights})
    : _lights = lights; // ignore: prefer_initializing_formals

  Future<void> call(String id, String roomId) async {
    var light = await _lights.get(id);
    if (light != null) await _lights.update(light.copyWith(roomId: roomId));
  }
}
