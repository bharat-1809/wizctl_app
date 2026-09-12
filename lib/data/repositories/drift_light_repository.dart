import 'package:drift/drift.dart';

import '../../domain/entities/light.dart';
import '../../domain/repositories/light_repository.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftLightRepository implements LightRepository {
  final AppDatabase _db;

  DriftLightRepository(this._db);

  SimpleSelectStatement<$LightsTable, LightRow> _where(
    Expression<bool> Function($LightsTable l) filter,
  ) => _db.select(_db.lights)
    ..where(filter)
    // Id last so rows sharing a sort index and timestamp keep one stable
    // order rather than whatever the rowids happen to be.
    ..orderBy([
      (l) => OrderingTerm.asc(l.sortIndex),
      (l) => OrderingTerm.asc(l.addedAt),
      (l) => OrderingTerm.asc(l.id),
    ]);

  List<Light> _map(List<LightRow> rows) =>
      rows.map((r) => r.toDomain()).toList();

  @override
  Stream<List<Light>> watchByHome(String homeId) =>
      _where((l) => l.homeId.equals(homeId)).watch().map(_map);

  @override
  Stream<List<Light>> watchByRoom(String roomId) =>
      _where((l) => l.roomId.equals(roomId)).watch().map(_map);

  @override
  Stream<Light?> watch(String id) =>
      _where((l) => l.id.equals(id))
          .watchSingleOrNull()
          .map((r) => r?.toDomain());

  @override
  Future<List<Light>> getByHome(String homeId) async =>
      _map(await _where((l) => l.homeId.equals(homeId)).get());

  @override
  Future<List<Light>> getByRoom(String roomId) async =>
      _map(await _where((l) => l.roomId.equals(roomId)).get());

  @override
  Future<Light?> get(String id) async =>
      (await _where((l) => l.id.equals(id)).getSingleOrNull())?.toDomain();

  @override
  Future<Light?> getByMac(String homeId, String mac) async => (await _where(
    (l) => l.homeId.equals(homeId) & l.mac.equals(mac),
  ).getSingleOrNull())?.toDomain();

  @override
  Future<void> insert(Light light) =>
      _db.into(_db.lights).insert(light.toRow());

  @override
  Future<void> update(Light light) =>
      _db.update(_db.lights).replace(light.toRow());

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.lights)..where((l) => l.id.equals(id))).go();
}
