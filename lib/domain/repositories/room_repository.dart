import '../entities/room.dart';

abstract interface class RoomRepository {
  Stream<List<Room>> watchByHome(String homeId);
  Future<List<Room>> getByHome(String homeId);
  Future<Room?> get(String id);
  Future<void> insert(Room room);
  Future<void> update(Room room);
  Future<void> delete(String id);
}
