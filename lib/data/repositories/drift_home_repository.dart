import 'package:drift/drift.dart';

import '../../domain/entities/home.dart';
import '../../domain/repositories/home_repository.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftHomeRepository implements HomeRepository {
  final AppDatabase _db;

  DriftHomeRepository(this._db);

  SimpleSelectStatement<$HomesTable, HomeRow> get _ordered =>
      _db.select(_db.homes)..orderBy([
        (h) => OrderingTerm.asc(h.sortIndex),
        (h) => OrderingTerm.asc(h.createdAt),
      ]);

  @override
  Stream<List<Home>> watchAll() =>
      _ordered.watch().map((rows) => rows.map((r) => r.toDomain()).toList());

  @override
  Future<List<Home>> getAll() async =>
      (await _ordered.get()).map((r) => r.toDomain()).toList();

  @override
  Future<Home?> get(String id) async => (await (_db.select(
    _db.homes,
  )..where((h) => h.id.equals(id))).getSingleOrNull())?.toDomain();

  @override
  Future<void> insert(Home home) => _db.into(_db.homes).insert(home.toRow());

  @override
  Future<void> update(Home home) => _db.update(_db.homes).replace(home.toRow());

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.homes)..where((h) => h.id.equals(id))).go();
}
