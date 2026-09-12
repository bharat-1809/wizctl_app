import 'dart:math' as math;

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
    var existing = await _rooms.getByHome(homeId);
    var room = Room(
      id: _ids.next(),
      homeId: homeId,
      name: trimmed,
      glyph: glyph,
      sortIndex: _nextIndex(existing.map((r) => r.sortIndex)),
    );
    await _rooms.insert(room);
    return room;
  }

  /// Above the current maximum, not the count: a non-tail delete must not
  /// hand out an index that collides with a survivor.
  int _nextIndex(Iterable<int> existing) =>
      existing.isEmpty ? 0 : existing.reduce(math.max) + 1;
}
