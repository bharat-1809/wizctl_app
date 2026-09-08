import '../repositories/room_repository.dart';
import 'usecase_exceptions.dart';

/// Renames a room, if it still exists.
class RenameRoom {
  final RoomRepository _rooms;

  RenameRoom({required RoomRepository rooms})
    : _rooms = rooms; // ignore: prefer_initializing_formals

  Future<void> call(String id, String name) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var room = await _rooms.get(id);
    if (room != null) await _rooms.update(room.copyWith(name: trimmed));
  }
}
