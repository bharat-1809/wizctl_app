import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';

import 'fakes.dart';

/// The prototype's home, as fakes: Kaverappa House with its three rooms and
/// six lights (one of them unreachable), plus the Studio to switch to.
/// Names, addresses, classes, fixtures and states are the mobile prototype's
/// seed data (`design/reference/WizCtl_Mobile.dc.html`, state block).
class SeedHome {
  final homes = FakeHomeRepository();
  final rooms = FakeRoomRepository();
  final lights = FakeLightRepository();
  final settings = FakeSettingsRepository();
  final store = LiveStateStore();

  final DateTime added = DateTime(2026, 9, 8, 12);

  late final Home home = Home(
    id: 'h1',
    name: 'Kaverappa House',
    subnet: '192.168.1',
    createdAt: added,
  );
  late final Home studio = Home(
    id: 'h2',
    name: 'Studio',
    createdAt: added,
    sortIndex: 1,
  );

  final Room living = const Room(
    id: 'living',
    homeId: 'h1',
    name: 'Living Room',
    glyph: RoomGlyph.sofa,
  );
  final Room bedroom = const Room(
    id: 'bedroom',
    homeId: 'h1',
    name: 'Bedroom',
    glyph: RoomGlyph.bed,
    sortIndex: 1,
  );
  final Room kitchen = const Room(
    id: 'kitchen',
    homeId: 'h1',
    name: 'Kitchen',
    glyph: RoomGlyph.utensils,
    sortIndex: 2,
  );
  final Room desk = const Room(
    id: 'desk',
    homeId: 'h2',
    name: 'Desk',
    glyph: RoomGlyph.lampDesk,
  );

  late final Light dome = _light(
    'dome',
    'living',
    'Ceiling dome light',
    '192.168.1.104',
    'a8bb50f1c204',
    BulbClass.rgb,
    Fixture.dome,
    0,
  );
  late final Light floor = _light(
    'floor',
    'living',
    'Corner floor lamp',
    '192.168.1.107',
    'a8bb50f1c8a1',
    BulbClass.rgb,
    Fixture.desk,
    1,
  );
  late final Light strip = _light(
    'strip',
    'living',
    'Shelf strip',
    '192.168.1.111',
    'a8bb50f2013e',
    BulbClass.tw,
    Fixture.strip,
    2,
  );
  late final Light bedside = _light(
    'bedside',
    'bedroom',
    'Bedside bulb',
    '192.168.1.115',
    'a8bb50f21177',
    BulbClass.rgb,
    Fixture.bulb,
    3,
  );
  late final Light hall = _light(
    'hall',
    'bedroom',
    'Hallway',
    '192.168.1.118',
    'a8bb50f22b03',
    BulbClass.dw,
    Fixture.dome,
    4,
  );
  late final Light counter = _light(
    'counter',
    'kitchen',
    'Counter downlight',
    '192.168.1.121',
    'a8bb50f23940',
    BulbClass.tw,
    Fixture.dome,
    5,
  );
  late final Light task = _light(
    'task',
    'desk',
    'Task lamp',
    '10.0.0.42',
    'a8bb50f30011',
    BulbClass.tw,
    Fixture.desk,
    0,
    homeId: 'h2',
  );

  List<Light> get all => [dome, floor, strip, bedside, hall, counter, task];

  SeedHome({bool active = true}) {
    homes.seed([home, studio]);
    rooms.seed([living, bedroom, kitchen, desk]);
    lights.seed(all);
    if (active) {
      settings.save(const AppSettings(activeHomeId: 'h1'));
    }
    store.seed({
      'dome': const LiveState(
        isOn: true,
        brightness: 70,
        kelvin: 2450,
        rgb: Rgb.amber,
        sceneId: 6,
        speed: 150,
        active: ActiveChannel.scene,
        reachable: true,
        rssi: -52,
      ),
      'floor': const LiveState(
        isOn: true,
        brightness: 45,
        kelvin: 2700,
        rgb: Rgb(255, 120, 60),
        sceneId: 29,
        speed: 120,
        active: ActiveChannel.colour,
        reachable: true,
        rssi: -58,
      ),
      'strip': const LiveState(
        isOn: false,
        brightness: 60,
        kelvin: 4000,
        rgb: Rgb.warm,
        sceneId: 12,
        speed: 100,
        active: ActiveChannel.white,
        reachable: true,
        rssi: -61,
      ),
      'bedside': const LiveState(
        isOn: false,
        brightness: 30,
        kelvin: 2200,
        rgb: Rgb(255, 140, 40),
        sceneId: 10,
        speed: 90,
        active: ActiveChannel.white,
        reachable: true,
        rssi: -66,
      ),
      'hall': const LiveState(
        isOn: false,
        brightness: 50,
        kelvin: 2700,
        rgb: Rgb.warm,
        sceneId: 11,
        speed: 100,
        active: ActiveChannel.white,
        reachable: false,
      ),
      'counter': const LiveState(
        isOn: true,
        brightness: 90,
        kelvin: 5000,
        rgb: Rgb(242, 246, 255),
        sceneId: 15,
        speed: 100,
        active: ActiveChannel.white,
        reachable: true,
        rssi: -49,
      ),
      'task': const LiveState(
        isOn: true,
        brightness: 80,
        kelvin: 4500,
        rgb: Rgb(255, 244, 230),
        sceneId: 15,
        speed: 100,
        active: ActiveChannel.white,
        reachable: true,
        rssi: -40,
      ),
    });
  }

  Light _light(
    String id,
    String roomId,
    String name,
    String ip,
    String mac,
    BulbClass cls,
    Fixture fixture,
    int sortIndex, {
    String homeId = 'h1',
  }) => Light(
    id: id,
    homeId: homeId,
    roomId: roomId,
    name: name,
    ip: ip,
    mac: mac,
    moduleName: null,
    bulbClass: cls,
    fixture: fixture,
    fwVersion: '1.25.0',
    sortIndex: sortIndex,
    addedAt: added,
  );

  /// A home with nothing in it, for the first run.
  static SeedHome empty() {
    var seed = SeedHome(active: false);
    for (var l in seed.all) {
      seed.lights.delete(l.id);
    }
    for (var r in [seed.living, seed.bedroom, seed.kitchen, seed.desk]) {
      seed.rooms.delete(r.id);
    }
    seed.homes.delete('h1');
    seed.homes.delete('h2');
    return seed;
  }
}
