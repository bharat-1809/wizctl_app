import 'dart:math' as math;

import '../entities/entities.dart';
import '../repositories/home_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/clock.dart';
import '../services/id_generator.dart';
import 'usecase_exceptions.dart';

/// Creates a home and makes it the active one (spec §5.1).
class CreateHome {
  final HomeRepository _homes;
  final SettingsRepository _settings;
  final IdGenerator _ids;
  final Clock _clock;

  CreateHome({
    required HomeRepository homes,
    required SettingsRepository settings,
    required IdGenerator ids,
    required Clock clock,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _ids = ids, // ignore: prefer_initializing_formals
       _clock = clock; // ignore: prefer_initializing_formals

  Future<Home> call(String name, {String? subnet}) async {
    var trimmed = name.trim();
    if (trimmed.isEmpty) throw const EmptyNameException();
    var existing = await _homes.getAll();
    var home = Home(
      id: _ids.next(),
      name: trimmed,
      subnet: subnet,
      createdAt: _clock.now(),
      sortIndex: _nextIndex(existing.map((h) => h.sortIndex)),
    );
    await _homes.insert(home);
    await _settings.save(
      (await _settings.get()).copyWith(activeHomeId: home.id),
    );
    return home;
  }

  /// Above the current maximum, not the count: a non-tail delete must not
  /// hand out an index that collides with a survivor.
  int _nextIndex(Iterable<int> existing) =>
      existing.isEmpty ? 0 : existing.reduce(math.max) + 1;
}
