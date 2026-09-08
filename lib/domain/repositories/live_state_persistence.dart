import '../entities/live_state.dart';

/// Last-known live state, so dials show real values at launch while the
/// first refresh runs.
abstract interface class LiveStatePersistence {
  Future<Map<String, LiveState>> load();
  Future<void> save(Map<String, LiveState> states);
}
