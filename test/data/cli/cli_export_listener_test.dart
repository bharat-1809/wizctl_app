import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/cli/cli_config_exporter.dart';
import 'package:wizctl_app/data/cli/cli_export_listener.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

import '../../support/fakes.dart';
import '../../support/in_zone_cancel.dart';

/// The fakes' streams relayed through [inZoneCancel], so `cancel()` resolves
/// inside the `fakeAsync` zone and `CliExportListener.dispose()` is seen to
/// complete.
class _InZoneSettings extends FakeSettingsRepository {
  @override
  Stream<AppSettings> watch() => inZoneCancel(super.watch());
}

class _InZoneRooms extends FakeRoomRepository {
  @override
  Stream<List<Room>> watchByHome(String homeId) =>
      inZoneCancel(super.watchByHome(homeId));
}

class _InZoneLights extends FakeLightRepository {
  @override
  Stream<List<Light>> watchByHome(String homeId) =>
      inZoneCancel(super.watchByHome(homeId));
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

/// A [_CountingExporter] that suspends for 10 ms before counting, so a test
/// can distinguish a caller that awaits the export from one that fires it.
class _DelayedExporter extends _CountingExporter {
  @override
  Future<void> export({
    required List<Light> lights,
    required List<Room> rooms,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return super.export(lights: lights, rooms: rooms);
  }
}

/// An exporter that always fails, so a test can watch a failed config write
/// reach `onError` instead of the zone.
class _FailingExporter extends _CountingExporter {
  @override
  Future<void> export({
    required List<Light> lights,
    required List<Room> rooms,
  }) async {
    throw StateError('no home directory');
  }
}

void main() {
  Light aLight(String id) => Light(
    id: id,
    homeId: 'h',
    roomId: 'r',
    name: 'x',
    ip: id,
    mac: 'm$id',
    fixture: Fixture.bulb,
    addedAt: DateTime(2026),
  );

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

  test('dispose awaits an export the debounce already fired', () {
    fakeAsync((async) {
      var settings = _InZoneSettings();
      var rooms = _InZoneRooms()
        ..seed([
          const Room(id: 'r', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa),
        ]);
      var lights = _InZoneLights();
      var exporter = _DelayedExporter();
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
      lights.insert(aLight('1'));
      async.elapse(const Duration(milliseconds: 500));
      expect(exporter.exports, 0, reason: 'fired, still exporting');
      var disposed = false;
      unawaited(listener.dispose().then((_) => disposed = true));
      async.flushMicrotasks();
      expect(disposed, isFalse, reason: 'the in-flight export is awaited');
      async.elapse(const Duration(milliseconds: 10));
      expect(disposed, isTrue);
      expect(exporter.exports, 1);
    });
  });

  test('a failed export reaches onError and dispose still completes', () {
    fakeAsync((async) {
      var settings = _InZoneSettings();
      var rooms = _InZoneRooms()
        ..seed([
          const Room(id: 'r', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa),
        ]);
      var lights = _InZoneLights();
      Object? error;
      StackTrace? stack;
      var listener = CliExportListener(
        settings: settings,
        rooms: rooms,
        lights: lights,
        exporter: _FailingExporter(),
        debounce: const Duration(milliseconds: 500),
        onError: (e, s) {
          error = e;
          stack = s;
        },
      );
      listener.start();
      async.flushMicrotasks();
      settings.save(const AppSettings(activeHomeId: 'h'));
      async.flushMicrotasks();
      lights.insert(aLight('1'));
      async.elapse(const Duration(milliseconds: 600));
      expect(error, isA<StateError>());
      expect(stack, isNotNull);
      var disposed = false;
      unawaited(listener.dispose().then((_) => disposed = true));
      async.flushMicrotasks();
      expect(disposed, isTrue);
    });
  });
}
