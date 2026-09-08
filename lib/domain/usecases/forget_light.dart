import '../repositories/light_repository.dart';
import '../services/live_state_store.dart';

/// Removes a light from the home and clears its live state.
class ForgetLight {
  final LightRepository _lights;
  final LiveStateStore _store;

  ForgetLight({required LightRepository lights, required LiveStateStore store})
    : _lights = lights, // ignore: prefer_initializing_formals
      _store = store; // ignore: prefer_initializing_formals

  Future<void> call(String id) async {
    await _lights.delete(id);
    _store.remove(id);
  }
}
