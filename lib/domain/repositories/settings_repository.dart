import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();
  Future<AppSettings> get();
  Future<void> save(AppSettings settings);
}
