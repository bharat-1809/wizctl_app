import '../entities/light.dart';

abstract interface class LightRepository {
  Stream<List<Light>> watchByHome(String homeId);
  Stream<List<Light>> watchByRoom(String roomId);
  Stream<Light?> watch(String id);
  Future<List<Light>> getByHome(String homeId);
  Future<List<Light>> getByRoom(String roomId);
  Future<Light?> get(String id);
  Future<Light?> getByMac(String homeId, String mac);
  Future<void> insert(Light light);
  Future<void> update(Light light);
  Future<void> delete(String id);
}
