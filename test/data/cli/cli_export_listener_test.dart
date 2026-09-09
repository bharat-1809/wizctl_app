import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/cli/cli_config_exporter.dart';
import 'package:wizctl_app/data/cli/cli_export_listener.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fakes.dart';

/// Relays [source] through a controller that declares its own `onCancel`,
/// so `cancel()` returns a freshly created, zone-local future a `fakeAsync`
/// test can observe. The fakes' `async*` streams instead return the
/// process-wide `Future._nullFuture` sentinel, pinned to whichever zone
/// first realized it, which never completes inside a `fakeAsync` zone — see
/// `test/data/repositories/live_state_persister_test.dart` for the same
/// hazard. Without this, `CliExportListener.dispose()` finishes its final
/// export but its future is never seen to complete.
Stream<T> _inZoneCancel<T>(Stream<T> source) {
  late StreamSubscription<T> upstream;
  var controller = StreamController<T>(
    onCancel: () {
      unawaited(upstream.cancel());
      return Future.value();
    },
  );
  upstream = source.listen(controller.add);
  return controller.stream;
}

class _InZoneSettings extends FakeSettingsRepository {
  @override
  Stream<AppSettings> watch() => _inZoneCancel(super.watch());
}

class _InZoneRooms extends FakeRoomRepository {
  @override
  Stream<List<Room>> watchByHome(String homeId) =>
      _inZoneCancel(super.watchByHome(homeId));
}

class _InZoneLights extends FakeLightRepository {
  @override
  Stream<List<Light>> watchByHome(String homeId) =>
      _inZoneCancel(super.watchByHome(homeId));
}

/// A [CliConfigExporter] that counts exports instead of touching the disk,
/// so the listener's debouncing can be observed without real IO.
class _CountingExporter extends CliConfigExporter {
  int exports = 0;
  List<Light> lastLights = [];
  _CountingExporter() : super(homeDirectory: () => Directory.systemTemp);
  @override
  Future<void> export({
    required List<Light> lights,
    required List<Room> rooms,
  }) async {
    exports++;
    lastLights = lights;
  }
}

void main() {
  test('exports the active home after changes, debounced', () {
    fakeAsync((async) {
      var settings = FakeSettingsRepository();
      var rooms = FakeRoomRepository()
        ..seed([
          const Room(id: 'r', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa),
        ]);
      var lights = FakeLightRepository();
      var exporter = _CountingExporter();
      var listener = CliExportListener(
        settings: settings,
        rooms: rooms,
        lights: lights,
        exporter: exporter,
        debounce: const Duration(milliseconds: 500),
      );
      listener.start();
      async.flushMicrotasks();
      expect(exporter.exports, 0, reason: 'no active home yet');
      settings.save(const AppSettings(activeHomeId: 'h'));
      async.flushMicrotasks();
      lights.insert(
        Light(
          id: '1',
          homeId: 'h',
          roomId: 'r',
          name: 'x',
          ip: '1',
          mac: 'm',
          fixture: Fixture.bulb,
          addedAt: DateTime(2026),
        ),
      );
      lights.insert(
        Light(
          id: '2',
          homeId: 'h',
          roomId: 'r',
          name: 'y',
          ip: '2',
          mac: 'n',
          fixture: Fixture.bulb,
          addedAt: DateTime(2026),
        ),
      );
      async.elapse(const Duration(milliseconds: 600));
      expect(exporter.exports, 1);
      expect(exporter.lastLights, hasLength(2));
      listener.dispose();
    });
  });

  test('dispose flushes the pending export exactly once', () {
    fakeAsync((async) {
      var settings = _InZoneSettings();
      var rooms = _InZoneRooms()
        ..seed([
          const Room(id: 'r', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa),
        ]);
      var lights = _InZoneLights();
      var exporter = _CountingExporter();
      var listener = CliExportListener(
        settings: settings,
        rooms: rooms,
        lights: lights,
        exporter: exporter,
        debounce: const Duration(milliseconds: 500),
      );
      listener.start();
      async.flushMicrotasks();
      settings.save(const AppSettings(activeHomeId: 'h'));
      async.flushMicrotasks();
      lights.insert(
        Light(
          id: '1',
          homeId: 'h',
          roomId: 'r',
          name: 'x',
          ip: '1',
          mac: 'm',
          fixture: Fixture.bulb,
          addedAt: DateTime(2026),
        ),
      );
      async.elapse(const Duration(milliseconds: 100));
      expect(exporter.exports, 0, reason: 'still inside the debounce');
      var disposed = false;
      unawaited(listener.dispose().then((_) => disposed = true));
      async.flushMicrotasks();
      expect(exporter.exports, 1, reason: 'dispose flushed the pending export');
      expect(exporter.lastLights, hasLength(1));
      expect(disposed, isTrue);
      async.elapse(const Duration(milliseconds: 600));
      expect(exporter.exports, 1, reason: 'the cancelled timer never fires');
    });
  });
}
