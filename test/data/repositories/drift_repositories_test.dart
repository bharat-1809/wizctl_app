import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/data/db/app_database.dart';
import 'package:wizctl_app/data/repositories/drift_home_repository.dart';
import 'package:wizctl_app/data/repositories/drift_light_repository.dart';
import 'package:wizctl_app/data/repositories/drift_live_state_persistence.dart';
import 'package:wizctl_app/data/repositories/drift_room_repository.dart';
import 'package:wizctl_app/data/repositories/drift_settings_repository.dart';
import 'package:wizctl_app/domain/entities/entities.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late DriftHomeRepository homes;
  late DriftRoomRepository rooms;
  late DriftLightRepository lights;

  setUp(() {
    db = AppDatabase.inMemory();
    homes = DriftHomeRepository(db);
    rooms = DriftRoomRepository(db);
    lights = DriftLightRepository(db);
  });
  tearDown(() => db.close());

  final home = Home(
    id: 'h',
    name: 'Home',
    subnet: '192.168.1',
    createdAt: DateTime(2026, 9, 8),
    sortIndex: 0,
  );
  const room = Room(
    id: 'r',
    homeId: 'h',
    name: 'Living Room',
    glyph: RoomGlyph.sofa,
  );
  final light = Light(
    id: 'l',
    homeId: 'h',
    roomId: 'r',
    name: 'Dome',
    ip: '192.168.1.104',
    mac: 'aa',
    moduleName: 'ESP01_SHRGB1C_31',
    bulbClass: BulbClass.rgb,
    fixture: Fixture.dome,
    fwVersion: '1.25.0',
    addedAt: DateTime(2026, 9, 8),
  );

  test('homes round-trip and stream', () async {
    await homes.insert(home);
    await homes.update(home.copyWith(name: 'Renamed'));
    await expectLater(
      homes.watchAll(),
      emitsThrough(
        predicate<List<Home>>(
          (l) => l.length == 1 && l.single.name == 'Renamed',
        ),
      ),
    );
    expect((await homes.get('h'))!.name, 'Renamed');
    expect((await homes.get('h'))!.createdAt, DateTime(2026, 9, 8));
    await homes.delete('h');
    expect(await homes.getAll(), isEmpty);
  });

  test('rooms and lights round-trip with enums and lookups', () async {
    await homes.insert(home);
    await rooms.insert(room);
    await lights.insert(light);
    expect((await rooms.getByHome('h')).single.glyph, RoomGlyph.sofa);
    var read = (await lights.get('l'))!;
    expect(read, light);
    expect(read.bulbClass, BulbClass.rgb);
    expect(read.fixture, Fixture.dome);
    expect((await lights.getByMac('h', 'aa'))!.id, 'l');
    expect(await lights.getByMac('h', 'zz'), isNull);
    expect((await lights.getByRoom('r')).single.id, 'l');
    var watched = await lights.watch('l').first;
    expect(watched!.name, 'Dome');
    await lights.update(
      light.copyWith(name: 'Lamp', bulbClass: null, clearBulbClass: true),
    );
    expect((await lights.get('l'))!.className, 'Unknown');
    await lights.delete('l');
    expect(await lights.watchByHome('h').first, isEmpty);
  });

  test('settings persist and stream, with a clearable active home', () async {
    var settings = DriftSettingsRepository(db);
    expect(await settings.get(), AppSettings.defaults);
    await settings.save(
      const AppSettings(
        activeHomeId: 'h',
        feedbackEnabled: false,
        rescanOnLaunch: false,
      ),
    );
    expect(
      await settings.get(),
      const AppSettings(
        activeHomeId: 'h',
        feedbackEnabled: false,
        rescanOnLaunch: false,
      ),
    );
    expect((await settings.watch().first).activeHomeId, 'h');
    await settings.save(const AppSettings());
    expect((await settings.get()).activeHomeId, isNull);
  });

  test('live states persist for existing lights only', () async {
    await homes.insert(home);
    await rooms.insert(room);
    await lights.insert(light);
    var persistence = DriftLiveStatePersistence(db);
    await persistence.save({
      'l': LiveState.initial.copyWith(
        isOn: true,
        brightness: 80,
        active: ActiveChannel.scene,
        sceneId: 5,
        rssi: -40,
        updatedAt: DateTime(2026, 9, 8, 12),
      ),
      'ghost': LiveState.initial,
    });
    var loaded = await persistence.load();
    expect(loaded.keys, ['l']);
    expect(loaded['l']!.sceneId, 5);
    expect(loaded['l']!.active, ActiveChannel.scene);
    expect(loaded['l']!.rssi, -40);
    expect(loaded['l']!.updatedAt, DateTime(2026, 9, 8, 12));
    expect(
      loaded['l']!.reachable,
      isFalse,
      reason: 'a loaded state is stale until refreshed',
    );
  });

  test('rooms sharing a sort index come back ordered by id', () async {
    await homes.insert(home);
    // Inserted back to front: without the id tie-break SQLite hands them
    // back in rowid (insertion) order, which the user never chose.
    await rooms.insert(
      const Room(id: 'r2', homeId: 'h', name: 'Bedroom', glyph: RoomGlyph.bed),
    );
    await rooms.insert(
      const Room(id: 'r1', homeId: 'h', name: 'Bath', glyph: RoomGlyph.bath),
    );
    expect((await rooms.getByHome('h')).map((r) => r.id).toList(), [
      'r1',
      'r2',
    ]);
  });
}
