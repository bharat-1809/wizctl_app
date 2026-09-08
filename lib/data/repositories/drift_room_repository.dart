import 'package:drift/drift.dart';

import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftRoomRepository implements RoomRepository {
  final AppDatabase _db;

  DriftRoomRepository(this._db);

  SimpleSelectStatement<$RoomsTable, RoomRow> _byHome(String homeId) =>
      _db.select(_db.rooms)
        ..where((r) => r.homeId.equals(homeId))
        ..orderBy([(r) => OrderingTerm.asc(r.sortIndex)]);

  @override
  Stream<List<Room>> watchByHome(String homeId) =>
      _byHome(homeId)
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<Room>> getByHome(String homeId) async =>
      (await _byHome(homeId).get()).map((r) => r.toDomain()).toList();

  @override
  Future<Room?> get(String id) async => (await (_db.select(
    _db.rooms,
  )..where((r) => r.id.equals(id))).getSingleOrNull())?.toDomain();

  @override
  Future<void> insert(Room room) => _db.into(_db.rooms).insert(room.toRow());

  @override
  Future<void> update(Room room) => _db.update(_db.rooms).replace(room.toRow());

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.rooms)..where((r) => r.id.equals(id))).go();
}
