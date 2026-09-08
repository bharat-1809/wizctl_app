import 'package:flutter_test/flutter_test.dart';
import 'package:wizctl/wizctl.dart';
import 'package:wizctl_app/domain/entities/entities.dart';
import 'package:wizctl_app/domain/services/live_state_store.dart';
import 'package:wizctl_app/domain/usecases/usecases.dart';

import '../../support/fakes.dart';

void main() {
  late FakeHomeRepository homes;
  late FakeRoomRepository rooms;
  late FakeLightRepository lights;
  late FakeSettingsRepository settings;
  late LiveStateStore store;
  late SequenceIds ids;
  late FakeClock clock;

  setUp(() {
    homes = FakeHomeRepository();
    rooms = FakeRoomRepository();
    lights = FakeLightRepository();
    settings = FakeSettingsRepository();
    store = LiveStateStore();
    ids = SequenceIds();
    clock = FakeClock();
  });

  test('create, switch, rename and delete homes', () async {
    var create = CreateHome(
      homes: homes,
      settings: settings,
      ids: ids,
      clock: clock,
    );
    var a = await create('  Kaverappa House ');
    expect(a.name, 'Kaverappa House');
    expect((await settings.get()).activeHomeId, a.id);
    await expectLater(create('   '), throwsA(isA<EmptyNameException>()));
    var b = await create('Studio', subnet: '10.0.0');
    expect((await settings.get()).activeHomeId, b.id);
    await SwitchHome(settings: settings)(a.id);
    expect((await settings.get()).activeHomeId, a.id);
    await RenameHome(homes: homes)(a.id, 'Home');
    expect((await homes.get(a.id))!.name, 'Home');
    await DeleteHome(homes: homes, settings: settings)(a.id);
    expect(await homes.getAll(), hasLength(1));
    expect((await settings.get()).activeHomeId, b.id);
    await expectLater(
      DeleteHome(homes: homes, settings: settings)(b.id),
      throwsA(isA<LastHomeException>()),
    );
  });

  test('rooms: add with sort index, rename, delete only when empty', () async {
    var add = AddRoom(rooms: rooms, ids: ids);
    var living = await add('h', 'Living Room', RoomGlyph.sofa);
    var bed = await add('h', 'Bedroom', RoomGlyph.bed);
    expect(living.sortIndex, 0);
    expect(bed.sortIndex, 1);
    await RenameRoom(rooms: rooms)(bed.id, 'Bed room');
    expect((await rooms.get(bed.id))!.name, 'Bed room');
    lights.seed([
      Light(
        id: 'l',
        homeId: 'h',
        roomId: living.id,
        name: 'x',
        ip: 'i',
        mac: 'm',
        fixture: Fixture.bulb,
        addedAt: DateTime(2026),
      ),
    ]);
    await expectLater(
      DeleteRoom(rooms: rooms, lights: lights)(living.id),
      throwsA(isA<RoomNotEmptyException>()),
    );
    await DeleteRoom(rooms: rooms, lights: lights)(bed.id);
    expect(await rooms.getByHome('h'), hasLength(1));
  });

  test('lights: rename, move, fixture, forget, save discovered', () async {
    rooms.seed([
      const Room(id: 'r1', homeId: 'h', name: 'A', glyph: RoomGlyph.sofa),
      const Room(id: 'r2', homeId: 'h', name: 'B', glyph: RoomGlyph.bed),
    ]);
    var save = SaveDiscoveredLight(
      lights: lights,
      store: store,
      ids: ids,
      clock: clock,
    );
    const device = DiscoveredDevice(
      ip: '192.168.1.126',
      mac: 'abc',
      moduleName: 'ESP01_SHRGB1C_31',
      bulbClass: BulbClass.rgb,
      fwVersion: '1.25.0',
    );
    var light = await save(
      homeId: 'h',
      roomId: 'r1',
      device: device,
      alias: ' Bedside bulb ',
      fixture: Fixture.bulb,
      initial: LiveState.initial.copyWith(isOn: true),
    );
    expect(light.name, 'Bedside bulb');
    expect(light.fwVersion, '1.25.0');
    expect(store.of(light.id).isOn, isTrue);
    await expectLater(
      save(
        homeId: 'h',
        roomId: 'r1',
        device: device,
        alias: 'again',
        fixture: Fixture.bulb,
      ),
      throwsA(isA<AlreadySavedException>()),
    );
    var unnamed = await save(
      homeId: 'h',
      roomId: 'r1',
      device: device.copyWith(alreadySaved: false).copyWithMac('def'),
      alias: '',
      fixture: Fixture.desk,
    );
    expect(unnamed.name, 'WiZ RGB');
    await RenameLight(lights: lights)(light.id, 'Lamp');
    await MoveLight(lights: lights)(light.id, 'r2');
    await SetFixture(lights: lights)(light.id, Fixture.strip);
    var updated = (await lights.get(light.id))!;
    expect(
      (updated.name, updated.roomId, updated.fixture),
      ('Lamp', 'r2', Fixture.strip),
    );
    await ForgetLight(lights: lights, store: store)(light.id);
    expect(await lights.get(light.id), isNull);
    expect(store.snapshot.containsKey(light.id), isFalse);
  });

  test('finish onboarding writes only used and custom rooms and activates the home', () async {
    var finish = FinishOnboarding(
      homes: homes,
      rooms: rooms,
      lights: lights,
      settings: settings,
      store: store,
      ids: ids,
      clock: clock,
    );
    var home = await finish(
      OnboardingResult(
        homeName: 'Kaverappa House',
        subnet: '192.168.1',
        rooms: const [
          OnboardingRoom(
            tempId: 'living',
            name: 'Living Room',
            glyph: RoomGlyph.sofa,
            custom: false,
          ),
          OnboardingRoom(
            tempId: 'bedroom',
            name: 'Bedroom',
            glyph: RoomGlyph.bed,
            custom: false,
          ),
          OnboardingRoom(
            tempId: 'kitchen',
            name: 'Kitchen',
            glyph: RoomGlyph.utensils,
            custom: false,
          ),
          OnboardingRoom(
            tempId: 'study',
            name: 'Study',
            glyph: RoomGlyph.lampDesk,
            custom: true,
          ),
        ],
        lights: [
          OnboardingLight(
            device: const DiscoveredDevice(
              ip: '192.168.1.126',
              mac: 'a',
              bulbClass: BulbClass.rgb,
            ),
            alias: 'Ceiling dome light',
            roomTempId: 'living',
            fixture: Fixture.dome,
            initial: LiveState.initial.copyWith(isOn: true),
          ),
          const OnboardingLight(
            device: DiscoveredDevice(
              ip: '192.168.1.140',
              mac: 'b',
              bulbClass: BulbClass.socket,
            ),
            alias: '',
            roomTempId: 'living',
            fixture: Fixture.socket,
          ),
        ],
      ),
    );
    expect(home.subnet, '192.168.1');
    expect((await settings.get()).activeHomeId, home.id);
    var written = await rooms.getByHome(home.id);
    expect(written.map((r) => r.name), ['Living Room', 'Study']);
    var saved = await lights.getByHome(home.id);
    expect(saved.map((l) => l.name), ['Ceiling dome light', 'WiZ Smart Plug']);
    expect(saved.every((l) => l.roomId == written.first.id), isTrue);
    expect(store.of(saved.first.id).isOn, isTrue);
  });

  test('learn home subnet writes it once and ignores unknown homes', () async {
    var learn = LearnHomeSubnet(homes: homes);
    await homes.insert(Home(id: 'h', name: 'House', createdAt: clock.now()));
    await learn('h', '192.168.1');
    expect((await homes.get('h'))!.subnet, '192.168.1');
    await learn('h', '10.0.0');
    expect((await homes.get('h'))!.subnet, '192.168.1');
    await learn('missing', '10.0.0');
  });
}
