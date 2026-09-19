import '../repositories/settings_repository.dart';

/// The stream every route bloc derives its active home from.
Stream<String?> activeHomeIds(SettingsRepository settings) =>
    settings.watch().map((s) => s.activeHomeId).distinct();
