import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl_app/data/db/app_database.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  HomeRow home(String id) => HomeRow(
    id: id,
    name: 'Home $id',
    subnet: null,
    createdAt: 0,
    sortIndex: 0,
  );
  RoomRow room(String id, String home) =>
      RoomRow(id: id, homeId: home, name: 'Room', glyph: 'sofa', sortIndex: 0);
  LightRow light(String id, String home, String room, {String mac = 'mac'}) =>
      LightRow(
        id: id,
        homeId: home,
        roomId: room,
        name: 'L',
        ip: '10.0.0.1',
        mac: mac,
        moduleName: null,
        bulbClass: 'rgb',
        fixture: 'bulb',
        fwVersion: null,
        sortIndex: 0,
        addedAt: 0,
      );

  test('inserts and reads back', () async {
    await db.into(db.homes).insert(home('h'));
    await db.into(db.rooms).insert(room('r', 'h'));
    await db.into(db.lights).insert(light('l', 'h', 'r'));
    expect((await db.select(db.lights).get()).single.mac, 'mac');
  });

  test('a MAC is unique within a home', () async {
    await db.into(db.homes).insert(home('h'));
    await db.into(db.homes).insert(home('h2'));
    await db.into(db.rooms).insert(room('r', 'h'));
    await db.into(db.rooms).insert(room('r2', 'h2'));
    await db.into(db.lights).insert(light('a', 'h', 'r'));
    await db.into(db.lights).insert(light('b', 'h2', 'r2'));
    await expectLater(
      db.into(db.lights).insert(light('c', 'h', 'r')),
      throwsA(anything),
    );
  });

  test(
    'deleting a home cascades; deleting a room with lights is refused',
    () async {
      await db.into(db.homes).insert(home('h'));
      await db.into(db.rooms).insert(room('r', 'h'));
      await db.into(db.lights).insert(light('l', 'h', 'r'));
      await db
          .into(db.lightStates)
          .insert(
            LightStateRow(
              lightId: 'l',
              isOn: true,
              brightness: 50,
              kelvin: 2700,
              r: 1,
              g: 2,
              b: 3,
              sceneId: 0,
              speed: 100,
              active: 'white',
              rssi: null,
              updatedAt: null,
            ),
          );
      await expectLater(
        (db.delete(db.rooms)..where((r) => r.id.equals('r'))).go(),
        throwsA(anything),
      );
      await (db.delete(db.homes)..where((h) => h.id.equals('h'))).go();
      expect(await db.select(db.rooms).get(), isEmpty);
      expect(await db.select(db.lights).get(), isEmpty);
      expect(await db.select(db.lightStates).get(), isEmpty);
    },
  );

  test('settings upsert', () async {
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          const SettingRow(key: 'activeHomeId', value: 'h'),
        );
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          const SettingRow(key: 'activeHomeId', value: 'h2'),
        );
    expect((await db.select(db.settings).get()).single.value, 'h2');
  });
}
