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
import 'package:wizctl_app/domain/usecases/usecase_exceptions.dart';

export 'fake_gateway.dart';

/// A stream that replays [latest] to a new listener and then forwards
/// [updates].
///
/// The subscription to [updates] is taken **synchronously** in `onListen`, so
/// a change written in the same microtask turn as the `listen` call still
/// arrives. An `async*` body cannot do this: it only reaches its
/// `yield* updates` after its first `yield` has been delivered, and a
/// broadcast source drops everything written in that window — which made a
/// fake silently lose a write that real code would have seen.
Stream<T> _replaying<T>(T Function() latest, Stream<T> updates) {
  late StreamController<T> out;
  StreamSubscription<T>? subscription;
  out = StreamController<T>(
    onListen: () {
      out.add(latest());
      subscription = updates.listen(
        out.add,
        onError: out.addError,
        onDone: out.close,
      );
    },
    // The source's cancel is not awaited: its future can be the SDK's shared
    // null future, which belongs to the root zone, and awaiting one of those
    // inside a `testWidgets` body never resumes. This closure's own future is
    // created in the canceller's zone, so `await subscription.cancel()` —
    // `Cubit.close()`, in practice — completes there.
    onCancel: () async {
      subscription?.cancel();
    },
  );
  return out.stream;
}

/// A broadcast stream that replays its latest value to new listeners.
class _Replay<T> {
  T value;
  final _controller = StreamController<T>.broadcast();
  _Replay(this.value);
  Stream<T> get stream => _replaying(() => value, _controller.stream);

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

  /// What [insert] throws instead of storing the room. Null by default, so a
  /// write succeeds. An `Object`, not a `DomainException`, so a test can model
  /// a failure the domain never modelled — a closed database, a platform
  /// channel that went away — and check that the view that asked for the write
  /// copes. [update] writes through [insert], so this fails one too.
  Object? insertError;
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
  Stream<List<Room>> watchByHome(String homeId) => _replaying(
    () => _byHome(homeId),
    _changes.stream.map((_) => _byHome(homeId)),
  );

  @override
  Future<List<Room>> getByHome(String homeId) async => _byHome(homeId);
  @override
  Future<Room?> get(String id) async => _rooms[id];
  @override
  Future<void> insert(Room room) async {
    var error = insertError;
    if (error != null) throw error;
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

  /// How long [delete] takes to finish *after* it has told its watchers the
  /// light has gone — the window in which a projection can see the deletion
  /// while the code that asked for it is still awaiting. Zero by default; a
  /// test that cares what a screen is told, and in what order, opens the
  /// window rather than leaving it to microtask luck.
  Duration deleteLatency = Duration.zero;

  /// What [delete] throws instead of removing the light. Null by default, so
  /// a delete succeeds; set it to make one fail the way a screen has to cope
  /// with — the light stays, and no watcher is told it has gone.
  DomainException? deleteError;

  /// How long [insert] takes to finish *after* it has told its watchers about
  /// the light — the window in which a screen is still showing a save as in
  /// flight. Zero by default. [update] writes through [insert], so this holds
  /// an update open too.
  Duration insertLatency = Duration.zero;

  /// What [insert] throws instead of storing the light. Null by default, so a
  /// save succeeds. It is an `Object`, not a `DomainException`, so a test can
  /// also model a failure the domain never modelled — a closed database, a
  /// platform channel that went away — and check that the screen copes.
  Object? insertError;

  /// What [get] throws instead of answering. Null by default. An `Object` for
  /// [insertError]'s reason: a read can fail in ways the domain never modelled
  /// too, and whoever asked for it has to cope.
  Object? getError;

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
  Stream<List<Light>> watchByHome(String homeId) => _replaying(
    () => byHome(homeId),
    _changes.stream.map((_) => byHome(homeId)),
  );

  @override
  Stream<List<Light>> watchByRoom(String roomId) => _replaying(
    () => byRoom(roomId),
    _changes.stream.map((_) => byRoom(roomId)),
  );

  @override
  Stream<Light?> watch(String id) =>
      _replaying(() => _lights[id], _changes.stream.map((_) => _lights[id]));

  @override
  Future<List<Light>> getByHome(String homeId) async => byHome(homeId);
  @override
  Future<List<Light>> getByRoom(String roomId) async => byRoom(roomId);
  @override
  Future<Light?> get(String id) async {
    var error = getError;
    if (error != null) throw error;
    return _lights[id];
  }

  @override
  Future<Light?> getByMac(String homeId, String mac) async => _lights.values
      .where((l) => l.homeId == homeId && l.mac == mac)
      .firstOrNull;
  @override
  Future<void> insert(Light light) async {
    var error = insertError;
    if (error != null) throw error;
    _lights[light.id] = light;
    _changes.add(null);
    if (insertLatency > Duration.zero) {
      await Future<void>.delayed(insertLatency);
    }
  }

  @override
  Future<void> update(Light light) => insert(light);
  @override
  Future<void> delete(String id) async {
    var error = deleteError;
    if (error != null) throw error;
    _lights.remove(id);
    _changes.add(null);
    if (deleteLatency > Duration.zero) {
      await Future<void>.delayed(deleteLatency);
    }
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
