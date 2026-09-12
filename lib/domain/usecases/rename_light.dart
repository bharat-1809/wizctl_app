import '../repositories/light_repository.dart';
import 'usecase_exceptions.dart';

/// Renames a light, if it still exists.
class RenameLight {
  final LightRepository _lights;

  RenameLight({required LightRepository lights})
    : _lights = lights; // ignore: prefer_initializing_formals

  Future<void> call(String id, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var light = await _lights.get(id);
    if (light != null) await _lights.update(light.copyWith(name: trimmed));
  }
}
