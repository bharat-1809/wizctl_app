import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../db/app_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase _db;

  DriftSettingsRepository(this._db);

  static const _activeHome = 'activeHomeId';
  static const _feedback = 'feedbackEnabled';
  static const _rescan = 'rescanOnLaunch';

  AppSettings _parse(List<SettingRow> rows) {
    var map = {for (var r in rows) r.key: r.value};
    return AppSettings(
      activeHomeId: map[_activeHome],
      feedbackEnabled: map[_feedback] != 'false',
      rescanOnLaunch: map[_rescan] != 'false',
    );
  }

  @override
  Stream<AppSettings> watch() => _db.select(_db.settings).watch().map(_parse);

  @override
  Future<AppSettings> get() async =>
      _parse(await _db.select(_db.settings).get());

  @override
  Future<void> save(AppSettings settings) => _db.transaction(() async {
    if (settings.activeHomeId == null) {
      await (_db.delete(
        _db.settings,
      )..where((s) => s.key.equals(_activeHome))).go();
    } else {
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingRow(key: _activeHome, value: settings.activeHomeId!),
          );
    }
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingRow(key: _feedback, value: '${settings.feedbackEnabled}'),
        );
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingRow(key: _rescan, value: '${settings.rescanOnLaunch}'),
        );
  });
}
