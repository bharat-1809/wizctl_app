import 'dart:async';

import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/repositories/home_repository.dart';
import 'package:wizctl_app/domain/repositories/light_repository.dart';
import 'package:wizctl_app/domain/repositories/live_state_persistence.dart';
import 'package:wizctl_app/domain/repositories/room_repository.dart';
import 'package:wizctl_app/domain/repositories/settings_repository.dart';
import 'package:wizctl_app/domain/services/clock.dart';
import 'package:wizctl_app/domain/services/id_generator.dart';
import 'package:wizctl_app/domain/services/network_monitor.dart';

export 'fake_gateway.dart';

/// A broadcast stream that replays its latest value to new listeners.
class _Replay<T> {
  T value;
  final _controller = StreamController<T>.broadcast();
  _Replay(this.value);
  Stream<T> get stream async* {
    yield value;
    yield* _controller.stream;
  }

  void set(T next) {
    value = next;
    _controller.add(next);
  }
}

class FakeHomeRepository implements HomeRepository {
  final Map<String, Home> _homes = {};
  late final _Replay<List<Home>> _all = _Replay(_list());

  /// Sorted by `(sortIndex, id)`: `List.sort` is not stable, so homes
  /// sharing a `sortIndex` need the id tie-break for a deterministic order.
  List<Home> _list() => _homes.values.toList()
    ..sort((a, b) {
      var bySortIndex = a.sortIndex.compareTo(b.sortIndex);
      return bySortIndex != 0 ? bySortIndex : a.id.compareTo(b.id);
    });
  void _notify() => _all.set(_list());
  void seed(List<Home> homes) {
    for (var h in homes) {
      _homes[h.id] = h;
    }
    _notify();
  }

  @override
  Stream<List<Home>> watchAll() => _all.stream;
  @override
  Future<List<Home>> getAll() async => _list();
  @override
  Future<Home?> get(String id) async => _homes[id];
  @override
  Future<void> insert(Home home) async {
    _homes[home.id] = home;
    _notify();
  }

  @override
  Future<void> update(Home home) => insert(home);
  @override
  Future<void> delete(String id) async {
    _homes.remove(id);
    _notify();
  }
}

class FakeRoomRepository implements RoomRepository {
  final Map<String, Room> _rooms = {};
  final _changes = StreamController<void>.broadcast();
  void seed(List<Room> rooms) {
    for (var r in rooms) {
      _rooms[r.id] = r;
    }
    _changes.add(null);
  }

  /// Sorted by `(sortIndex, id)`: `List.sort` is not stable, so rooms
  /// sharing a `sortIndex` need the id tie-break for a deterministic order.
  List<Room> _byHome(String homeId) =>
      _rooms.values.where((r) => r.homeId == homeId).toList()..sort((a, b) {
        var bySortIndex = a.sortIndex.compareTo(b.sortIndex);
        return bySortIndex != 0 ? bySortIndex : a.id.compareTo(b.id);
      });
  @override
  Stream<List<Room>> watchByHome(String homeId) async* {
    yield _byHome(homeId);
    yield* _changes.stream.map((_) => _byHome(homeId));
  }

  @override
  Future<List<Room>> getByHome(String homeId) async => _byHome(homeId);
  @override
  Future<Room?> get(String id) async => _rooms[id];
  @override
  Future<void> insert(Room room) async {
    _rooms[room.id] = room;
    _changes.add(null);
  }

  @override
  Future<void> update(Room room) => insert(room);
  @override
  Future<void> delete(String id) async {
    _rooms.remove(id);
    _changes.add(null);
  }
}

class FakeLightRepository implements LightRepository {
  final Map<String, Light> _lights = {};
  final _changes = StreamController<void>.broadcast();
  void seed(List<Light> lights) {
    for (var l in lights) {
      _lights[l.id] = l;
    }
    _changes.add(null);
  }

  /// Sorted by `(sortIndex, id)`: `List.sort` is not stable, so lights
  /// sharing a `sortIndex` need the id tie-break for a deterministic order.
  List<Light> _sorted(Iterable<Light> l) => l.toList()
    ..sort((a, b) {
      var bySortIndex = a.sortIndex.compareTo(b.sortIndex);
      return bySortIndex != 0 ? bySortIndex : a.id.compareTo(b.id);
    });
  List<Light> byHome(String homeId) =>
      _sorted(_lights.values.where((l) => l.homeId == homeId));
  List<Light> byRoom(String roomId) =>
      _sorted(_lights.values.where((l) => l.roomId == roomId));
  @override
  Stream<List<Light>> watchByHome(String homeId) async* {
    yield byHome(homeId);
    yield* _changes.stream.map((_) => byHome(homeId));
  }

  @override
  Stream<List<Light>> watchByRoom(String roomId) async* {
    yield byRoom(roomId);
    yield* _changes.stream.map((_) => byRoom(roomId));
  }

  @override
  Stream<Light?> watch(String id) async* {
    yield _lights[id];
    yield* _changes.stream.map((_) => _lights[id]);
  }

  @override
  Future<List<Light>> getByHome(String homeId) async => byHome(homeId);
  @override
  Future<List<Light>> getByRoom(String roomId) async => byRoom(roomId);
  @override
  Future<Light?> get(String id) async => _lights[id];
  @override
  Future<Light?> getByMac(String homeId, String mac) async => _lights.values
      .where((l) => l.homeId == homeId && l.mac == mac)
      .firstOrNull;
  @override
  Future<void> insert(Light light) async {
    _lights[light.id] = light;
    _changes.add(null);
  }

  @override
  Future<void> update(Light light) => insert(light);
  @override
  Future<void> delete(String id) async {
    _lights.remove(id);
    _changes.add(null);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  late final _Replay<AppSettings> _settings = _Replay(AppSettings.defaults);
  @override
  Stream<AppSettings> watch() => _settings.stream;
  @override
  Future<AppSettings> get() async => _settings.value;
  @override
  Future<void> save(AppSettings settings) async => _settings.set(settings);
}

class FakeLiveStatePersistence implements LiveStatePersistence {
  Map<String, LiveState> stored = {};
  int saves = 0;
  @override
  Future<Map<String, LiveState>> load() async => stored;
  @override
  Future<void> save(Map<String, LiveState> states) async {
    stored = Map.of(states);
    saves++;
  }
}

/// A manually-driven [Clock]. `delay` completes immediately and advances
/// [now] by the requested duration rather than waiting for it: tests verify
/// the duration a caller *asked for* (recorded in [delays]), not elapsed
/// wall-clock time.
class FakeClock implements Clock {
  DateTime current;
  final List<Duration> delays = [];
  FakeClock([DateTime? start]) : current = start ?? DateTime(2026, 9, 8, 12);
  @override
  DateTime now() => current;
  @override
  Future<void> delay(Duration duration) async {
    delays.add(duration);
    current = current.add(duration);
  }
}

class SequenceIds implements IdGenerator {
  int _n = 0;
  @override
  String next() => 'id${++_n}';
}

/// A scripted [NetworkInfo]: [subnet] is the value [currentSubnet] returns,
/// settable between calls; [calls] counts how many times it was awaited.
class FakeNetworkInfo implements NetworkInfo {
  String? subnet;
  int calls = 0;

  FakeNetworkInfo([this.subnet]);

  @override
  Future<String?> currentSubnet() async {
    calls++;
    return subnet;
  }
}
