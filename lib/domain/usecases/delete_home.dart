import '../repositories/home_repository.dart';
import '../repositories/settings_repository.dart';
import 'usecase_exceptions.dart';

/// Deletes a home; at least one home must always remain, and the active
/// home moves on when it is the one deleted.
class DeleteHome {
  final HomeRepository _homes;
  final SettingsRepository _settings;

  DeleteHome({
    required HomeRepository homes,
    required SettingsRepository settings,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _settings = settings; // ignore: prefer_initializing_formals

  Future<void> call(String id) async {
    var all = await _homes.getAll();
    if (all.length <= 1) throw const LastHomeException();
    await _homes.delete(id);
    var settings = await _settings.get();
    if (settings.activeHomeId == id) {
      var remaining = all.where((h) => h.id != id).first;
      await _settings.save(settings.copyWith(activeHomeId: remaining.id));
    }
  }
}
