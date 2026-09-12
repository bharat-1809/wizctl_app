import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../entities/entities.dart';
import '../repositories/home_repository.dart';
import '../repositories/light_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/clock.dart';
import '../services/id_generator.dart';
import '../services/live_state_store.dart';
import 'usecase_exceptions.dart';

/// A room offered during onboarding, keyed by a temporary id until it is
/// written and gets a real one.
class OnboardingRoom extends Equatable {
  final String tempId;
  final String name;
  final RoomGlyph glyph;

  /// Added by the user rather than offered by a template; always written,
  /// even without a light.
  final bool custom;

  const OnboardingRoom({
    required this.tempId,
    required this.name,
    required this.glyph,
    required this.custom,
  });

  @override
  List<Object?> get props => [tempId, name, glyph, custom];
}

/// A discovered light the user chose to keep during onboarding.
class OnboardingLight extends Equatable {
  final DiscoveredDevice device;
  final String alias;
  final String roomTempId;
  final Fixture fixture;
  final LiveState? initial;

  const OnboardingLight({
    required this.device,
    required this.alias,
    required this.roomTempId,
    required this.fixture,
    this.initial,
  });

  @override
  List<Object?> get props => [device, alias, roomTempId, fixture, initial];
}

/// Everything the onboarding flow collected, ready to be written as the
/// first home.
class OnboardingResult extends Equatable {
  final String homeName;
  final String? subnet;
  final List<OnboardingRoom> rooms;
  final List<OnboardingLight> lights;

  const OnboardingResult({
    required this.homeName,
    this.subnet,
    required this.rooms,
    required this.lights,
  });

  @override
  List<Object?> get props => [homeName, subnet, rooms, lights];
}

/// Writes the first home: only rooms that received a light, plus rooms the
/// user created by hand, are written (handoff spec).
class FinishOnboarding {
  final HomeRepository _homes;
  final RoomRepository _rooms;
  final LightRepository _lights;
  final SettingsRepository _settings;
  final LiveStateStore _store;
  final IdGenerator _ids;
  final Clock _clock;

  FinishOnboarding({
    required HomeRepository homes,
    required RoomRepository rooms,
    required LightRepository lights,
    required SettingsRepository settings,
    required LiveStateStore store,
    required IdGenerator ids,
    required Clock clock,
  }) : _homes = homes, // ignore: prefer_initializing_formals
       _rooms = rooms, // ignore: prefer_initializing_formals
       _lights = lights, // ignore: prefer_initializing_formals
       _settings = settings, // ignore: prefer_initializing_formals
       _store = store, // ignore: prefer_initializing_formals
       _ids = ids, // ignore: prefer_initializing_formals
       _clock = clock; // ignore: prefer_initializing_formals

  Future<Home> call(OnboardingResult result) async {
    var name = result.homeName.trim();
    if (name.isEmpty) throw const EmptyNameException();
    var now = _clock.now();
    var existingHomes = await _homes.getAll();
    var home = Home(
      id: _ids.next(),
      name: name,
      subnet: result.subnet,
      createdAt: now,
      sortIndex: _nextIndex(existingHomes.map((h) => h.sortIndex)),
    );
    await _homes.insert(home);

    var used = result.lights.map((l) => l.roomTempId).toSet();
    var roomIds = <String, String>{};
    var index = 0;
    for (var r in result.rooms) {
      if (!r.custom && !used.contains(r.tempId)) continue;
      var room = Room(
        id: _ids.next(),
        homeId: home.id,
        name: r.name.trim(),
        glyph: r.glyph,
        sortIndex: index++,
      );
      await _rooms.insert(room);
      roomIds[r.tempId] = room.id;
    }

    var lightIndex = 0;
    for (var l in result.lights) {
      var roomId = roomIds[l.roomTempId];
      if (roomId == null) continue;
      var light = Light(
        id: _ids.next(),
        homeId: home.id,
        roomId: roomId,
        name: l.alias.trim().isEmpty ? l.device.displayName : l.alias.trim(),
        ip: l.device.ip,
        mac: l.device.mac,
        moduleName: l.device.moduleName,
        bulbClass: l.device.bulbClass,
        fixture: l.fixture,
        fwVersion: l.device.fwVersion,
        sortIndex: lightIndex++,
        addedAt: now,
      );
      await _lights.insert(light);
      if (l.initial != null) _store.put(light.id, l.initial!);
    }

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
