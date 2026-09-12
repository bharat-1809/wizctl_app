import '../repositories/light_repository.dart';
import '../repositories/room_repository.dart';
import 'usecase_exceptions.dart';

/// Deletes a room, but only once it holds no lights.
class DeleteRoom {
  final RoomRepository _rooms;
  final LightRepository _lights;

  DeleteRoom({required RoomRepository rooms, required LightRepository lights})
    : _rooms = rooms, // ignore: prefer_initializing_formals
      _lights = lights; // ignore: prefer_initializing_formals

  Future<void> call(String id) async {
    if ((await _lights.getByRoom(id)).isNotEmpty) {
      throw const RoomNotEmptyException();
    }
    await _rooms.delete(id);
  }
}
