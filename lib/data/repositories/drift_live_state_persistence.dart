import 'package:drift/drift.dart';

import '../../domain/entities/live_state.dart';
import '../../domain/repositories/live_state_persistence.dart';
import '../db/app_database.dart';
import 'row_mappers.dart';

class DriftLiveStatePersistence implements LiveStatePersistence {
  final AppDatabase _db;

  DriftLiveStatePersistence(this._db);

  @override
  Future<Map<String, LiveState>> load() async {
    var rows = await _db.select(_db.lightStates).get();
    return {for (var r in rows) r.lightId: r.toDomain()};
  }

  @override
  Future<void> save(Map<String, LiveState> states) => _db.transaction(() async {
    var known = (await _db.select(_db.lights).get()).map((l) => l.id).toSet();
    await _db.batch((b) {
      for (var entry in states.entries) {
        if (!known.contains(entry.key)) continue;
        b.insert(
          _db.lightStates,
          entry.value.toRow(entry.key),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  });
}
