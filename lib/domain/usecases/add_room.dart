import '../entities/entities.dart';
import '../repositories/room_repository.dart';
import '../services/id_generator.dart';
import 'usecase_exceptions.dart';

/// Adds a room to a home, appended after the existing ones.
class AddRoom {
  final RoomRepository _rooms;
  final IdGenerator _ids;

  AddRoom({required RoomRepository rooms, required IdGenerator ids})
    : _rooms = rooms, // ignore: prefer_initializing_formals
      _ids = ids; // ignore: prefer_initializing_formals

  Future<Room> call(String homeId, String name, RoomGlyph glyph) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var count = (await _rooms.getByHome(homeId)).length;
    var room = Room(
      id: _ids.next(),
      homeId: homeId,
      name: trimmed,
      glyph: glyph,
      sortIndex: count,
    );
    await _rooms.insert(room);
    return room;
  }
}
