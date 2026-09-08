import '../repositories/settings_repository.dart';

/// Makes an existing home the active one.
class SwitchHome {
  final SettingsRepository _settings;

  SwitchHome({required SettingsRepository settings})
    : _settings = settings; // ignore: prefer_initializing_formals

  Future<void> call(String homeId) async =>
      _settings.save((await _settings.get()).copyWith(activeHomeId: homeId));
}
